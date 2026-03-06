# 👩‍🏫 Say it right! / Sag's richtig!

**Sag, was du meinst. Mein, was du sagst.** — An AI-powered app teaching structured thinking and clear communication.

## What Is This?

A universal iOS/iPadOS/macOS app that teaches teenagers and young adults the most transferable communication skill there is: structuring thought. Rooted in Barbara Minto's Pyramid Principle, the app trains two complementary abilities — formulating your own thoughts clearly (Build mode) and quickly absorbing others' reasoning (Break mode).

Barbara, the lead character, is a strict but good-natured teacher who evaluates the *architecture* of your thinking, not the content of your opinions.

## Architecture

- **iOS 17+ / iPadOS 17+ / macOS 14+**, Swift 6, SwiftUI
- **Anthropic API** direct (no backend server)
- **Local JSON** for learner profile and session history
- **4 layers**: Presentation → Intelligence → State → Content
- **Voice-first on iPhone** (TTS + STT), visual on iPad, keyboard on Mac

## Development Workflow

This project uses **Claude Code** with slash commands, named sessions,
and persistent cross-story memory. No external orchestration needed.

### Getting Started
```bash
# One-time setup (labels, milestones)
./scripts/setup-github.sh

# Start Claude Code in the repo
cd say-it-right
claude
/rename sir-setup

# Break E1 into stories
/project:refine-epic E1
```

### Daily Workflow
```bash
# Start a new story
claude
/rename sir-SIR-007
/project:start-story SIR-007       # or "next" for next in backlog

# ... work happens ...

# Wrap up
/project:complete-story             # tests, commits, PR, updates board

# Resume after a break
claude --continue                   # picks up where you left off
```

### Slash Commands

| Command | What it does |
|---------|-------------|
| `/project:start-story <id\|next>` | Load issue, create branch, begin implementing |
| `/project:complete-story` | Test, commit, push, create PR, update board |
| `/project:implement-story <id\|next>` | Fully autonomous start→implement→complete |
| `/project:refine-epic <E1..E6>` | Analyst: break epic into user stories |
| `/qa:review-pr <pr#>` | QA: review PR against acceptance criteria |
| `/barbara:test-session [level]` | Simulate coaching session, check structural feedback quality |

## Epics

| Epic | Title | Status |
|------|-------|--------|
| E1 | Barbara's Brain (system prompt + evaluation rubrics) | 🎯 Current |
| E2 | iOS Shell & Chat Interface | Planned |
| E3 | Build Mode — Structural Coaching | Planned |
| E4 | Break Mode — Text Analysis & Pyramid Extraction | Planned |
| E5 | Voice Interaction (TTS + STT) | Planned |
| E6 | Visual Pyramid Builder (iPad/Mac) | Planned |

**V1 Demonstrator = E1 + E2 + E3** (~3–5 weeks)

## Project Structure

```
say-it-right/
├── CLAUDE.md                           ← Claude Code reads this
├── README.md
├── .gitignore
├── .claude/
│   ├── commands/
│   │   ├── project/
│   │   │   ├── start-story.md          ← /project:start-story
│   │   │   ├── complete-story.md       ← /project:complete-story
│   │   │   ├── implement-story.md      ← /project:implement-story
│   │   │   └── refine-epic.md          ← /project:refine-epic
│   │   ├── qa/
│   │   │   └── review-pr.md            ← /qa:review-pr
│   │   └── barbara/
│   │       └── test-session.md         ← /barbara:test-session
│   ├── MEMORY.md                       ← cross-story context (auto-updated)
│   └── current-story.json              ← ephemeral session state
├── agents/
│   ├── shared/AGENTS.md                ← Project context (all personas)
│   ├── analyst/AGENTS.md               ← Story refinement persona
│   ├── qa/AGENTS.md                    ← Review & red-teaming persona
│   ├── scanner/AGENTS.md               ← Board scanning persona
│   └── builder/AGENTS.md               ← Implementation persona
├── docs/
│   ├── epics/                          ← E1–E6 + TEMPLATE.md
│   ├── product-spec.md                 ← Full product concept specification
│   └── adrs/                           ← Architecture decisions
├── prompts/
│   └── barbara-system-prompt.md        ← The master system prompt
├── content/
│   ├── practice-texts/                 ← Pre-generated texts with answer keys
│   └── evaluation-rubrics/             ← Structural quality criteria per level
├── scripts/
│   └── setup-github.sh                 ← One-time board setup
└── app/                                ← Xcode project (E2)
```
