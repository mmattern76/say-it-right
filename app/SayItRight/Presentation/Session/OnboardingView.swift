import SwiftUI
import AVFoundation

/// First-time welcome experience with Barbara introducing herself.
///
/// Flow:
/// 1. Barbara's portrait appears with a welcome message
/// 2. Text is typed out character-by-character with TTS narration
/// 3. User picks an avatar (Maxi or Alex) and enters their name
/// 4. Barbara delivers a closing pep-talk
///
/// Replayable: The welcome message can be replayed from the profile screen.
struct OnboardingView: View {
    @Bindable var settings: AppSettings
    var onComplete: () -> Void

    @State private var phase: OnboardingPhase = .welcome
    @State private var typedText = ""
    @State private var isTyping = false
    @State private var selectedAvatar: LearnerAvatar?
    @State private var nameInput = ""
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Barbara's portrait
            Image("launch-barbara")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding(.horizontal, 40)

            Spacer().frame(height: 24)

            // Speech bubble
            speechBubble

            Spacer().frame(height: 24)

            // Action area
            actionArea

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .task {
            await startPhase(.welcome)
        }
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Barbara")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(typedText)
                .font(.body)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(minHeight: 120, alignment: .top)
        .padding(.horizontal)
    }

    // MARK: - Action Area

    @ViewBuilder
    private var actionArea: some View {
        switch phase {
        case .welcome:
            if !isTyping {
                Button("Let's go!") {
                    Task { await startPhase(.pickAvatar) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .transition(.opacity)
            }

        case .pickAvatar:
            if !isTyping {
                VStack(spacing: 16) {
                    HStack(spacing: 32) {
                        ForEach(LearnerAvatar.allCases, id: \.self) { avatar in
                            VStack(spacing: 8) {
                                LearnerAvatarView(avatar: avatar, size: 80)
                                    .overlay {
                                        if selectedAvatar == avatar {
                                            Circle()
                                                .stroke(Color.accentColor, lineWidth: 3)
                                                .frame(width: 84, height: 84)
                                        }
                                    }
                                Text(avatar.displayName)
                                    .font(.subheadline)
                            }
                            .onTapGesture { selectedAvatar = avatar }
                        }
                    }

                    TextField(settings.language == "de" ? "Dein Name" : "Your name", text: $nameInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .multilineTextAlignment(.center)

                    if selectedAvatar != nil && !nameInput.isEmpty {
                        Button(settings.language == "de" ? "Weiter" : "Continue") {
                            settings.selectedAvatar = selectedAvatar?.rawValue
                            settings.displayName = nameInput
                            Task { await startPhase(.pepTalk) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .transition(.opacity)
                    }
                }
            }

        case .pepTalk:
            if !isTyping {
                Button(settings.language == "de" ? "Los geht's!" : "Let's start!") {
                    settings.hasCompletedOnboarding = true
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Phase Management

    private func startPhase(_ newPhase: OnboardingPhase) async {
        phase = newPhase
        let message = newPhase.message(language: settings.language, name: nameInput)
        await typeAndSpeak(message)
    }

    // MARK: - Typing + TTS

    private func typeAndSpeak(_ text: String) async {
        typedText = ""
        isTyping = true

        // Start TTS
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: settings.language == "de" ? "de-DE" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)

        // Type out character by character
        for char in text {
            typedText.append(char)
            try? await Task.sleep(for: .milliseconds(30))
        }

        isTyping = false
    }
}

// MARK: - Onboarding Phases

private enum OnboardingPhase {
    case welcome
    case pickAvatar
    case pepTalk

    func message(language: String, name: String) -> String {
        if language == "de" {
            switch self {
            case .welcome:
                return "Hallo! Ich bin Barbara. Ich bringe dir bei, wie du deine Gedanken so strukturierst, dass jeder sie versteht. Klar, logisch, auf den Punkt. Keine langen Reden, kein Drumherum. Bereit?"
            case .pickAvatar:
                return "Gut. Bevor wir anfangen: Wer bist du? Such dir einen Avatar aus und sag mir deinen Namen."
            case .pepTalk:
                return "Perfekt, \(name)! Ab jetzt lernst du, wie man Argumente baut, die sitzen. Ich bin streng, aber fair. Wenn du Unsinn redest, sag ich's dir. Wenn du's drauf hast, auch. Fangen wir an!"
            }
        } else {
            switch self {
            case .welcome:
                return "Hello! I'm Barbara. I'll teach you how to structure your thinking so anyone can follow it. Clear, logical, straight to the point. No rambling, no filler. Ready?"
            case .pickAvatar:
                return "Good. Before we start: who are you? Pick an avatar and tell me your name."
            case .pepTalk:
                return "Perfect, \(name)! From now on, you'll learn how to build arguments that land. I'm strict, but fair. If you're talking nonsense, I'll tell you. If you nail it, I'll tell you that too. Let's go!"
            }
        }
    }
}

/// Standalone replay view for the welcome message (accessible from profile).
struct WelcomeReplayView: View {
    @Bindable var settings: AppSettings

    @State private var typedText = ""
    @State private var isPlaying = false
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 24) {
            Image("launch-barbara")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                Text("Barbara")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(typedText)
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Button {
                Task { await playWelcome() }
            } label: {
                Label(isPlaying ? "Playing..." : "Replay Welcome", systemImage: "play.circle")
            }
            .buttonStyle(.bordered)
            .disabled(isPlaying)
        }
        .padding()
        .navigationTitle("Welcome")
    }

    private func playWelcome() async {
        let message = OnboardingPhase.welcome.message(language: settings.language, name: "")
        typedText = ""
        isPlaying = true

        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: settings.language == "de" ? "de-DE" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)

        for char in message {
            typedText.append(char)
            try? await Task.sleep(for: .milliseconds(30))
        }

        isPlaying = false
    }
}

#Preview("Onboarding") {
    OnboardingView(settings: .shared) { }
}

#Preview("Welcome Replay") {
    NavigationStack {
        WelcomeReplayView(settings: .shared)
    }
}
