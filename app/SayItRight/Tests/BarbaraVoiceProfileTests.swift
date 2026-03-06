import Testing
@testable import SayItRight

// MARK: - BarbaraVoiceProfile Tests

@Suite("BarbaraVoiceProfile")
struct BarbaraVoiceProfileTests {

    // MARK: - Predefined Profile Tests

    @Test("German profile has expected voice identifiers")
    func germanProfileVoiceIdentifiers() {
        let profile = BarbaraVoiceProfile.german
        #expect(profile.preferredVoiceIdentifier == "com.apple.voice.enhanced.de-DE.Helena")
        #expect(profile.fallbackVoiceIdentifier == "com.apple.voice.compact.de-DE.Anna")
    }

    @Test("English profile has expected voice identifiers")
    func englishProfileVoiceIdentifiers() {
        let profile = BarbaraVoiceProfile.english
        #expect(profile.preferredVoiceIdentifier == "com.apple.voice.enhanced.en-GB.Stephanie")
        #expect(profile.fallbackVoiceIdentifier == "com.apple.voice.compact.en-GB.Daniel")
    }

    @Test("German profile base parameters are within valid ranges")
    func germanProfileBaseParameters() {
        let profile = BarbaraVoiceProfile.german
        #expect(profile.baseRate >= 0.0 && profile.baseRate <= 1.0)
        #expect(profile.basePitch >= 0.5 && profile.basePitch <= 2.0)
        #expect(profile.volume >= 0.0 && profile.volume <= 1.0)
    }

    @Test("English profile base parameters are within valid ranges")
    func englishProfileBaseParameters() {
        let profile = BarbaraVoiceProfile.english
        #expect(profile.baseRate >= 0.0 && profile.baseRate <= 1.0)
        #expect(profile.basePitch >= 0.5 && profile.basePitch <= 2.0)
        #expect(profile.volume >= 0.0 && profile.volume <= 1.0)
    }

    @Test("Base rate is moderate — not too fast, not too slow")
    func baseRateIsModerate() {
        // Barbara speaks deliberately. Rate should be below default (0.5) but not sluggish.
        let german = BarbaraVoiceProfile.german
        let english = BarbaraVoiceProfile.english
        #expect(german.baseRate >= 0.35 && german.baseRate <= 0.50)
        #expect(english.baseRate >= 0.35 && english.baseRate <= 0.50)
    }

    @Test("Base pitch is warm but not high")
    func basePitchIsWarm() {
        // Pitch should be near neutral (1.0), slightly above for warmth.
        let german = BarbaraVoiceProfile.german
        let english = BarbaraVoiceProfile.english
        #expect(german.basePitch >= 1.0 && german.basePitch <= 1.15)
        #expect(english.basePitch >= 1.0 && english.basePitch <= 1.15)
    }

    @Test("Volume is normalised for comfortable listening")
    func volumeIsComfortable() {
        // Not full blast (1.0), not quiet. Should be in the 0.8–0.95 range.
        let german = BarbaraVoiceProfile.german
        let english = BarbaraVoiceProfile.english
        #expect(german.volume >= 0.8 && german.volume <= 0.95)
        #expect(english.volume >= 0.8 && english.volume <= 0.95)
    }

    // MARK: - Language Selection

    @Test("Profile for German language returns German profile")
    func profileForGerman() {
        let profile = BarbaraVoiceProfile.profile(for: .de)
        #expect(profile == BarbaraVoiceProfile.german)
    }

    @Test("Profile for English language returns English profile")
    func profileForEnglish() {
        let profile = BarbaraVoiceProfile.profile(for: .en)
        #expect(profile == BarbaraVoiceProfile.english)
    }

    // MARK: - Contextual Variation Tests

    @Test("Correction rate equals base rate (no adjustment)")
    func correctionRate() {
        let profile = BarbaraVoiceProfile.german
        let rate = profile.rate(for: .correction)
        #expect(rate == profile.baseRate + profile.correctionRateAdjustment)
    }

    @Test("Praise rate is slower than base rate")
    func praiseRateIsSlower() {
        let profile = BarbaraVoiceProfile.german
        let praiseRate = profile.rate(for: .praise)
        let baseRate = profile.rate(for: .correction)
        #expect(praiseRate < baseRate)
    }

    @Test("Observation rate is faster than base rate")
    func observationRateIsFaster() {
        let profile = BarbaraVoiceProfile.german
        let observationRate = profile.rate(for: .observation)
        let baseRate = profile.rate(for: .correction)
        #expect(observationRate > baseRate)
    }

    @Test("Praise pitch is higher than correction pitch")
    func praisePitchIsHigher() {
        let profile = BarbaraVoiceProfile.english
        let praisePitch = profile.pitch(for: .praise)
        let correctionPitch = profile.pitch(for: .correction)
        #expect(praisePitch > correctionPitch)
    }

    @Test("Correction pitch is slightly below base pitch")
    func correctionPitchIsSlightlyLower() {
        let profile = BarbaraVoiceProfile.english
        let correctionPitch = profile.pitch(for: .correction)
        #expect(correctionPitch <= profile.basePitch)
    }

    @Test("All contextual rates stay within valid range 0.0–1.0")
    func contextualRatesInRange() {
        for language in AppLanguage.allCases {
            let profile = BarbaraVoiceProfile.profile(for: language)
            for context: BarbaraVoiceProfile.SpeechContext in [.correction, .praise, .observation] {
                let rate = profile.rate(for: context)
                #expect(rate >= 0.0 && rate <= 1.0,
                        "Rate \(rate) out of range for \(language)/\(context)")
            }
        }
    }

    @Test("All contextual pitches stay within valid range 0.5–2.0")
    func contextualPitchesInRange() {
        for language in AppLanguage.allCases {
            let profile = BarbaraVoiceProfile.profile(for: language)
            for context: BarbaraVoiceProfile.SpeechContext in [.correction, .praise, .observation] {
                let pitch = profile.pitch(for: context)
                #expect(pitch >= 0.5 && pitch <= 2.0,
                        "Pitch \(pitch) out of range for \(language)/\(context)")
            }
        }
    }

    @Test("Contextual variations are subtle — within 10% of base")
    func contextualVariationsAreSubtle() {
        for language in AppLanguage.allCases {
            let profile = BarbaraVoiceProfile.profile(for: language)
            for context: BarbaraVoiceProfile.SpeechContext in [.correction, .praise, .observation] {
                let rate = profile.rate(for: context)
                let pitch = profile.pitch(for: context)
                #expect(abs(rate - profile.baseRate) <= profile.baseRate * 0.1,
                        "Rate variation too large for \(language)/\(context)")
                #expect(abs(pitch - profile.basePitch) <= profile.basePitch * 0.1,
                        "Pitch variation too large for \(language)/\(context)")
            }
        }
    }

    // MARK: - TTSConfiguration Bridge Tests

    @Test("ttsConfiguration produces valid TTSConfiguration for each context")
    func ttsConfigurationBridge() {
        let profile = BarbaraVoiceProfile.german
        let config = profile.ttsConfiguration(for: .correction)

        #expect(config.rate == profile.rate(for: .correction))
        #expect(config.pitchMultiplier == profile.pitch(for: .correction))
        #expect(config.volume == profile.volume)
    }

    @Test("ttsConfiguration for praise differs from correction")
    func ttsConfigurationDiffersByContext() {
        let profile = BarbaraVoiceProfile.english
        let correction = profile.ttsConfiguration(for: .correction)
        let praise = profile.ttsConfiguration(for: .praise)

        #expect(correction.rate != praise.rate)
        #expect(correction.pitchMultiplier != praise.pitchMultiplier)
        // Volume and voice stay the same across contexts
        #expect(correction.volume == praise.volume)
        #expect(correction.voiceIdentifier == praise.voiceIdentifier)
    }

    // MARK: - Sample Phrases Tests

    @Test("Sample phrases exist for both languages")
    func samplePhrasesExist() {
        #expect(BarbaraVoiceProfile.samplePhrases[.de] != nil)
        #expect(BarbaraVoiceProfile.samplePhrases[.en] != nil)
    }

    @Test("Each language has exactly 3 sample phrases (correction, praise, observation)")
    func samplePhrasesCount() {
        #expect(BarbaraVoiceProfile.samplePhrases[.de]?.count == 3)
        #expect(BarbaraVoiceProfile.samplePhrases[.en]?.count == 3)
    }

    @Test("Sample phrases are non-empty")
    func samplePhrasesAreNonEmpty() {
        for language in AppLanguage.allCases {
            guard let phrases = BarbaraVoiceProfile.samplePhrases[language] else {
                Issue.record("Missing phrases for \(language)")
                return
            }
            for phrase in phrases {
                #expect(!phrase.isEmpty, "Empty phrase found for \(language)")
            }
        }
    }

    // MARK: - Equatable Tests

    @Test("German and English profiles are not equal")
    func profilesAreDistinct() {
        #expect(BarbaraVoiceProfile.german != BarbaraVoiceProfile.english)
    }

    @Test("Same profile equals itself")
    func profileEquality() {
        #expect(BarbaraVoiceProfile.german == BarbaraVoiceProfile.german)
        #expect(BarbaraVoiceProfile.english == BarbaraVoiceProfile.english)
    }

    // MARK: - Voice Resolution Tests

    @Test("resolvedVoiceIdentifier returns preferred, fallback, or nil")
    func voiceResolution() {
        // We cannot control which voices are installed on CI/test machines,
        // but we can verify the method does not crash and returns a String?.
        let profile = BarbaraVoiceProfile.german
        let resolved = profile.resolvedVoiceIdentifier()
        // Result is either nil or one of the two configured identifiers
        if let resolved {
            #expect(
                resolved == profile.preferredVoiceIdentifier ||
                resolved == profile.fallbackVoiceIdentifier
            )
        }
    }

    // MARK: - Edge Case: Clamping

    @Test("Rate clamping works for extreme adjustments")
    func rateClamping() {
        let extreme = BarbaraVoiceProfile(
            preferredVoiceIdentifier: "test",
            fallbackVoiceIdentifier: "test",
            baseRate: 0.95,
            basePitch: 1.0,
            volume: 1.0,
            correctionRateAdjustment: 0.0,
            correctionPitchAdjustment: 0.0,
            praiseRateAdjustment: -0.03,
            praisePitchAdjustment: 0.03,
            observationRateAdjustment: 0.2, // Would push above 1.0
            observationPitchAdjustment: 0.0
        )
        #expect(extreme.rate(for: .observation) == 1.0) // Clamped
    }

    @Test("Pitch clamping works for extreme adjustments")
    func pitchClamping() {
        let extreme = BarbaraVoiceProfile(
            preferredVoiceIdentifier: "test",
            fallbackVoiceIdentifier: "test",
            baseRate: 0.5,
            basePitch: 0.5,
            volume: 1.0,
            correctionRateAdjustment: 0.0,
            correctionPitchAdjustment: -0.1, // Would push below 0.5
            praiseRateAdjustment: 0.0,
            praisePitchAdjustment: 0.0,
            observationRateAdjustment: 0.0,
            observationPitchAdjustment: 0.0
        )
        #expect(extreme.pitch(for: .correction) == 0.5) // Clamped
    }
}
