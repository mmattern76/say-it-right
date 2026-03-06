# E10: LLM Prompt Workshop

## Vision
The meta-skill becomes explicit. The user writes a prompt, sends it to a
real LLM, and sees what comes back. Then Barbara dissects the prompt's
structure: "You asked three questions disguised as one. The AI guessed
which one you meant — and guessed wrong. Separate them. Lead with context.
Specify your format. Try again." The user revises, resends, and sees the
difference a well-structured prompt makes. This is where Say it right!
becomes genuinely unique in the market — no other app teaches prompt
engineering as a downstream application of classical structured thinking.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Prompt Workshop session type**:
  - Barbara presents a scenario: "You need to ask an AI to help you
    write a cover letter. Draft your prompt."
  - User writes a prompt
  - Prompt is sent to a real Claude API call (separate from Barbara's evaluation)
  - The AI's response is displayed alongside the user's prompt
  - Barbara evaluates the *prompt's structure*, not the AI's response
  - "See how the AI rambled? That's because your prompt rambled. Fix the prompt."
  - User revises and resends; Barbara compares the two AI responses
- **Prompt evaluation rubric** (structural, not content):
  - Is the context/situation clear?
  - Is the task/question specific and unambiguous?
  - Are constraints and format specified?
  - Is there a single clear ask, or are multiple requests tangled?
  - Would a human understand this request on first read?
- **Scenario bank**: 20+ prompt-writing scenarios in DE and EN:
  - Academic: "Ask an AI to explain a concept", "Get help structuring an essay"
  - Professional: "Draft a meeting summary request", "Ask for feedback on a plan"
  - Creative: "Request a story with specific constraints", "Ask for brainstorming help"
  - Meta: "Ask an AI to critique your own writing"
- **Before/after comparison**: Side-by-side display of the original prompt + response
  vs. the revised prompt + response, highlighting how structural improvement
  in the prompt leads to better AI output
- **Barbara's bridge to pyramid thinking**: Explicit connection between prompt
  structure and the Pyramid Principle. "Your prompt should lead with what
  you need — that's your governing thought. Then give context — those are
  your supports. Then specify constraints — that's your evidence layer."

### Out of Scope
- Teaching specific API features or technical prompt engineering (system prompts, temperature, etc.)
- Comparing different LLM providers
- Prompt templates or copy-paste libraries (this is about learning, not shortcuts)
- Image generation prompts (text-only for V1)
- Cost tracking for API calls (managed within the app's existing API budget)

### Success Criteria
- [ ] User writes a prompt, sees a real AI response, and understands how structure affected the output
- [ ] Barbara's feedback on prompts uses pyramid terminology consistently
- [ ] The before/after comparison is visually clear and convincing
- [ ] Users report that the workshop improved their real-world prompt writing
- [ ] Prompt evaluation rubric produces actionable feedback, not vague advice
- [ ] Scenario bank covers enough variety for 2+ weeks of daily use
- [ ] API calls for prompt testing are handled within acceptable latency and cost

## Design Decisions
- **Real API calls, not simulated**: The user must see the actual consequence of a badly structured prompt. Simulated responses would feel fake and undermine the lesson.
- **Separate Claude call**: The prompt is sent to a fresh Claude context (not Barbara's conversation). Barbara evaluates the prompt structure; the separate Claude call evaluates its effectiveness.
- **Structure over content**: Barbara doesn't teach "prompt hacks" — she teaches the same pyramid thinking applied to human→AI communication. The lesson is that clear structure works for any audience, human or machine.
- **Level 4 prerequisite**: The Prompt Workshop only unlocks at Level 4. Users must demonstrate structural mastery in human communication before applying it to AI communication.

## Dependencies
- Depends on: E7 (Level 4 rubric and content), E3 (Build mode infrastructure)
- Blocked by: E7 must define the L4 prompt evaluation rubric
- Enables: nothing directly — this is the capstone feature of the app

## Technical Considerations
- Dual API calls per exercise turn: one to Barbara (evaluation), one to a fresh Claude context (prompt testing). Budget ~2x normal API cost per session.
- Fresh Claude context: no system prompt contamination. The user's prompt is sent exactly as written, with only a minimal wrapper.
- Response display: the AI's response must be visually distinct from Barbara's feedback (different panel, different styling)
- Before/after comparison view: two-column layout on iPad/Mac, swipeable on iPhone
- Prompt length limits: cap at ~500 words to prevent abuse and manage costs
- Rate limiting: max 3 prompt-test iterations per session to control API costs

## Open Questions
- [ ] Should the "target" LLM for prompt testing always be Claude, or should it be configurable?
- [ ] How to handle prompts that produce inappropriate AI responses? (Content filter on the response?)
- [ ] Should Barbara ever model a "gold standard" prompt for comparison? Or only critique the user's?
- [ ] Is 3 iterations per session enough? Should power users get more?
- [ ] Should prompt workshop exercises contribute to level progression, or are they standalone practice?
- [ ] How to message the dual API cost to users if the app moves to a subscription model?

## Story Candidates
1. Prompt Workshop session flow: scenario → write prompt → send → show response → Barbara evaluates
2. Fresh Claude API integration: separate context, minimal wrapper, response display
3. Prompt evaluation rubric: structural criteria for prompt quality
4. Scenario bank: 20+ prompt-writing scenarios in DE and EN
5. Before/after comparison view: side-by-side prompts and responses
6. Barbara's pyramid-to-prompt bridge dialogues
7. Prompt revision flow: revise → resend → compare responses → Barbara's debrief
8. Rate limiting: max iterations per session, cost management
9. Response content filtering: safety check on AI responses to user prompts
10. iPhone layout: swipeable before/after comparison
11. iPad/Mac layout: two-column prompt + response comparison

## References
- Primer parallel: The Primer teaches the reader to communicate with other
  computational systems — not just with humans. The reader who masters the
  Primer can navigate any interface.
- "Prompt engineering is just clear communication": The thesis of this epic
  and arguably the thesis of the entire app.
