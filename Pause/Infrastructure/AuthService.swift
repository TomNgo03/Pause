import Foundation
import Security

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
    enum VerificationPurpose: String { case signup, recovery }

    @Published private(set) var state: State = .restoring
    @Published private(set) var isLoading = false

    var user: AuthUser? {
        if case let .signedIn(user) = state { return user }
        return nil
    }
    var isConfigured: Bool { configuration != nil }

    private var session: AuthSession?
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

    /// Creates an unconfirmed account and sends the six-digit signup code.
    func requestSignupCode(email: String, password: String) async throws {
        try validate(email: email, password: password)
        try await performLoading {
            let _: SignupResponse = try await self.request(
                path: "signup",
                body: ["email": email.normalizedEmail, "password": password]
            )
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
        body: [String: String],
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
        request.httpBody = try JSONEncoder().encode(body)
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

    private struct SignupResponse: Decodable { let id: UUID? }
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
    case notConfigured, invalidEmail, weakPassword, invalidCode, sessionExpired, network, server(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured: "Pause cannot connect to its account service."
        case .invalidEmail: "Enter a valid email address."
        case .weakPassword: "Use at least eight characters for your password."
        case .invalidCode: "Enter the six-digit code from your email."
        case .sessionExpired: "Your secure session expired. Please sign in again."
        case .network: "Pause could not reach the account service. Check your connection and try again."
        case let .server(message): message
        }
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
