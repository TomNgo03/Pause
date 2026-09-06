import Foundation
import Security
import AuthenticationServices
import UIKit

struct AuthUser: Codable, Equatable {
    let id: UUID
    let email: String?
}

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval?
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

@MainActor
final class AuthService: ObservableObject {
    enum State: Equatable { case restoring, signedOut, signedIn(AuthUser) }
    enum VerificationPurpose: String { case recovery }

    @Published private(set) var state: State = .restoring
    @Published private(set) var isLoading = false

    var user: AuthUser? {
        if case let .signedIn(user) = state { return user }
        return nil
    }
    var isConfigured: Bool { configuration != nil }

    private var session: AuthSession?
    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var configuration: (url: URL, key: String)? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: value), !value.isEmpty,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else { return nil }
        return (url, key)
    }

    func restoreSession() async {
        guard configuration != nil, let saved = SessionTokenStore.load() else {
            clearSession()
            return
        }
        do {
            let refreshed: AuthSession = try await request(
                path: "token?grant_type=refresh_token",
                body: ["refresh_token": saved.refreshToken]
            )
            accept(refreshed)
        } catch { clearSession() }
    }

    /// Creates an account and signs in immediately when Confirm email is disabled in Supabase.
    func signUp(email: String, password: String) async throws {
        try validate(email: email, password: password)
        try await performLoading {
            let response: SignupResponse = try await self.request(
                path: "signup",
                body: ["email": email.normalizedEmail, "password": password]
            )
            guard let session = response.session else { throw AuthError.emailConfirmationEnabled }
            self.accept(session)
        }
    }

    /// Confirms the email and creates the first authenticated session.
    func verifyCode(email: String, code: String, purpose: VerificationPurpose) async throws {
        guard code.filter(\.isNumber).count == 6 else { throw AuthError.invalidCode }
        try await performLoading {
            let verified: AuthSession = try await self.request(
                path: "verify",
                body: ["email": email.normalizedEmail, "token": code.filter(\.isNumber), "type": purpose.rawValue]
            )
            self.accept(verified)
        }
    }

    func signIn(email: String, password: String) async throws {
        try validate(email: email, password: password)
        try await performLoading {
            let signedIn: AuthSession = try await self.request(
                path: "token?grant_type=password",
                body: ["email": email.normalizedEmail, "password": password]
            )
            self.accept(signedIn)
        }
    }

    func signInWithOAuth(provider: String) async throws {
        guard ["google", "apple"].contains(provider) else { throw AuthError.unsupportedProvider }
        guard let configuration else { throw AuthError.notConfigured }
        var components = URLComponents(url: configuration.url.appendingPathComponent("auth/v1/authorize"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "provider", value: provider),
            URLQueryItem(name: "redirect_to", value: "pause://auth-callback")
        ]
        guard let url = components?.url else { throw AuthError.notConfigured }

        try await performLoading {
            let callbackURL = try await self.openAuthenticationSession(url: url)
            let values = callbackURL.authParameters
            if let message = values["error_description"]?.replacingOccurrences(of: "+", with: " ") {
                throw AuthError.server(message)
            }
            guard let accessToken = values["access_token"], let refreshToken = values["refresh_token"] else {
                throw AuthError.invalidCallback
            }
            let user: AuthUser = try await self.request(path: "user", method: "GET", body: nil, bearerToken: accessToken)
            self.accept(AuthSession(accessToken: accessToken, refreshToken: refreshToken,
                                    expiresAt: values["expires_at"].flatMap(TimeInterval.init), user: user))
        }
    }

    /// Sends a recovery code. The Supabase recovery template must contain `{{ .Token }}`.
    func requestPasswordResetCode(email: String) async throws {
        guard email.isValidEmail else { throw AuthError.invalidEmail }
        try await performLoading {
            let _: EmptyResponse = try await self.request(path: "recover", body: ["email": email.normalizedEmail])
        }
    }

    /// Verifies a recovery code, then replaces the password for that temporary session.
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        guard newPassword.count >= 8 else { throw AuthError.weakPassword }
        try await verifyCode(email: email, code: code, purpose: .recovery)
        guard let accessToken = session?.accessToken else { throw AuthError.sessionExpired }
        do {
            let updated: AuthUser = try await request(
                path: "user", method: "PUT", body: ["password": newPassword], bearerToken: accessToken
            )
            state = .signedIn(updated)
        } catch {
            clearSession()
            throw error
        }
    }

    func signOut() async {
        if let token = session?.accessToken {
            let _: EmptyResponse? = try? await request(path: "logout", body: [:], bearerToken: token)
        }
        clearSession()
    }

    func deleteRemoteAccount() async throws {
        guard let configuration, let token = session?.accessToken else { clearSession(); return }
        isLoading = true
        defer { isLoading = false }
        var request = URLRequest(url: configuration.url.appendingPathComponent("functions/v1/delete-account"))
        request.httpMethod = "DELETE"
        request.setValue(configuration.key, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        clearSession()
    }

    private func performLoading(_ operation: () async throws -> Void) async throws {
        isLoading = true
        defer { isLoading = false }
        try await operation()
    }

    private func validate(email: String, password: String) throws {
        guard email.isValidEmail else { throw AuthError.invalidEmail }
        guard password.count >= 8 else { throw AuthError.weakPassword }
    }

    private func accept(_ session: AuthSession) {
        self.session = session
        SessionTokenStore.save(session)
        state = .signedIn(session.user)
    }

    private func clearSession() {
        session = nil
        SessionTokenStore.delete()
        state = .signedOut
    }

    private func request<Response: Decodable>(
        path: String,
        method: String = "POST",
        body: [String: String]?,
        bearerToken: String? = nil
    ) async throws -> Response {
        guard let configuration else { throw AuthError.notConfigured }
        let base = configuration.url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let endpoint = URL(string: "\(base)/auth/v1/\(path)") else { throw AuthError.notConfigured }
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue(configuration.key, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearerToken { request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization") }
        if let body { request.httpBody = try JSONEncoder().encode(body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        if Response.self == EmptyResponse.self, data.isEmpty { return EmptyResponse() as! Response }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw AuthError.network }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerError.self, from: data).displayMessage)
            throw AuthError.server(message ?? "We couldn't complete that request. Please try again.")
        }
    }

    private func openAuthenticationSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "pause") { [weak self] callback, error in
                self?.webAuthenticationSession = nil
                if let callback { continuation.resume(returning: callback) }
                else if let authenticationError = error as? ASWebAuthenticationSessionError,
                        authenticationError.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.cancelled)
                } else { continuation.resume(throwing: error ?? AuthError.invalidCallback) }
            }
            session.presentationContextProvider = WebAuthenticationPresenter.shared
            session.prefersEphemeralWebBrowserSession = false
            webAuthenticationSession = session
            guard session.start() else {
                webAuthenticationSession = nil
                continuation.resume(throwing: AuthError.invalidCallback)
                return
            }
        }
    }

    private struct SignupResponse: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let expiresAt: TimeInterval?
        let user: AuthUser?
        var session: AuthSession? {
            guard let accessToken, let refreshToken, let user else { return nil }
            return AuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt, user: user)
        }
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case user
        }
    }
    private struct ServerError: Decodable {
        let msg: String?
        let message: String?
        let errorDescription: String?
        var displayMessage: String? { msg ?? message ?? errorDescription }
        enum CodingKeys: String, CodingKey { case msg, message; case errorDescription = "error_description" }
    }
}

private struct EmptyResponse: Decodable { init() {} }

enum AuthError: LocalizedError {
    case notConfigured, invalidEmail, weakPassword, invalidCode, sessionExpired, network
    case unsupportedProvider, invalidCallback, cancelled, emailConfirmationEnabled, server(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured: "Pause cannot connect to its account service."
        case .invalidEmail: "Enter a valid email address."
        case .weakPassword: "Use at least eight characters for your password."
        case .invalidCode: "Enter the six-digit code from your email."
        case .sessionExpired: "Your secure session expired. Please sign in again."
        case .network: "Pause could not reach the account service. Check your connection and try again."
        case .unsupportedProvider: "That sign-in provider is not supported."
        case .invalidCallback: "The sign-in response was incomplete. Please try again."
        case .cancelled: "Sign-in was cancelled."
        case .emailConfirmationEnabled: "Turn off Confirm email in Supabase to use simple account creation."
        case let .server(message): message
        }
    }
}

private extension URL {
    var authParameters: [String: String] {
        let source = fragment.map { "?\($0)" } ?? "?\(query ?? "")"
        return Dictionary(uniqueKeysWithValues: (URLComponents(string: source)?.queryItems ?? []).compactMap {
            guard let value = $0.value else { return nil }
            return ($0.name, value)
        })
    }
}

@MainActor
private final class WebAuthenticationPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthenticationPresenter()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

private extension String {
    var normalizedEmail: String { trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    var isValidEmail: Bool {
        let parts = normalizedEmail.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
}

enum SessionTokenStore {
    private static let service = "org.pauseproject.auth"
    private static let account = "session-v2"

    static func save(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        delete()
        SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account,
                    kSecValueData: data, kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary, nil)
    }

    static func load() -> AuthSession? {
        var result: AnyObject?
        let status = SecItemCopyMatching([kSecClass: kSecClassGenericPassword, kSecAttrService: service,
            kSecAttrAccount: account, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne] as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    static func delete() {
        for key in [account, "session"] {
            SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: key] as CFDictionary)
        }
    }
}
