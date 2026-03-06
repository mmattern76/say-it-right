import AVFoundation

// MARK: - BarbaraVoiceProfile

/// Configuration for Barbara's speaking voice, per language.
///
/// Encapsulates the selected Apple TTS voice, speech rate, pitch, and volume
/// so that voice parameters are not hardcoded in the playback service.
///
/// ## Voice Selection Rationale
///
/// **German (de-DE):**
/// Primary: `com.apple.voice.enhanced.de-DE.Helena`
/// Helena (Enhanced) is a warm, clear female voice with a measured tone that
/// conveys authority without coldness. She sounds like a confident teacher
/// addressing older students — direct but approachable. The enhanced variant
/// is significantly more natural than the compact version.
/// Fallback: `com.apple.voice.compact.de-DE.Anna`
/// Anna (Compact) is the standard German female voice, available on all
/// devices without download. Less natural but still intelligible.
///
/// **English (en-GB):**
/// Primary: `com.apple.voice.enhanced.en-GB.Stephanie`
/// Stephanie (Enhanced, British English) has a warm, authoritative quality
/// that matches Barbara's personality — she sounds like a well-spoken teacher,
/// not a chirpy assistant. British English reinforces the slightly formal,
/// structured communication style Barbara models.
/// Fallback: `com.apple.voice.compact.en-GB.Daniel`
/// Daniel (Compact, British English) is widely available and has a clear,
/// measured delivery. Male voice as fallback is acceptable — the key
/// quality is clarity and authority.
///
/// ## Tuning Parameters
///
/// - **Rate (0.42):** Slightly below default (0.5). Barbara speaks with
///   deliberate pacing — she never rushes. This gives learners time to
///   absorb structural feedback. Not so slow as to feel patronising.
///
/// - **Pitch (1.05):** Very slightly above neutral (1.0). Adds a touch of
///   warmth without sounding high-pitched or childish. Barbara is warm but
///   grounded.
///
/// - **Volume (0.9):** Slightly below maximum to avoid harshness on device
///   speakers and headphones. Comfortable for sustained listening.
///
/// ## Contextual Variation
///
/// Barbara speaks slightly differently depending on context:
/// - **Correction:** Standard rate, pitch stays neutral — firm and clear.
/// - **Praise:** Marginally slower rate, very slight pitch lift — warmth
///   comes through without gushing.
/// - **Observation:** Slightly faster, neutral pitch — matter-of-fact,
///   analytical tone.
///
/// Apple TTS has limited expressive control, so these variations are subtle.
/// The goal is to avoid monotony rather than simulate full emotional range.
struct BarbaraVoiceProfile: Sendable, Equatable {

    /// The context in which Barbara is speaking, used for subtle voice variation.
    enum SpeechContext: Sendable, Equatable {
        /// A correction or redirect: "That's not a conclusion, that's a preamble."
        case correction
        /// Praise (used sparingly): "Now *that* is how you make a point."
        case praise
        /// A structural observation or instruction: "Your second group lacks a governing thought."
        case observation
    }

    // MARK: - Voice Identifiers

    /// Preferred enhanced voice identifier for the language.
    let preferredVoiceIdentifier: String

    /// Fallback compact voice identifier if the enhanced voice is not available.
    let fallbackVoiceIdentifier: String

    // MARK: - Base Parameters

    /// Base speech rate (0.0–1.0).
    let baseRate: Float

    /// Base pitch multiplier (0.5–2.0).
    let basePitch: Float

    /// Volume (0.0–1.0).
    let volume: Float

    // MARK: - Contextual Adjustments

    /// Rate adjustment for corrections (added to baseRate).
    let correctionRateAdjustment: Float

    /// Pitch adjustment for corrections (added to basePitch).
    let correctionPitchAdjustment: Float

    /// Rate adjustment for praise (added to baseRate).
    let praiseRateAdjustment: Float

    /// Pitch adjustment for praise (added to basePitch).
    let praisePitchAdjustment: Float

    /// Rate adjustment for observations (added to baseRate).
    let observationRateAdjustment: Float

    /// Pitch adjustment for observations (added to basePitch).
    let observationPitchAdjustment: Float

    // MARK: - Computed Properties

    /// Returns the rate for a given speech context, clamped to valid range.
    func rate(for context: SpeechContext) -> Float {
        let adjustment: Float
        switch context {
        case .correction:
            adjustment = correctionRateAdjustment
        case .praise:
            adjustment = praiseRateAdjustment
        case .observation:
            adjustment = observationRateAdjustment
        }
        return clamp(baseRate + adjustment, min: 0.0, max: 1.0)
    }

    /// Returns the pitch for a given speech context, clamped to valid range.
    func pitch(for context: SpeechContext) -> Float {
        let adjustment: Float
        switch context {
        case .correction:
            adjustment = correctionPitchAdjustment
        case .praise:
            adjustment = praisePitchAdjustment
        case .observation:
            adjustment = observationPitchAdjustment
        }
        return clamp(basePitch + adjustment, min: 0.5, max: 2.0)
    }

    /// Resolves the best available voice identifier on this device.
    ///
    /// Checks whether the preferred (enhanced) voice is installed. If not,
    /// falls back to the compact voice. If neither is available, returns nil
    /// and the system will use its default voice for the language.
    func resolvedVoiceIdentifier() -> String? {
        let available = Set(AVSpeechSynthesisVoice.speechVoices().map(\.identifier))
        if available.contains(preferredVoiceIdentifier) {
            return preferredVoiceIdentifier
        }
        if available.contains(fallbackVoiceIdentifier) {
            return fallbackVoiceIdentifier
        }
        return nil
    }

    /// Builds a `TTSConfiguration` for the given speech context.
    ///
    /// This is the bridge between `BarbaraVoiceProfile` (character config)
    /// and `TTSConfiguration` (engine config).
    func ttsConfiguration(for context: SpeechContext) -> TTSConfiguration {
        TTSConfiguration(
            rate: rate(for: context),
            pitchMultiplier: pitch(for: context),
            volume: volume,
            voiceIdentifier: resolvedVoiceIdentifier()
        )
    }

    // MARK: - Private

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Predefined Profiles

extension BarbaraVoiceProfile {

    /// Barbara's German voice profile.
    ///
    /// Uses Helena (Enhanced) as primary voice — warm, clear, authoritative.
    /// Falls back to Anna (Compact) on devices without the enhanced voice downloaded.
    static let german = BarbaraVoiceProfile(
        preferredVoiceIdentifier: "com.apple.voice.enhanced.de-DE.Helena",
        fallbackVoiceIdentifier: "com.apple.voice.compact.de-DE.Anna",
        baseRate: 0.42,
        basePitch: 1.05,
        volume: 0.9,
        correctionRateAdjustment: 0.0,
        correctionPitchAdjustment: -0.02,
        praiseRateAdjustment: -0.03,
        praisePitchAdjustment: 0.03,
        observationRateAdjustment: 0.02,
        observationPitchAdjustment: 0.0
    )

    /// Barbara's English voice profile.
    ///
    /// Uses Stephanie (Enhanced, British English) as primary voice — warm,
    /// authoritative, slightly formal. Falls back to Daniel (Compact) which
    /// is widely available.
    static let english = BarbaraVoiceProfile(
        preferredVoiceIdentifier: "com.apple.voice.enhanced.en-GB.Stephanie",
        fallbackVoiceIdentifier: "com.apple.voice.compact.en-GB.Daniel",
        baseRate: 0.42,
        basePitch: 1.05,
        volume: 0.9,
        correctionRateAdjustment: 0.0,
        correctionPitchAdjustment: -0.02,
        praiseRateAdjustment: -0.03,
        praisePitchAdjustment: 0.03,
        observationRateAdjustment: 0.02,
        observationPitchAdjustment: 0.0
    )

    /// Returns the appropriate voice profile for the given app language.
    static func profile(for language: AppLanguage) -> BarbaraVoiceProfile {
        switch language {
        case .de: .german
        case .en: .english
        }
    }

    /// All sample phrases used during voice testing, per language.
    ///
    /// Each array contains one correction, one praise, and one structural observation
    /// — the three primary modes of Barbara's feedback.
    static let samplePhrases: [AppLanguage: [String]] = [
        .de: [
            // Correction
            "Das ist keine Schlussfolgerung, das ist eine Einleitung. Fang nochmal an.",
            // Praise
            "Jetzt ja. So macht man einen Punkt.",
            // Structural observation
            "Deine zweite Gruppe hat keinen leitenden Gedanken. Ohne den fehlt die Richtung."
        ],
        .en: [
            // Correction
            "That's not a conclusion, that's a preamble. Start over.",
            // Praise
            "Now that is how you make a point.",
            // Structural observation
            "Your second group lacks a governing thought. Without it, the reader has no direction."
        ]
    ]
}
