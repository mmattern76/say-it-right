# E8: Onboarding & Diagnostic Placement

## Vision
Barbara doesn't waste your time on basics you've already mastered, and
she doesn't throw you into the deep end unprepared. The first time you
open the app, Barbara runs a short, conversational diagnostic — not a
test, but a conversation that reveals where you are. Within 5 minutes,
she knows whether you need Level 1 foundations or can skip straight to
Level 2 grouping. The onboarding also introduces Barbara's character,
sets expectations, and makes the user want to come back.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **First-launch experience**:
  - Language selection (German / English)
  - Brief character introduction: who Barbara is and what the app does
  - Tone-setting: Barbara's first words establish her personality
    ("I'm Barbara. I'm going to teach you to think clearly. It won't
    always be comfortable, but you'll thank me later.")
- **Diagnostic conversation** (3–5 minutes):
  - Barbara asks 3–4 questions of increasing structural complexity
  - User responds (typed or spoken if E5 is available)
  - Barbara evaluates structure silently (no feedback during diagnostic)
  - Based on responses, places user at Level 1 or Level 2
  - If responses show L3+ capability, flags for accelerated path
- **Diagnostic rubric**: lightweight version of the full evaluation rubric,
  optimised for quick placement rather than detailed feedback
- **Results & welcome**:
  - Barbara explains the placement: "You already lead with your point —
    good. But your grouping needs work. We'll start with Ordnung."
  - Brief preview of what the user will learn at their level
  - First real exercise begins immediately (no dead time after onboarding)
- **Skip option**: Experienced users or returning users can skip the
  diagnostic and self-select their level (Barbara notes this and adjusts
  if their performance doesn't match)
- **Onboarding for voice mode** (if E5 shipped):
  - Microphone permission request with Barbara's explanation
  - Brief voice calibration ("Say something so I can hear you properly")

### Out of Scope
- Account creation or sign-in (no accounts in V1)
- Tutorial walkthrough of every session type (learn by doing)
- Animated onboarding sequences or video
- Re-diagnostic (if the user wants to reset, they start fresh via settings)

### Success Criteria
- [ ] New user completes onboarding in under 5 minutes
- [ ] Diagnostic correctly places users (validated against subsequent performance)
- [ ] Barbara's character comes through in the first 30 seconds
- [ ] Users who skip diagnostic and self-select are quietly re-calibrated within 3 sessions
- [ ] The transition from diagnostic to first real exercise feels seamless
- [ ] Language selection persists and Barbara switches cleanly
- [ ] Onboarding does not feel like a test — it feels like a conversation

## Design Decisions
- **Conversation, not quiz**: Barbara asks open-ended questions ("What do you think about school uniforms?"), not multiple-choice. The structure of the response IS the diagnostic.
- **Silent evaluation during diagnostic**: Barbara doesn't give feedback on the diagnostic responses. She's listening, not teaching. This prevents the diagnostic from becoming a lesson.
- **Conservative placement**: If uncertain, place the user at the lower level. Better to start easy and promote quickly than to frustrate with premature difficulty.
- **Immediate first exercise**: The onboarding ends with Barbara launching straight into a session. No "tutorial complete!" screen. Learning starts now.

## Dependencies
- Depends on: E2 (app shell), E3 (learner profile — the diagnostic writes the initial profile)
- Blocked by: nothing beyond E2 + E3
- Enables: Better user experience for all subsequent epics

## Technical Considerations
- Diagnostic prompt: a specialised system prompt variant that evaluates without giving feedback
- Placement algorithm: score structural dimensions from diagnostic responses, map to level thresholds
- Learner profile initialisation: diagnostic results seed the profile with initial strengths/weaknesses
- Skip flow: if user skips, create a default L1 profile with a "tentative" flag that triggers re-evaluation after 3 sessions
- Voice onboarding (E5): microphone permission must be requested before first voice exercise, with Barbara's in-character explanation

## Open Questions
- [ ] How many diagnostic questions? (3 feels fast, 5 feels thorough — which matters more for first impression?)
- [ ] Should the diagnostic questions be the same every time, or drawn from a pool?
- [ ] Should Barbara reveal the placement logic? ("I'm going to ask you a few questions to see where we should start") or keep it conversational?
- [ ] What if the diagnostic suggests L3+? Place at L3, or place at L2 with accelerated pacing?
- [ ] Should returning users (e.g. reinstall) be able to import a previous profile?

## Story Candidates
1. First-launch flow: language selection → Barbara introduction → diagnostic
2. Diagnostic system prompt: evaluate structure without giving feedback
3. Diagnostic question bank: 8–10 questions at varying complexity, draw 3–5 per session
4. Placement algorithm: map diagnostic scores to level placement
5. Learner profile initialisation from diagnostic results
6. Barbara's placement explanation dialogue
7. Skip-diagnostic flow: self-select level, tentative profile, re-evaluation trigger
8. Seamless transition from diagnostic to first real exercise
9. Voice onboarding (conditional on E5): mic permission, voice calibration
10. Onboarding analytics: track completion rate, time spent, placement distribution

## References
- Primer parallel: The Primer adapts to its reader from the very first
  interaction — it doesn't start with a generic tutorial.
- Adaptive testing: Computer-adaptive tests (like the GRE) select questions
  based on prior answers. The diagnostic uses the same principle informally.
