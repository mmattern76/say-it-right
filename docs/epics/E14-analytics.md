# E14: Analytics & Learning Insights

## Vision
After months of practice, the user opens a view that shows them their
entire journey. A timeline of how their structural scores evolved. A
heatmap of which skill dimensions improved fastest. A "then vs. now"
comparison where Barbara resurfaces an early response and places it next
to a recent one on the same topic: "Look at how you used to write. And
look at you now." The data doesn't just track progress — it makes growth
*visible* and *undeniable*.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Growth timeline**:
  - Visualisation of structural scores over time (weekly averages)
  - Level transition markers on the timeline
  - Annotations for significant moments (first clean pyramid, first L2 exercise, etc.)
- **Skill dimension heatmap**:
  - Grid of skill dimensions (governing thought, grouping, MECE, evidence alignment,
    redundancy avoidance, etc.) × time periods
  - Colour-coded: green (strong), yellow (developing), red (needs work)
  - Shows which skills improved fastest and which plateau
- **Then vs. Now**:
  - Barbara selects an early response and a recent response on a similar topic
  - Side-by-side display with structural annotations
  - Barbara provides commentary: "Three months ago you gave me four rambling
    paragraphs. Today you gave me a clean three-point pyramid in half the words.
    That's what structured thinking looks like."
- **Session analytics**:
  - Total sessions, total time, exercises completed
  - Revision success rate (% of sessions where revision scored higher than first attempt)
  - Average response time trends
  - Mode distribution (Build / Break / Drill / Duel)
- **Exportable progress report**:
  - PDF or shareable summary of the learner's journey
  - Suitable for portfolio, university application, or parent sharing
  - Includes: level achieved, key metrics, skill profile, Barbara's assessment
- **Barbara's periodic reviews**:
  - At milestones (every 30 sessions, every level transition), Barbara initiates
    a review conversation: "Let's look at where you are."
  - She highlights growth, names remaining challenges, sets expectations for next phase

### Out of Scope
- Cohort analytics (comparison to other users — privacy concern)
- School or institution reporting
- Real-time analytics dashboards (insights are computed on-demand or periodically)
- Predictive analytics ("you'll reach L3 in 2 weeks")
- Integration with external learning management systems

### Success Criteria
- [ ] Growth timeline shows meaningful progression over 30+ sessions
- [ ] Skill heatmap correctly reflects performance trends per dimension
- [ ] "Then vs. Now" selects genuinely comparable responses (similar topic/type)
- [ ] "Then vs. Now" makes growth visually and emotionally obvious
- [ ] Exportable report looks professional and communicates value
- [ ] Barbara's periodic reviews feel insightful, not generic
- [ ] Analytics compute within 2 seconds even with 200+ sessions of history

## Design Decisions
- **Emotion over data**: The analytics view should make the user *feel* their growth, not just see numbers. "Then vs. Now" is the centrepiece because it's the most emotionally impactful.
- **Barbara narrates the data**: Charts alone are cold. Barbara's commentary transforms data into story. "Your MECE scores were flat for two weeks, then something clicked. See this jump? That's when grouping became instinctive."
- **On-demand computation**: Analytics are computed when the user opens the insights view, not continuously. This keeps the app lightweight.
- **Export as celebration**: The exportable report is framed as an achievement document, not a grade sheet. It's something you'd want to show someone.

## Dependencies
- Depends on: E3 (session history and structural scores — the raw data source)
- Blocked by: sufficient usage data (analytics are meaningless without 20+ sessions)
- Enables: parent confidence (E12), monetisation conversations, university application value
- Enhanced by: E7 (L3/L4 data adds depth), E13 (duel results add social dimension)

## Technical Considerations
- Score aggregation: compute weekly averages, dimension-level trends from session history JSON
- Comparable response selection for "Then vs. Now": match by topic domain, exercise type, and difficulty level; select earliest and most recent with highest score differential
- Chart rendering: SwiftUI Charts for timeline and heatmap
- PDF generation: use the docx/PDF skill pattern for exportable reports
- Performance: analytics computation on 200+ sessions must complete in < 2 seconds
- Storage: no additional storage — analytics derive from existing session history
- Barbara's review prompts: specialised system prompt variant that receives aggregate stats and produces narrative review

## Open Questions
- [ ] How many sessions before analytics become meaningful? (Show a "keep practicing" message before threshold)
- [ ] Should "Then vs. Now" always pick the worst early response, or a representative one?
- [ ] Should the export include sample responses? (Privacy consideration — the user controls this)
- [ ] What format for export? PDF? Image? Shareable link?
- [ ] Should analytics differentiate between Build and Break performance, or unify them?
- [ ] How to handle users who reset their profile? Archive old analytics or start fresh?

## Story Candidates
1. Growth timeline: weekly score averages, level markers, annotations
2. Skill dimension heatmap: dimensions × time, colour-coded
3. "Then vs. Now" comparison engine: select comparable responses, display side-by-side
4. "Then vs. Now" Barbara commentary: specialised prompt producing narrative comparison
5. Session analytics summary: totals, revision rate, time trends, mode distribution
6. SwiftUI Charts integration: timeline chart, heatmap visualisation
7. Exportable progress report: PDF generation with learner journey summary
8. Barbara's periodic review: milestone-triggered review conversation
9. Analytics computation engine: aggregate scores from session history
10. Insights view layout: platform-adaptive (scrollable on iPhone, dashboard on iPad/Mac)
11. "Keep practicing" state: minimum session threshold before analytics unlock
12. Export sharing: share sheet integration, format options

## References
- Primer parallel: The Primer remembers everything. At the end of Nell's
  journey, the full arc of her growth is visible — from uncertain child to
  capable young woman. Analytics makes Say it right!'s version of this
  arc visible to the learner.
- Quantified self movement: Making invisible progress visible is one of
  the most powerful motivators for sustained learning.
