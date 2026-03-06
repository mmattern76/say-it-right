# System Prompt Assembly Template

Assemble the system prompt by replacing each placeholder with the corresponding block content. Order matters — blocks build on each other.

## Assembly Order

```
{{IDENTITY}}

{{PEDAGOGY}}

{{RUBRIC}}

{{SESSION_TEMPLATE}}

{{SESSION_DIRECTIVE}}

# Learner Profile

{{PROFILE}}

{{OUTPUT_FORMAT}}
```

## Placeholder Sources

| Placeholder | Source File | Notes |
|---|---|---|
| `{{IDENTITY}}` | `prompts/blocks/identity-{lang}.md` | Barbara's personality. Always first. |
| `{{PEDAGOGY}}` | `prompts/blocks/pedagogy-{lang}.md` | Evaluation loop, revision limits, praise rules. |
| `{{RUBRIC}}` | `prompts/blocks/rubric-l{N}-{lang}.md` | L1 or L2 rubric based on learner's `currentLevel`. |
| `{{SESSION_TEMPLATE}}` | `prompts/sessions/{session-type}-{lang}.md` | Session-specific flow (say-it-clearly, find-the-point, etc.). |
| `{{SESSION_DIRECTIVE}}` | `prompts/blocks/session-directive-{lang}.md` | Adaptive coaching rules based on profile data. |
| `{{PROFILE}}` | Runtime JSON | Learner profile JSON injected at runtime. See `schemas/learner-profile.schema.json`. |
| `{{OUTPUT_FORMAT}}` | `prompts/blocks/output-format-{lang}.md` | Hidden metadata format. Always last — it defines the output contract. |

## Dynamic Data Injection

The `{{PROFILE}}` placeholder is replaced with a JSON block:

```
# Learner Profile

```json
{
  "displayName": "Maxi",
  "currentLevel": 1,
  "strengths": [],
  "developmentAreas": ["governing_thought"],
  "sessionsCompleted": 0,
  "streakDays": 0,
  "recentScores": [],
  "notes": ""
}
`` `
```

## Session-Specific Data

For "Find the point" sessions, append the practice text after the session template:

```
# Practice Text

{practiceTextJson}
```

The practice text JSON includes the `answerKey` — Barbara uses it for evaluation but never reveals it to the learner.

## Token Budget

Target: **under 4,000 tokens** total assembled prompt. This leaves ~196K tokens for conversation context.

Approximate block sizes:
- Identity: ~500 tokens
- Pedagogy: ~450 tokens
- Rubric (L1): ~500 tokens / Rubric (L2): ~600 tokens
- Session template: ~400-500 tokens
- Session directive: ~450 tokens
- Profile: ~100 tokens
- Output format: ~700 tokens
- **Total: ~3,100–3,300 tokens**
