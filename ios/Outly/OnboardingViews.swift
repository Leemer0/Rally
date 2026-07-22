import SwiftUI
import UIKit

struct OnboardingFlowView: View {
    @Environment(DemoStore.self) private var store

    var body: some View {
        Group {
            switch store.state.onboardingStage {
            case .welcome:
                WelcomeView()
            case .auth:
                AuthenticationView()
            case .name:
                NameOnboardingView()
            case .age:
                AgeOnboardingView()
            case .gender:
                GenderOnboardingView()
            case .interested:
                OnboardingCompleteView()
            case .complete:
                OnboardingCompleteView()
            case .main:
                EmptyView()
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .outlyScreenBackground()
    }
}

private struct WelcomeView: View {
    @Environment(DemoStore.self) private var store
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                if dynamicTypeSize.isAccessibilitySize || proxy.size.height < 700 {
                    ScrollView {
                        compactContent
                    }
                    .scrollIndicators(.hidden)
                } else {
                    standardContent(screenHeight: proxy.size.height)
                }
            }
        }
        .onAppear { appeared = true }
    }

    private func standardContent(screenHeight: CGFloat) -> some View {
        let heroHeight = min(410, max(350, screenHeight * 0.5))

        return ZStack(alignment: .top) {
            nightlifeHero(height: heroHeight)

            VStack(alignment: .leading, spacing: 0) {
                welcomeHeader

                Spacer()
                    .frame(height: max(250, heroHeight - 78))

                headline

                supportingCopy
                    .padding(.top, 14)

                Spacer(minLength: 14)

                actions
            }
            .padding(.horizontal, OutlyMetrics.edge)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            welcomeHeader
                .padding(.top, 6)
            nightlifeHero(height: dynamicTypeSize.isAccessibilitySize ? 190 : 230)
                .padding(.horizontal, -OutlyMetrics.edge)
                .padding(.top, 8)
            headline
                .padding(.top, 18)
            supportingCopy
                .padding(.top, 14)
            actions
                .padding(.top, 24)
        }
        .padding(.horizontal, OutlyMetrics.edge)
        .padding(.bottom, 18)
    }

    private var welcomeHeader: some View {
        HStack(alignment: .center) {
            WelcomeHeroMedia()
                .frame(width: 82, height: 42)
                .accessibilityHidden(true)

            Spacer(minLength: 12)

            if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: 7) {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 6, height: 6)
                    Text("TORONTO · TONIGHT")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.1)
                }
                .foregroundStyle(theme.secondaryText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Toronto tonight")
            }
        }
        .frame(minHeight: 44)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Say you met\nat a bar,")
                .foregroundStyle(theme.primaryText)
            Text("not a dating\napp.")
                .foregroundStyle(theme.accent)
        }
        .font(.largeTitle.weight(.bold))
        .tracking(-1.3)
        .fixedSize(horizontal: false, vertical: true)
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 14)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.65).delay(0.08), value: appeared)
    }

    private var supportingCopy: some View {
        Text("See where people are going tonight.\nPick a bar. Meet in real life.")
            .font(.subheadline)
            .foregroundStyle(theme.secondaryText)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actions: some View {
        VStack(spacing: 4) {
            Button("Sign Up") { store.beginAuthentication(.signUp) }
                .buttonStyle(MetalSilverActionButtonStyle())
                .accessibilityIdentifier("sign-up")
            Button("Log In") { store.beginAuthentication(.logIn) }
                .buttonStyle(GhostButtonStyle())
                .accessibilityIdentifier("log-in")
        }
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 12)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.6).delay(0.18), value: appeared)
    }

    private func nightlifeHero(height: CGFloat) -> some View {
        Image("WelcomeNightlife")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [
                        .black.opacity(0.18),
                        .clear,
                        .black.opacity(0.2),
                        .black,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.68), .clear, .black.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .opacity(appeared || reduceMotion ? 0.95 : 0)
            .animation(.easeOut(duration: 0.55), value: appeared)
            .accessibilityHidden(true)
    }
}

private struct AuthenticationView: View {
    @Environment(DemoStore.self) private var store
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.appServices) private var services
    @State private var loadingProvider: AuthProvider?
    @State private var authenticationTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var presentedEmailIntent: AuthIntent?
    @AccessibilityFocusState private var errorIsFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader { store.go(to: .welcome) }

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: OutlyMetrics.spacing24)

                        WingedOMarkView(compact: true)

                        Text(store.authIntent == .signUp ? "Create your account." : "Welcome back.")
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                            .padding(.top, OutlyMetrics.spacing24)

                        Text(store.authIntent == .signUp ? "Two quick details. Nothing public." : "Continue to tonight’s map.")
                            .font(.body)
                            .foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, OutlyMetrics.spacing12)

                        VStack(spacing: OutlyMetrics.spacing12) {
                            authButton(.apple) {
                                Image(systemName: "apple.logo")
                                    .imageScale(.large)
                            }
                                .accessibilityIdentifier("auth-apple")

                            authButton(.google) {
                                Image("GoogleSignInMark")
                                    .resizable()
                                    .scaledToFit()
                            }
                                .accessibilityIdentifier("auth-google")

                            authButton(.facebook) {
                                FacebookAuthMark()
                            }
                                .accessibilityIdentifier("auth-facebook")

                            authButton(.email) {
                                Image(systemName: "envelope.fill")
                            }
                                .accessibilityIdentifier("auth-email")
                        }
                        .padding(.top, OutlyMetrics.spacing32)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(theme.error)
                                .multilineTextAlignment(.center)
                                .padding(.top, 14)
                                .accessibilityLabel("Error: \(errorMessage)")
                                .accessibilityFocused($errorIsFocused)
                        }

                        Spacer(minLength: OutlyMetrics.spacing24)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, OutlyMetrics.edge)
                }
            }
        }
        .onDisappear {
            authenticationTask?.cancel()
            authenticationTask = nil
        }
        .sheet(item: $presentedEmailIntent) { intent in
            EmailAuthenticationSheet(intent: intent) { credentials in
                try await authenticate(.email(intent: intent, credentials: credentials))
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func authButton<Icon: View>(
        _ provider: AuthProvider,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button {
            if provider == .email, !services.isDemo {
                presentedEmailIntent = store.authIntent
            } else {
                beginAuthentication(with: provider)
            }
        } label: {
            ZStack {
                Text("Continue with \(provider.title)")
                    .lineLimit(1)

                HStack {
                    icon()
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)

                    Spacer()

                    if loadingProvider == provider {
                        ProgressView()
                            .tint(progressTint(for: provider))
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(.horizontal, 18)
        }
        .disabled(loadingProvider != nil)
        .buttonStyle(AuthenticationProviderButtonStyle(provider: provider))
    }

    private func progressTint(for provider: AuthProvider) -> Color {
        switch provider {
        case .apple: .black
        case .facebook: .white
        case .google, .email: theme.primaryText
        }
    }

    private func beginAuthentication(with provider: AuthProvider) {
        guard authenticationTask == nil else { return }
        authenticationTask = Task {
            try? await authenticate(.oauth(provider))
        }
    }

    private func authenticate(_ request: AuthenticationRequest) async throws {
        let provider: AuthProvider
        switch request {
        case let .oauth(value): provider = value
        case .email: provider = .email
        }
        loadingProvider = provider
        errorMessage = nil
        errorIsFocused = false
        defer {
            loadingProvider = nil
            authenticationTask = nil
        }
        do {
            _ = try await services.authenticate(request)
            guard !Task.isCancelled else { return }

            if services.isDemo {
                if store.authIntent == .signUp {
                    store.go(to: .name)
                } else {
                    store.completeLogin()
                }
                return
            }

            do {
                store.applyConsumerBootstrap(try await services.loadConsumerBootstrap())
            } catch let error as SupabaseBackendError {
                if case let .server(code, _, _) = error, code == "ONBOARDING_REQUIRED" {
                    store.go(to: .name)
                } else {
                    throw error
                }
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "Couldn’t sign you in. Try again."
            errorMessage = message
            errorIsFocused = true
            UIAccessibility.post(notification: .announcement, argument: message)
            throw error
        }
    }
}

private struct EmailAuthenticationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(OutlyTheme.self) private var theme
    let intent: AuthIntent
    let authenticate: (EmailAuthCredentials) async throws -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)

                    SecureField("Password", text: $password)
                        .textContentType(intent == .signUp ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(theme.error)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Text(intent == .signUp ? "Create account" : "Log in")
                            Spacer()
                            if isSubmitting { ProgressView() }
                        }
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle(intent == .signUp ? "Sign up with email" : "Log in with email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { focusedField = .email }
    }

    private var canSubmit: Bool {
        email.contains("@") && email.contains(".") && password.count >= 8
    }

    @MainActor
    private func submit() async {
        guard canSubmit, !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await authenticate(EmailAuthCredentials(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password
            ))
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Couldn’t continue with email."
        }
    }
}

private struct AuthenticationProviderButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let provider: AuthProvider

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: OutlyMetrics.controlHeight)
            .foregroundStyle(foregroundColor)
            .background(
                backgroundColor.opacity(configuration.isPressed ? 0.76 : 1),
                in: RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.58)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        switch provider {
        case .apple: .white
        case .facebook: Color(hex: 0x1877F2)
        case .google: Color(hex: 0x131314)
        case .email: theme.elevatedSurface
        }
    }

    private var foregroundColor: Color {
        switch provider {
        case .apple: .black
        case .facebook: .white
        case .google, .email: theme.primaryText
        }
    }

    private var borderColor: Color {
        switch provider {
        case .google: Color(hex: 0x8E918F)
        case .email: theme.border
        case .facebook, .apple: .clear
        }
    }
}

private struct FacebookAuthMark: View {
    var body: some View {
        Text("f")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .offset(y: 1)
        .frame(width: 20, height: 20)
    }
}

private struct NameOnboardingView: View {
    @Environment(DemoStore.self) private var store
    @Environment(OutlyTheme.self) private var theme
    @FocusState private var focused: Bool
    @State private var error: String?
    @AccessibilityFocusState private var errorIsFocused: Bool

    var body: some View {
        OnboardingShell(
            step: 1,
            title: "What should we call you?",
            description: "Only you can see this.",
            onBack: { store.go(to: .auth) }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                SectionEyebrow(text: "First name")
                TextField("Enter your first name", text: Binding(
                    get: { store.profile.firstName },
                    set: {
                        store.setFirstName($0)
                        error = nil
                        errorIsFocused = false
                    }
                ))
                .textContentType(.givenName)
                .submitLabel(.next)
                .focused($focused)
                .onSubmit(advance)
                .padding(.horizontal, 15)
                .frame(minHeight: OutlyMetrics.controlHeight)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius).stroke(error == nil ? theme.border : theme.error, lineWidth: 1) }
                .accessibilityIdentifier("first-name")
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(theme.error)
                        .accessibilityLabel("Error: \(error)")
                        .accessibilityFocused($errorIsFocused)
                }
            }
        } footer: {
            Button("Next", action: advance)
                .buttonStyle(StandardActionButtonStyle())
                .accessibilityIdentifier("onboarding-next")
        }
        .onAppear { focused = true }
    }

    private func advance() {
        guard !store.submitName() else { return }
        let message = "Please enter your first name"
        error = message
        focused = true
        errorIsFocused = true
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

private struct AgeOnboardingView: View {
    @Environment(DemoStore.self) private var store
    @Environment(OutlyTheme.self) private var theme
    @State private var dateOfBirth = Calendar.current.date(
        byAdding: .year,
        value: -25,
        to: Date()
    ) ?? Date()

    private var latestEligibleBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -19, to: Date()) ?? Date()
    }

    private var earliestBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date.distantPast
    }

    var body: some View {
        OnboardingShell(
            step: 2,
            title: "What’s your date of birth?",
            description: "You must be 19 or older. This can’t be changed later.",
            onBack: { store.go(to: .name) }
        ) {
            DatePicker(
                "Date of birth",
                selection: $dateOfBirth,
                in: earliestBirthDate ... latestEligibleBirthDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                theme.surface,
                in: RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
                    .stroke(theme.border, lineWidth: 1)
            }
            .accessibilityLabel("Date of birth")
            .accessibilityIdentifier("date-of-birth")
        } footer: {
            Button("Next") {
                store.setDateOfBirth(dateOfBirth)
                store.go(to: .gender)
            }
                .buttonStyle(StandardActionButtonStyle())
                .accessibilityIdentifier("onboarding-next")
        }
        .onAppear {
            if let savedDate = store.profile.dateOfBirth {
                dateOfBirth = min(savedDate, latestEligibleBirthDate)
            }
        }
    }
}

private struct GenderOnboardingView: View {
    @Environment(DemoStore.self) private var store
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.appServices) private var services
    @State private var selection: UserGender?
    @State private var hasAcceptedLegal = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        OnboardingShell(
            step: 3,
            totalSteps: 3,
            title: "How do you identify?",
            description: "Required for tonight’s anonymous crowd breakdown.",
            onBack: { store.go(to: .age) }
        ) {
            VStack(spacing: 8) {
                ForEach(UserGender.allCases) { gender in
                    Button {
                        selection = gender
                        errorMessage = nil
                    } label: {
                        HStack {
                            Text(gender.title)
                            Spacer()
                            Image(systemName: selection == gender ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection == gender ? theme.accent : theme.mutedText)
                        }
                        .frame(minHeight: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == gender ? .isSelected : [])
                }

                Divider()
                    .overlay(theme.border)
                    .padding(.vertical, 10)

                legalConsent

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(theme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
            }
        } footer: {
            Button {
                Task { await finish() }
            } label: {
                HStack {
                    Text("Finish")
                    if isSubmitting { ProgressView().tint(.black) }
                }
            }
            .buttonStyle(StandardActionButtonStyle())
            .disabled(selection == nil || !hasAcceptedLegal || isSubmitting)
            .accessibilityIdentifier("onboarding-finish")
        }
        .onAppear { selection = store.profile.gender }
    }

    private var legalConsent: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                hasAcceptedLegal.toggle()
            } label: {
                Image(systemName: hasAcceptedLegal ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(hasAcceptedLegal ? theme.accent : theme.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agree to the Terms of Service and Privacy Policy")
            .accessibilityValue(hasAcceptedLegal ? "Agreed" : "Not agreed")
            .accessibilityIdentifier("legal-consent")

            VStack(alignment: .leading, spacing: 5) {
                Text("I agree to Outly’s")
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryText)

                HStack(spacing: 5) {
                    Link("Terms of Service", destination: OutlyLegal.termsURL)
                    Text("and")
                        .foregroundStyle(theme.mutedText)
                    Link("Privacy Policy", destination: OutlyLegal.privacyURL)
                }
                .font(.footnote.weight(.semibold))
                .tint(theme.primaryText)
            }
            .padding(.top, 3)

            Spacer(minLength: 0)
        }
    }

    @MainActor
    private func finish() async {
        guard let selection,
              let dateOfBirth = store.profile.dateOfBirth,
              !isSubmitting
        else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            store.setGender(selection)
            let birthComponents = Calendar.autoupdatingCurrent.dateComponents(
                [.year, .month, .day],
                from: dateOfBirth
            )
            try await services.completeOnboarding(ConsumerOnboardingSubmission(
                firstName: store.profile.firstName,
                dateOfBirth: birthComponents,
                gender: selection
            ))
            if !services.isDemo {
                store.applyConsumerBootstrap(try await services.loadConsumerBootstrap())
            }
            store.go(to: .complete)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Couldn’t finish your account. Try again."
        }
    }
}

private struct OnboardingCompleteView: View {
    @Environment(DemoStore.self) private var store
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            WingedOMarkView()
                .shadow(color: .black.opacity(0.5), radius: 18, y: 12)
            Text("You’re in.")
                .font(.largeTitle.weight(.bold))
                .padding(.top, 32)
            Text("Your map is ready, \(store.profile.firstName).")
                .font(.body)
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 14)
                .padding(.horizontal, 24)
            Spacer()
            Button("Explore Toronto") { store.finishOnboarding() }
                .buttonStyle(StandardActionButtonStyle())
                .accessibilityIdentifier("explore-toronto")
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }
}

private struct OnboardingShell<Content: View, Footer: View>: View {
    @Environment(OutlyTheme.self) private var theme
    let step: Int
    let totalSteps: Int
    let title: String
    var description: String?
    let onBack: () -> Void
    let content: Content
    let footer: Footer

    init(
        step: Int,
        totalSteps: Int = 3,
        title: String,
        description: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.step = step
        self.totalSteps = totalSteps
        self.title = title
        self.description = description
        self.onBack = onBack
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader(onBack: onBack)
            ProgressView(value: Double(step), total: Double(totalSteps))
                .tint(theme.accent)
                .padding(.horizontal, 22)
                .accessibilityLabel("Onboarding step \(step) of \(totalSteps)")

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionEyebrow(text: "Step \(step) of \(totalSteps)")
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .padding(.top, 10)
                    if let description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .lineSpacing(4)
                            .padding(.top, 12)
                    }
                    content.padding(.top, 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            BottomActionBar { footer }
        }
    }
}
