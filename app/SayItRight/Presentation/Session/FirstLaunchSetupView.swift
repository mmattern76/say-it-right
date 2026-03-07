import SwiftUI

/// First-launch setup flow for new users.
///
/// Guides the user through:
/// 1. API key entry (required to use the app)
/// 2. Language selection
/// 3. Onboarding with Barbara
///
/// This view is shown when no API key is configured and onboarding
/// has not been completed. It ensures the app is functional before
/// the user reaches the main chat interface.
struct FirstLaunchSetupView: View {
    @Bindable var settings: AppSettings
    var onComplete: () -> Void

    @State private var step: SetupStep = ConfigProvider.anthropicAPIKey != nil ? .language : .apiKey
    @State private var apiKeyInput = ""
    @State private var showKey = false
    @State private var isValidating = false
    @State private var validationError: String?

    var body: some View {
        Group {
            switch step {
            case .apiKey:
                apiKeyStep
            case .language:
                languageStep
            case .onboarding:
                OnboardingView(settings: settings) {
                    onComplete()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - API Key Step

    private var apiKeyStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("launch-barbara")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding(.horizontal, 40)

            Spacer().frame(height: 24)

            VStack(spacing: 16) {
                Text("Say it right!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("To get started, enter your Anthropic API key. This key is stored securely on your device and never leaves it.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack {
                    Group {
                        if showKey {
                            TextField("sk-ant-...", text: $apiKeyInput)
                                .textContentType(.password)
                                #if os(iOS)
                                .autocapitalization(.none)
                                #endif
                        } else {
                            SecureField("sk-ant-...", text: $apiKeyInput)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 32)

                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    saveAPIKey()
                } label: {
                    if isValidating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                .accessibilityIdentifier("apiKeyContinueButton")
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.clear, Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Language Step

    private var languageStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("launch-barbara")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding(.horizontal, 40)

            Spacer().frame(height: 24)

            VStack(spacing: 24) {
                Text("Choose Your Language")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Barbara speaks both English and German. You can change this later in settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack(spacing: 24) {
                    languageButton(
                        flag: "🇬🇧",
                        name: "English",
                        code: "en"
                    )
                    languageButton(
                        flag: "🇩🇪",
                        name: "Deutsch",
                        code: "de"
                    )
                }

                Button("Continue") {
                    step = .onboarding
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("languageContinueButton")
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.clear, Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func languageButton(flag: String, name: String, code: String) -> some View {
        Button {
            settings.language = code
        } label: {
            VStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 48))
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(width: 120, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(settings.language == code ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(settings.language == code ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: settings.language == code ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }

        guard key.hasPrefix("sk-ant-") else {
            validationError = "API key should start with \"sk-ant-\""
            return
        }

        isValidating = true
        validationError = nil

        settings.apiKeyOverride = key
        isValidating = false
        step = .language
    }
}

// MARK: - Setup Step

/// Steps in the first-launch setup flow.
enum SetupStep: Int, Comparable {
    case apiKey = 0
    case language = 1
    case onboarding = 2

    static func < (lhs: SetupStep, rhs: SetupStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Previews

#Preview("API Key Step") {
    FirstLaunchSetupView(settings: .shared) { }
}

#Preview("Language Step") {
    let settings = AppSettings.shared
    FirstLaunchSetupView(settings: settings) { }
        .onAppear {
            settings.apiKeyOverride = "sk-ant-test"
        }
}
