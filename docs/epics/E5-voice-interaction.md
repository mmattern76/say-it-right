# E5: Voice Interaction (TTS + STT)

## Vision
Barbara speaks to you, and you speak back. On iPhone, this transforms
the app from a typing exercise into a conversational drill — Barbara asks
a question out loud, you answer out loud, she critiques your structure
in real time. This is where Barbara comes fully alive as a character, and
where the app trains the hardest variant of structured thinking: doing
it orally, under conversational pressure, without the luxury of editing.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **TTS (Barbara speaks)**:
  - Barbara's responses read aloud with a warm, authoritative female voice
  - Voice selection/configuration for German and English
  - Playback controls (pause, replay)
  - Auto-play option (Barbara speaks immediately) vs. tap-to-play
- **STT (User speaks)**:
  - Speech-to-text for user responses in Build mode exercises
  - Real-time transcription display (user sees their words as they speak)
  - "Done" signal (tap to stop, or silence detection)
  - Error handling for poor audio, background noise
- **Voice-first session flow on iPhone**:
  - "Say it clearly" adapted for voice: Barbara asks → user speaks → Barbara evaluates → user revises verbally
  - "Elevator pitch" adapted for voice: timed spoken response
  - "Find the point" adapted for voice: text displayed, user speaks their extraction
- **Voice as optional layer on iPad/Mac**:
  - TTS available but not default on larger screens
  - STT available as input alternative to typing
- **Audio session management**: proper handling of interruptions (phone calls,
  notifications), AirPods/Bluetooth audio routing

### Out of Scope
- Custom voice model training for Barbara (use ElevenLabs or Apple TTS)
- Voice-only mode without any visual UI (always have text fallback)
- Voice interaction in Break mode's "Fix this mess" or "Spot the gap"
  (restructuring exercises need visual/text input)
- Accessibility: VoiceOver integration is separate from Barbara's TTS

### Success Criteria
- [ ] Barbara's spoken voice feels natural, warm, and authoritative
- [ ] Barbara sounds like the same character in German and English
- [ ] STT accurately transcribes user responses in both languages
- [ ] Voice-first "Say it clearly" session works end-to-end on iPhone
- [ ] Voice "Elevator pitch" correctly times and captures spoken response
- [ ] Audio routing works with AirPods, Bluetooth speakers, and built-in speakers
- [ ] Interruptions (phone calls, Siri) are handled gracefully
- [ ] Users can switch between voice and text input mid-session
- [ ] Voice interaction does not significantly increase API latency (TTS is local or streamed efficiently)

## Design Decisions
- **TTS provider**: Start with Apple built-in TTS (AVSpeechSynthesizer). Human review selects the best voice for Barbara's character in DE and EN. ElevenLabs is the upgrade path if quality is insufficient.
- **STT provider**: Apple Speech Framework (SFSpeechRecognizer) — free, on-device, supports DE and EN, good enough quality.
- **Voice-first on iPhone, voice-optional elsewhere**: The phone is the daily drill device. iPad and Mac users are more likely at a desk and may prefer typing.
- **Always show text**: Even in voice mode, Barbara's words appear as text. Voice is additive, not exclusive. This ensures accessibility and lets users re-read feedback.
- **No voice recording storage**: Transcribed text is stored in session history, not audio files. Privacy by design.

## Dependencies
- Depends on: E2 (app shell), E3 (Build mode — voice wraps around existing exercise logic)
- Blocked by: TTS voice selection (requires spike/evaluation)
- Enables: Nothing directly — this is an enhancement layer on E3/E4

## Technical Considerations
- Apple Speech Framework: SFSpeechRecognizer for on-device STT, supports DE and EN
- ElevenLabs API: streaming TTS with custom voice, requires network; fallback to Apple TTS offline
- Audio session category: `.playAndRecord` with `.defaultToSpeaker` for iPhone, `.playback` for TTS-only on iPad/Mac
- Bluetooth routing: AVAudioSession route management for AirPods and external speakers
- Interruption handling: observe `.audioSessionInterruption` notification, pause/resume gracefully
- Latency pipeline: user stops speaking → STT finalises → send to Claude API → receive response → begin TTS. Target: < 3s total from user finishing to Barbara starting to speak.
- Streaming TTS: begin speaking as soon as first sentence is available (don't wait for full response)

## Open Questions
- [ ] ElevenLabs vs. Apple TTS: run a spike with both, compare quality and Barbara-character-fit
- [ ] Should Barbara's voice have subtle emotional variation (warmer when praising, crisper when correcting)?
- [ ] How to handle STT errors? Show transcript and let user correct before submitting? Or submit as-is and let Barbara work with imperfect input?
- [ ] Should there be a "voice training" onboarding where Barbara calibrates to the user's speech patterns?
- [ ] Cost model for ElevenLabs if used: per-character pricing, expected monthly cost per active user?
- [ ] Offline mode: Apple TTS works offline, but Claude API doesn't. What's the offline story for voice?

## Story Candidates
1. TTS spike: evaluate ElevenLabs vs. Apple TTS for Barbara's voice in both languages
2. Apple Speech Framework integration: SFSpeechRecognizer setup, permissions, language config
3. TTS playback engine: queue Barbara's responses, handle streaming, playback controls
4. STT capture flow: microphone permission, real-time transcription display, "done" detection
5. Voice-first "Say it clearly" session adaptation: rewire Build mode for spoken input/output
6. Voice "Elevator pitch" adaptation: timer + spoken input + evaluation
7. Voice "Find the point" adaptation: display text, capture spoken extraction
8. Audio session management: categories, routing, interruption handling
9. AirPods / Bluetooth audio routing
10. Voice/text toggle: allow switching mid-session
11. Barbara voice characterisation: select/tune voice parameters for both languages
12. Latency optimisation: streaming TTS, pipeline timing, perceived responsiveness

## References
- Primer parallel: The Primer speaks. The most memorable aspect of Stephenson's
  vision — a book that has a voice, a personality, and listens back.
- Oral examination tradition: The oldest form of academic assessment is verbal.
  Barbara brings it back, modernised.
