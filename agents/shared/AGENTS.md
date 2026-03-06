# Shared Context — Say it right! / Sag's richtig!

All agent personas share this foundational context.

## Product
Universal app (iOS/iPadOS/macOS) teaching structured thinking via the Pyramid
Principle. Lead character Barbara evaluates the ARCHITECTURE of your thinking,
never the content of your opinions.

## Tech Stack
- iOS 17+, Swift 6, SwiftUI
- Anthropic API (Claude Sonnet 4.5) — direct, no backend
- Local JSON persistence, iCloud sync
- Apple Speech (STT), ElevenLabs or Apple TTS (Barbara's voice)

## Architecture (4 layers, dependencies flow down)
- Layer 4: Presentation (SwiftUI, platform-adaptive)
- Layer 3: Intelligence (system prompt, evaluation, parsing)
- Layer 2: State (learner profile, session history, settings)
- Layer 1: Content (exercises, practice texts, rubrics, progression)

## Core Rules
- Barbara evaluates STRUCTURE only — never content correctness
- Hidden metadata pattern: JSON postscript with scores, not shown to user
- System prompt is modular: Identity + Pedagogy + Rubric + Profile + Directive + Format
- Language-aware, not translated (German and English have different examples)
- Platform-adaptive: voice-first iPhone, visual iPad, keyboard Mac

## Story Conventions
- Prefix: SIR-NNN
- Branch: feat/<issue_number>-<slug>
- Commit: conventional (feat:, fix:, chore:, content:)
- PR closes the GitHub issue
