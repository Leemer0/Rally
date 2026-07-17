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
            case .gender, .interested:
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
    @State private var errorMessage: String?
    @AccessibilityFocusState private var errorIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowHeader { store.go(to: .welcome) }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    WingedOMarkView(compact: true)
                    Text(store.authIntent == .signUp ? "Create your account." : "Welcome back.")
                        .font(.largeTitle.weight(.bold))
                        .padding(.top, OutlyMetrics.spacing32)
                    Text(store.authIntent == .signUp ? "Two quick details. Nothing public." : "Continue to tonight’s map.")
                        .font(.body)
                        .foregroundStyle(theme.secondaryText)
                        .lineSpacing(4)
                        .padding(.top, 16)

                    VStack(spacing: 12) {
                        authButton(.email, systemImage: "envelope.fill")
                            .accessibilityIdentifier("auth-email")
                        authButton(.google, systemImage: "person.crop.circle")
                    }
                    .padding(.top, OutlyMetrics.spacing32)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(theme.error)
                            .padding(.top, 14)
                            .accessibilityLabel("Error: \(errorMessage)")
                            .accessibilityFocused($errorIsFocused)
                    }
                }
                .padding(.horizontal, OutlyMetrics.edge)
                .padding(.bottom, 30)
            }
        }
    }

    @ViewBuilder
    private func authButton(_ provider: AuthProvider, systemImage: String) -> some View {
        let button = Button {
            Task { await authenticate(provider) }
        } label: {
            HStack {
                Image(systemName: systemImage)
                Text("Continue with \(provider.title)")
                Spacer()
                if loadingProvider == provider { ProgressView().tint(theme.primaryText) }
            }
            .padding(.horizontal, 18)
        }
        .disabled(loadingProvider != nil)

        if provider == .email {
            button.buttonStyle(StandardActionButtonStyle())
        } else {
            button.buttonStyle(SecondaryButtonStyle())
        }
    }

    private func authenticate(_ provider: AuthProvider) async {
        loadingProvider = provider
        errorMessage = nil
        errorIsFocused = false
        defer { loadingProvider = nil }
        do {
            _ = try await services.authenticate(provider)
            guard !Task.isCancelled else { return }
            if store.authIntent == .signUp {
                store.go(to: .name)
            } else {
                store.completeLogin()
            }
        } catch is CancellationError {
            return
        } catch {
            let message = "Couldn’t sign you in. Try again."
            errorMessage = message
            errorIsFocused = true
            UIAccessibility.post(notification: .announcement, argument: message)
        }
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

    var body: some View {
        OnboardingShell(
            step: 2,
            title: "How old are you?",
            description: "Ages 19–40.",
            onBack: { store.go(to: .name) }
        ) {
            Picker(
                "Age",
                selection: Binding(
                    get: { store.profile.age },
                    set: { store.setAge($0) }
                )
            ) {
                ForEach(19 ... 40, id: \.self) { age in
                    Text("\(age)")
                        .tag(age)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Age")
            .accessibilityValue("\(store.profile.age)")
            .accessibilityIdentifier("age-picker")
        } footer: {
            Button("Finish") { store.go(to: .complete) }
                .buttonStyle(StandardActionButtonStyle())
                .accessibilityIdentifier("onboarding-next")
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
    let title: String
    var description: String?
    let onBack: () -> Void
    let content: Content
    let footer: Footer

    init(
        step: Int,
        title: String,
        description: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.step = step
        self.title = title
        self.description = description
        self.onBack = onBack
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader(onBack: onBack)
            ProgressView(value: Double(step), total: 2)
                .tint(theme.accent)
                .padding(.horizontal, 22)
                .accessibilityLabel("Onboarding step \(step) of 2")

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionEyebrow(text: "Step \(step) of 2")
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
