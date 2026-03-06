# E9: Daily Drills & Engagement

## Vision
Barbara becomes a daily habit. A push notification at the time you choose:
"Good morning. Before you start your day — what's the most important thing
you need to communicate today? Structure it for me." A 2-minute voice drill
on the train. A streak counter that Barbara herself acknowledges: "Four
weeks straight. You're getting disciplined." The app moves from something
you open when you remember to something that pulls you back every day.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Daily drill format**:
  - One short exercise per day (2–5 minutes)
  - Barbara selects the exercise type and topic based on learner profile
  - Targets weaknesses or reinforces recent gains
  - Quick-fire format: no long texts to read, no multi-step restructuring
  - Optimised for voice on iPhone (typed fallback always available)
- **Push notifications**:
  - User-configurable time ("When should Barbara check in?")
  - Barbara-voiced notification text (in character, not generic)
  - Rotating prompts: "Time for your daily drill." / "I have a question
    for you." / "Let's keep that streak going."
  - Respectful: max 1 per day, easy to disable, no guilt mechanics
- **Streak tracking**:
  - Consecutive days with at least one completed exercise
  - Barbara acknowledges milestones in-session (7 days, 30 days, 100 days)
  - Streak recovery: miss one day, Barbara notes it without punishment.
    Miss three, streak resets. "You were gone. Let's pick up where we left off."
  - Streak visible on progress dashboard (from E3)
- **Barbara's daily question**:
  - A curated set of "question of the day" prompts that rotate
  - Contextually aware: avoids topics the user did yesterday
  - Seasonal/topical hooks: "School starts again next week. What's one
    thing you want to change about how you study? Structure your answer."
- **Quick-start widget** (iOS):
  - Home screen widget showing streak count and "Start daily drill" button
  - Lock screen widget (iOS 16+) with Barbara's daily question preview
- **Session reminders for incomplete exercises**:
  - If user starts an exercise but doesn't finish, gentle reminder after 2 hours
  - "You left mid-thought. Want to finish what you started?"

### Out of Scope
- Gamification beyond streaks (no points, badges, or leaderboards — that's E13 for Duel Mode)
- Social sharing of streaks
- Apple Watch companion app
- Spaced repetition scheduling (streaks are about habit, not SRS)

### Success Criteria
- [ ] Daily drill completes in under 5 minutes
- [ ] Push notifications arrive at user-configured time
- [ ] Notification text feels like Barbara, not like a generic app
- [ ] Streak counter accurately tracks consecutive days
- [ ] Barbara's streak acknowledgements feel earned, not patronising
- [ ] Home screen widget displays correctly and launches to daily drill
- [ ] Users who enable daily drills show 2x+ session frequency vs. those who don't
- [ ] Daily drill topic selection avoids recent repeats and targets profile weaknesses

## Design Decisions
- **Barbara controls the drill**: The user doesn't pick the daily exercise — Barbara does, based on the profile. This reinforces her authority and ensures targeted practice.
- **No punishment mechanics**: Missing a day is not shameful. Barbara is strict about quality, not attendance. Streaks are motivating but their loss is not devastating.
- **Voice-optimised**: The daily drill is the primary use case for voice interaction (E5). On iPhone, the ideal flow is: notification → open → Barbara speaks → user speaks → feedback → done. Under 3 minutes, no typing.
- **Notification copy is hand-crafted**: Not AI-generated per-notification. A curated bank of 50+ Barbara-voice notification strings, rotated.

## Dependencies
- Depends on: E3 (Build mode, learner profile — drill selection needs profile data)
- Blocked by: nothing beyond E3
- Enables: Higher retention and faster progression across all modes
- Enhanced by: E5 (voice makes daily drills frictionless on iPhone)

## Technical Considerations
- UNUserNotificationCenter: local notifications at user-configured time
- Notification scheduling: recalculate daily (in case user changes time or language)
- Notification text bank: 50+ strings in DE and EN, categorised by streak state
- Drill selection algorithm: weighted random from exercise types, biased toward profile weaknesses, excluding recent topics
- WidgetKit: small and medium widget displaying streak + daily question
- Lock screen widget: minimal display, deep link to daily drill
- Streak persistence: stored in learner profile, resilient to timezone changes

## Open Questions
- [ ] Should daily drills count toward level progression, or are they "maintenance" exercises?
- [ ] How to handle timezone changes (travel)? Grace period?
- [ ] Should the widget show Barbara's avatar or just text + streak count?
- [ ] Can Barbara's daily question be shared externally ("Share this question with a friend")?
- [ ] Should there be a "weekend mode" with different timing or intensity?

## Story Candidates
1. Daily drill exercise format: short, focused, profile-aware exercise selection
2. Drill selection algorithm: weighted random, weakness-targeting, dedup
3. Push notification system: scheduling, permission flow, Barbara-voice text bank
4. Notification text bank: 50+ strings in DE and EN
5. Streak tracking logic: consecutive days, milestones, grace period, reset
6. Barbara streak acknowledgement dialogues (7d, 30d, 60d, 100d)
7. Daily question bank: 100+ rotating prompts in DE and EN
8. Home screen widget (WidgetKit): streak display + quick-start
9. Lock screen widget: daily question preview
10. Incomplete session reminder: 2-hour follow-up notification
11. Settings UI: notification time picker, enable/disable, weekend mode toggle

## References
- Primer parallel: The Primer is always available, always ready, always
  relevant. It doesn't wait to be opened — it calls to the reader.
- Duolingo's streak model: Proven engagement mechanic, adapted here with
  Barbara's personality replacing Duo's guilt-tripping owl.
