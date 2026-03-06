# E12: Parent Dashboard

## Vision
Parents can see that it's working. A dedicated view shows the child's
progression through Barbara's levels, their consistency, their strengths,
and where they're developing. Parents see enough to understand the value
without invading the learner's intellectual privacy — they can see *how
well* their child structures arguments, but not *what opinions* they hold.
This is the bridge between "my kid uses an app" and "my kid is learning
a real skill."

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Parent view** (accessible via PIN or biometric authentication):
  - Current level and progression pace (timeline of level transitions)
  - Session frequency and duration (daily/weekly/monthly charts)
  - Streak history and current streak
  - Skill area breakdown: strengths and development areas
    (e.g. "Strong: leading with conclusions. Developing: MECE grouping.")
  - Recent session summaries: Barbara's structural assessment per session
    (scores and feedback themes, not the user's actual text)
  - Mode usage distribution (Build vs. Break vs. Daily Drill)
- **Privacy boundary** — parents can see:
  - Structural scores and skill dimensions
  - Session completion and engagement metrics
  - Barbara's feedback themes ("grouping needs work", "leads with conclusions consistently")
  - Exercise types completed
- **Privacy boundary** — parents CANNOT see:
  - The actual content of the user's responses (opinions, arguments, positions)
  - The specific text of Barbara's in-session feedback
  - Individual exercise prompts or topics chosen by the user
- **Parent settings**:
  - Set notification preferences for parent (weekly summary push notification)
  - View/modify daily drill time
  - Enable/disable app (parental time control)
- **Weekly summary notification**:
  - Push notification to parent device: "This week: 5 sessions, streak at 12 days,
    MECE grouping improving. Governing thought placement is consistently strong."

### Out of Scope
- Multi-child support (one learner profile per device in V1)
- Parent-teacher communication or export for schools
- Parent ability to set curriculum or override Barbara's assessment
- Cross-device sync of parent view (local only in V1)
- Detailed session replay or transcript access

### Success Criteria
- [ ] Parent can access dashboard without seeing the learner's actual opinions or arguments
- [ ] Progression data accurately reflects the learner's demonstrated ability
- [ ] Weekly summary notification provides useful, actionable information
- [ ] Dashboard renders meaningful data after just 5 sessions
- [ ] PIN/biometric gate prevents the learner from feeling surveilled
- [ ] Parent settings changes don't disrupt the learner's experience
- [ ] Privacy boundary holds: no pathway from parent view to learner content

## Design Decisions
- **Privacy by architecture**: The parent view queries aggregated scores and metadata, never raw session content. The privacy boundary is not just a UI choice — it's a data access constraint.
- **PIN gate, not separate app**: Parent dashboard lives within the same app, behind authentication. Simpler than a companion app, sufficient for V1.
- **Barbara's voice in parent view**: The weekly summary and skill descriptions use Barbara's language. "Your daughter leads with her point now — she didn't do that three weeks ago." This reinforces that Barbara is the expert.
- **No curriculum override**: Parents trust Barbara. They can see progress but can't skip levels or change difficulty. This matches the portfolio's philosophy in Professor Albert.

## Dependencies
- Depends on: E3 (learner profile, session history, progression model)
- Blocked by: nothing beyond E3
- Enables: parent confidence in the app's value; supports future monetisation conversations

## Technical Considerations
- Aggregate query layer: compute weekly scores, trend lines, skill breakdowns from session history JSON
- PIN storage: Keychain, not UserDefaults
- Biometric auth: LocalAuthentication framework (Face ID / Touch ID)
- Push notification for weekly summary: local notification, scheduled weekly
- Data visualisation: SwiftUI Charts for progression timeline and skill radar
- Privacy enforcement: parent view model only accesses aggregated data types, never raw session content

## Open Questions
- [ ] Should parent dashboard be accessible on all platforms, or iPad/Mac only?
- [ ] How to handle the case where the learner sets up the app without telling parents? (No forced parent setup)
- [ ] Should parents be able to see which topics Barbara chose? (Probably not — it reveals opinions indirectly)
- [ ] Is a weekly summary notification enough, or do parents want real-time alerts?
- [ ] Should the parent view show comparison to anonymised cohort averages? ("Your child is progressing faster than 70% of users at this level")

## Story Candidates
1. Parent authentication: PIN setup + biometric unlock
2. Parent dashboard layout: level, streak, skill areas, session frequency
3. Progression timeline chart: level transitions over time
4. Skill area breakdown: radar chart or bar chart of structural dimensions
5. Session summary aggregation: compute weekly/monthly metrics from session history
6. Privacy boundary enforcement: data access layer restricting parent queries
7. Weekly summary notification: scheduled local notification with Barbara's voice
8. Parent settings: notification preferences, daily drill time, app enable/disable
9. Barbara-voiced parent copy: skill descriptions and summaries in character
10. SwiftUI Charts integration for data visualisation

## References
- Primer parallel: In Diamond Age, the Primer's effects are visible to those
  around Nell — they can see she's becoming more capable, more articulate,
  more structured in her thinking. The parent dashboard surfaces this.
- Professor Albert E6: Same pattern, adapted for structural thinking metrics
  instead of math mastery.
