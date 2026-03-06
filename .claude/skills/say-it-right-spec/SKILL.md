---
name: say-it-right-spec
description: "Full project specification for Say it right! / Sag's richtig!. Load when starting a new story, making architecture decisions, or needing context on the overall design, Barbara's personality, structural pedagogy, or platform adaptation."
---

# Say it right! / Sag's richtig! — Project Specification

Read the full spec and relevant epic before making design decisions or starting a new story:

```
docs/product-spec.md       # Overall product spec, pedagogy, modes, sessions
docs/epics/E1.md           # Barbara's Brain (system prompt + evaluation rubrics)
docs/epics/E2.md           # iOS Shell & Chat Interface
docs/epics/E3.md           # Build Mode — Structural Coaching
docs/epics/E4.md           # Break Mode — Text Analysis & Pyramid Extraction
docs/epics/E5.md           # Voice Interaction (TTS + STT)
docs/epics/E6.md           # Visual Pyramid Builder (iPad/Mac)
```

Also available:
```
prompts/barbara-system-prompt.md    # Barbara's master system prompt
content/evaluation-rubrics/         # Structural quality criteria per level
content/practice-texts/             # Pre-generated texts with answer keys
```

## When to Read the Spec
- Starting a new story (`/project:start-story`)
- Making a design choice not covered by CLAUDE.md
- Working on the intelligence layer (system prompt, evaluation, response parsing)
- Working on Barbara's personality or feedback style
- Working on level adaptation (Klartext -> Ordnung -> Architektur -> Meisterschaft)
- Working on platform adaptation (voice-first iPhone, visual iPad, keyboard Mac)
- Unsure how Build vs Break mode should interact
