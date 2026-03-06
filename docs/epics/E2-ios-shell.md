# E2: iOS Shell & Chat Interface

## Vision
The user opens a real app on their iPhone, iPad, or Mac. Barbara greets
them with her illustrated avatar and asks a direct question. The interface
is clean, purpose-built, and platform-adaptive — a chat view on iPhone,
more spatial on iPad and Mac. It feels like talking to a sharp teacher,
not a generic chatbot.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- SwiftUI universal app (iOS, iPadOS, macOS) with platform-adaptive layouts
- Chat interface with message bubbles (user + Barbara)
- Barbara avatar display (4–6 static expression variants: neutral, raised
  eyebrow, slight nod, crossed arms, warm smile, thinking)
- Anthropic API integration with streaming responses
- System prompt assembly engine (composing modular blocks per request)
- Response parsing: split visible chat from hidden metadata
- Session management (start new, continue, end session)
- Language selection (German / English) in settings
- API key storage in iOS Keychain
- Network error handling and graceful degradation

### Out of Scope
- Build mode exercise logic (that's E3)
- Break mode exercise logic (that's E4)
- Voice interaction / TTS / STT (that's E5)
- Visual pyramid builder (that's E6)
- Persistent learner profile and progression tracking (that's E3)
- Progress dashboard (that's E3)

### Success Criteria
- [ ] User can complete a full coaching session in the native app
- [ ] Quality matches or exceeds the Claude Project experience from E1
- [ ] Streaming responses feel conversational (< 1s to first token)
- [ ] Barbara's avatar shows appropriate expressions tied to feedback tone
- [ ] App runs natively on iPhone, iPad, and Mac with appropriate layouts
- [ ] Language switch between German and English works without restart
- [ ] App handles network errors gracefully (no crashes, helpful message)
- [ ] API key is stored securely and never exposed in logs or UI

## Design Decisions
- **Direct API, no backend**: HTTPS to api.anthropic.com from the app
- **Streaming**: Use SSE streaming for perceived responsiveness
- **Universal app**: Single codebase, `#if os()` and size classes for platform adaptation
- **Avatar as static images**: Pre-rendered expression variants, switched by mood tag in metadata
- **iPhone layout**: Full-screen chat, compact. iPad: wider bubbles, potential sidebar. Mac: desktop window with comfortable reading width.

## Dependencies
- Depends on: E1 (system prompt and rubrics must be validated first)
- Blocked by: Barbara character illustrations (parallel design work)
- Enables: E3 (Build Mode), E4 (Break Mode), E5 (Voice), E6 (Pyramid Builder)

## Technical Considerations
- API key: stored in Keychain, never in UserDefaults or source
- Streaming: Anthropic's SSE format, parsed incrementally
- Hidden metadata parsing: regex for `<!-- BARBARA_META: {...} -->` block
- Context window management: keep last N messages, summarise older ones
- Platform detection: use SwiftUI environment values and size classes
- macOS: ensure proper window management, menu bar integration
- Dark mode: support from day one (Barbara's UI should work in both)

## Open Questions
- [ ] Should Barbara's chat bubbles have a distinct visual style (e.g. a teacher's handwriting font, or structured/clean to match her personality)?
- [ ] Dark mode styling — should Barbara's colour palette shift, or stay constant?
- [ ] How to handle very long Barbara responses on iPhone (collapsible sections?)
- [ ] Should the settings screen include a "Meet Barbara" onboarding flow?

## Story Candidates
1. Xcode project scaffolding (4-layer architecture, folder structure, universal app target)
2. AnthropicService: API client with streaming SSE support
3. SystemPromptAssembler: compose modular blocks into final prompt
4. ResponseParser: split visible text from hidden metadata JSON
5. Chat UI: message list, bubbles, scroll behaviour, platform-adaptive layout
6. Barbara avatar component (mood → expression mapping)
7. Language settings (German/English toggle, persisted locally)
8. Session management (start/continue/end, conversation history in memory)
9. Keychain wrapper for API key storage
10. Network error handling and retry logic
11. iPad layout adaptation (wider content area, potential sidebar)
12. macOS layout adaptation (window sizing, menu bar, keyboard shortcuts)
13. TestFlight build and distribution

## References
- Primer parallel: The physical book — purpose-built, inviting, and adaptive
  to the reader's context (phone in pocket vs. desk at home).
