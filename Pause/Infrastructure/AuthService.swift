import Foundation
import Security

struct AuthUser: Codable, Equatable { var id: UUID; var email: String? }

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isLoading = false
    var isConfigured: Bool { configuration != nil }

    private var configuration: (url: URL, key: String)? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: value), !value.isEmpty,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty else { return nil }
        return (url, key)
    }

    func signUp(email: String, password: String) async throws {
        try await authenticate(path: "signup", email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await authenticate(path: "token?grant_type=password", email: email, password: password)
    }

    func signOut() {
        user = nil; SessionTokenStore.delete()
    }

    func deleteRemoteAccount() async throws {
        guard let configuration, let token = SessionTokenStore.load() else { signOut(); return }
        var request = URLRequest(url: configuration.url.appendingPathComponent("functions/v1/delete-account"))
        request.httpMethod = "DELETE"
        request.setValue(configuration.key, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw AuthError.rejected }
        signOut()
    }

    private func authenticate(path: String, email: String, password: String) async throws {
        guard let configuration else { throw AuthError.notConfigured }
        guard email.contains("@"), password.count >= 8 else { throw AuthError.invalidCredentials }
        isLoading = true; defer { isLoading = false }
        guard let endpoint = URL(string: "\(configuration.url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/auth/v1/\(path)") else { throw AuthError.notConfigured }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"; request.setValue(configuration.key, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw AuthError.rejected }
        let payload = try JSONDecoder().decode(AuthPayload.self, from: data)
        guard let sessionUser = payload.user, let token = payload.accessToken else { throw AuthError.emailConfirmationRequired }
        user = sessionUser; SessionTokenStore.save(token)
    }

    private struct AuthPayload: Decodable {
        var user: AuthUser?; var accessToken: String?
        enum CodingKeys: String, CodingKey { case user, accessToken = "access_token" }
    }
}

enum AuthError: LocalizedError {
    case notConfigured, invalidCredentials, rejected, emailConfirmationRequired
    var errorDescription: String? {
        switch self {
        case .notConfigured: "Cloud accounts are not configured. Local Demo Mode remains available."
        case .invalidCredentials: "Enter a valid email and a password of at least eight characters."
        case .rejected: "The account request was rejected. Check the details or try again later."
        case .emailConfirmationRequired: "Check the email address for confirmation before signing in."
        }
    }
}

enum SessionTokenStore {
    private static let service = "org.pauseproject.auth"
    static func save(_ token: String) {
        delete(); let data = Data(token.utf8)
        SecItemAdd([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "session", kSecValueData: data, kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary, nil)
    }
    static func load() -> String? {
        var result: AnyObject?
        let status = SecItemCopyMatching([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "session", kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne] as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func delete() { SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "session"] as CFDictionary) }
}
