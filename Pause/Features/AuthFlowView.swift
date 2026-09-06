import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject private var model: AppModel
    @State private var screen: Screen = .welcome
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var code = ""
    @State private var errorMessage: String?

    private enum Screen { case welcome, signIn, signUp, signupCode, forgotPassword, recoveryCode }

    var body: some View {
        NavigationStack {
            ZStack {
                PauseBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        Group {
                            switch screen {
                            case .welcome: welcome
                            case .signIn: signIn
                            case .signUp: signUp
                            case .signupCode: codeEntry(purpose: .signup)
                            case .forgotPassword: forgotPassword
                            case .recoveryCode: codeEntry(purpose: .recovery)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                if screen != .welcome {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { goBack() } label: { Image(systemName: "chevron.left").fontWeight(.semibold) }
                            .accessibilityLabel("Back")
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "pause.fill")
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(PauseTheme.heroGradient, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                .shadow(color: PauseTheme.indigo.opacity(0.22), radius: 18, y: 9)
            Text("Pause").font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
        .padding(.top, screen == .welcome ? 36 : 4)
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            VStack(spacing: 9) {
                Text("Make your time intentional.")
                    .font(.title2.bold()).multilineTextAlignment(.center)
                Text("Plan focused time, reflect without judgment, and support friends you trust.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(3)
            }
            .padding(.bottom, 10)

            socialButtons
            divider
            Button("Create new account") { move(to: .signUp) }.buttonStyle(PrimaryButtonStyle())
            Button("Log in") { move(to: .signIn) }.buttonStyle(SoftButtonStyle())

            Label("Your reflections stay private by default", systemImage: "lock.shield.fill")
                .font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
        }
    }

    private var signIn: some View {
        authCard(title: "Welcome back", subtitle: "Log in to continue to your Pause space.") {
            socialButtons
            divider
            emailField
            passwordField(label: "Password", value: $password)
            HStack {
                Spacer()
                Button("Forgot password?") { move(to: .forgotPassword) }
                    .font(.subheadline.weight(.semibold))
            }
            statusMessage
            submitButton("Log in") { try await model.auth.signIn(email: email, password: password) }
            prompt("New to Pause?", action: "Create account") { move(to: .signUp) }
        }
    }

    private var socialButtons: some View {
        VStack(spacing: 11) {
            socialButton(title: "Continue with Apple", icon: "apple.logo", provider: "apple", dark: true)
            socialButton(title: "Continue with Google", icon: "g.circle.fill", provider: "google", dark: false)
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
            Text("or").font(.caption).foregroundStyle(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
        }
    }

    private func socialButton(title: String, icon: String, provider: String, dark: Bool) -> some View {
        Button {
            Task {
                errorMessage = nil
                do { try await model.auth.signInWithOAuth(provider: provider) }
                catch AuthError.cancelled { }
                catch { errorMessage = error.localizedDescription }
            }
        } label: {
            Label(title, systemImage: icon).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                .foregroundStyle(dark ? Color.white : Color.primary)
                .background(dark ? Color.black : Color(uiColor: .systemBackground),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color.primary.opacity(dark ? 0 : 0.14)))
        }
        .disabled(model.auth.isLoading)
        .accessibilityHint("Opens a secure \(provider.capitalized) sign-in page")
    }

    private var signUp: some View {
        authCard(title: "Create your account", subtitle: "We'll email a six-digit code to verify it is really you.") {
            emailField
            passwordField(label: "Password", value: $password)
            passwordField(label: "Confirm password", value: $confirmation)
            Text("Use at least 8 characters. Never reuse a school or social-media password.")
                .font(.caption).foregroundStyle(.secondary)
            statusMessage
            submitButton("Send verification code") {
                guard password == confirmation else { throw LocalAuthError.passwordsDoNotMatch }
                try await model.auth.requestSignupCode(email: email, password: password)
                move(to: .signupCode, clearError: false)
            }
            prompt("Already have an account?", action: "Log in") { move(to: .signIn) }
        }
    }

    private var forgotPassword: some View {
        authCard(title: "Reset your password", subtitle: "Enter your account email and we'll send a temporary code.") {
            emailField
            statusMessage
            submitButton("Send reset code") {
                try await model.auth.requestPasswordResetCode(email: email)
                move(to: .recoveryCode, clearError: false)
            }
            prompt("Remembered it?", action: "Back to login") { move(to: .signIn) }
        }
    }

    private func codeEntry(purpose: AuthService.VerificationPurpose) -> some View {
        let isRecovery = purpose == .recovery
        return authCard(
            title: isRecovery ? "Choose a new password" : "Check your email",
            subtitle: "Enter the six-digit code sent to \(email)."
        ) {
            TextField("000000", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .semibold, design: .rounded).monospacedDigit())
                .tracking(10)
                .onChange(of: code) { _, value in code = String(value.filter(\.isNumber).prefix(6)) }
                .pauseField()
                .accessibilityLabel("Six-digit verification code")
            if isRecovery {
                passwordField(label: "New password", value: $password)
                passwordField(label: "Confirm new password", value: $confirmation)
            }
            statusMessage
            submitButton(isRecovery ? "Reset password" : "Verify and continue") {
                if isRecovery {
                    guard password == confirmation else { throw LocalAuthError.passwordsDoNotMatch }
                    try await model.auth.resetPassword(email: email, code: code, newPassword: password)
                } else {
                    try await model.auth.verifyCode(email: email, code: code, purpose: .signup)
                }
            }
            Button("Send a new code") {
                Task { await resend(purpose: purpose) }
            }
            .font(.subheadline.weight(.semibold))
            .disabled(model.auth.isLoading)
        }
    }

    private var emailField: some View {
        TextField("Email address", text: $email)
            .textContentType(.emailAddress).keyboardType(.emailAddress)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .pauseField()
    }

    private func passwordField(label: String, value: Binding<String>) -> some View {
        SecureField(label, text: value).textContentType(.password).pauseField()
    }

    private var statusMessage: some View {
        Group {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func authCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        PauseCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.title2.bold())
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineSpacing(2)
                }
                content()
            }
        }
    }

    private func submitButton(_ title: String, operation: @escaping () async throws -> Void) -> some View {
        Button {
            Task {
                errorMessage = nil
                do { try await operation() }
                catch { errorMessage = error.localizedDescription }
            }
        } label: {
            HStack {
                if model.auth.isLoading { ProgressView().tint(.white) }
                Text(title)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(model.auth.isLoading)
    }

    private func prompt(_ text: String, action: String, perform: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Spacer(); Text(text).foregroundStyle(.secondary); Button(action, action: perform).fontWeight(.semibold); Spacer()
        }
        .font(.footnote)
    }

    private func resend(purpose: AuthService.VerificationPurpose) async {
        errorMessage = nil
        do {
            if purpose == .signup { try await model.auth.requestSignupCode(email: email, password: password) }
            else { try await model.auth.requestPasswordResetCode(email: email) }
        } catch { errorMessage = error.localizedDescription }
    }

    private func move(to destination: Screen, clearError: Bool = true) {
        if clearError { errorMessage = nil }
        code = ""
        withAnimation(.easeInOut(duration: 0.2)) { screen = destination }
    }

    private func goBack() {
        switch screen {
        case .signupCode: move(to: .signUp)
        case .recoveryCode: move(to: .forgotPassword)
        default: move(to: .welcome)
        }
    }
}

private enum LocalAuthError: LocalizedError {
    case passwordsDoNotMatch
    var errorDescription: String? { "The passwords do not match." }
}

private extension View {
    func pauseField() -> some View {
        padding(.horizontal, 15).frame(minHeight: 52)
            .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08)))
    }
}
