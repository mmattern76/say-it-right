# E11: Content Pipeline

## Vision
The app's practice text library stops being a static bundle and becomes a
living, growing corpus. A batch pipeline generates new texts at calibrated
difficulty levels, each with structured answer keys and quality metadata.
New content arrives on the app without requiring an App Store update. Users
who practice daily never run out of fresh material, and the content stays
relevant to current events and cultural context.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Text generation pipeline**:
  - Batch job that generates practice texts using Claude API
  - Inputs: difficulty level, quality type (well-structured / buried-lead /
    rambling / adversarial), language, topic domain, target length
  - Outputs: text body, structured answer key (pyramid JSON), difficulty
    metadata, quality rating, topic tags
  - Quality validation: automated checks for answer key consistency,
    readability score, length compliance
- **Content review workflow**:
  - Generated texts flagged for human review before publication
  - Review interface (lightweight — could be a simple web page or script)
  - Approve / reject / edit flow
  - Rejected texts logged with reason for pipeline improvement
- **Content delivery API**:
  - Lightweight endpoint serving new content to the app
  - App checks for new content on launch (or daily)
  - Incremental sync: download only texts the user doesn't have
  - Offline resilience: bundled library remains available; new content is additive
- **Topic bank refresh**:
  - New topics for "Say it clearly" / Build mode, generated alongside texts
  - Seasonal and topical hooks (back to school, elections, holidays)
  - Cultural appropriateness review for both DE and EN content
- **Content versioning**:
  - Each text has a version identifier
  - Answer keys can be updated without invalidating session history
  - Deprecated texts are removed from rotation but preserved in history

### Out of Scope
- Real-time content generation (all content is pre-generated and reviewed)
- User-generated content sharing (users don't contribute texts to the library)
- Content localisation beyond DE and EN
- Personalised content generation (content is generated for levels, not individuals)

### Success Criteria
- [ ] Pipeline generates 20+ new texts per batch with <10% rejection rate
- [ ] Generated answer keys are consistent with text content (validated by automated checks)
- [ ] Content delivery API serves new texts to the app within 24 hours of approval
- [ ] App syncs new content without noticeable delay or user disruption
- [ ] Offline mode works normally with bundled + previously synced content
- [ ] Content quality is indistinguishable from hand-crafted texts
- [ ] Pipeline runs on existing infrastructure (Railway or equivalent)

## Design Decisions
- **Batch, not real-time**: Quality control requires human review. Pre-generating in batches allows review before publication.
- **Additive, not replaceable**: New content supplements the bundled library. The app always has a baseline of content even without network access.
- **Lightweight delivery**: A simple JSON API, not a full CMS. Content is small (text + metadata), so a static file host or simple endpoint suffices.
- **Reuse MeTube pipeline pattern**: The batch job and Railway deployment pattern from MeTube's video curation pipeline applies here with minimal adaptation.

## Dependencies
- Depends on: E4 (practice text library format and answer key schema)
- Blocked by: nothing beyond E4's schema definition
- Enables: Sustained engagement beyond the initial content bundle
- Enhanced by: E7 (L3/L4 content requires more sophisticated text generation)

## Technical Considerations
- Batch generation: Node.js or Python script calling Claude API with structured prompts
- Answer key schema: must match E4's pyramid JSON format exactly
- Quality validation: automated checks for JSON schema compliance, text length, readability metrics
- Content delivery: static JSON files on Railway (or S3/CloudFlare), versioned by batch
- App sync: background fetch on iOS, check for new content manifest on launch
- Storage: new texts stored in app's documents directory, indexed alongside bundled content
- Rate limiting: batch generation respects Anthropic API rate limits
- Cost: estimate per-batch generation cost and build into operational budget

## Open Questions
- [ ] How often should new batches be generated? Weekly? Biweekly?
- [ ] How many texts per batch? (20 covers a week of daily use with variety)
- [ ] Should the pipeline also generate new topics for Build mode, or just Break mode texts?
- [ ] Is Railway the right host for the content API, or is a static file host simpler?
- [ ] Should content delivery be push (notification of new content) or pull (check on launch)?
- [ ] How to handle content that becomes culturally insensitive over time? (Versioned deprecation?)

## Story Candidates
1. Text generation prompt engineering: structured prompts for each quality level and language
2. Batch generation script: input config → Claude API calls → output JSON files
3. Automated quality validation: schema check, readability, answer key consistency
4. Human review interface: simple approve/reject/edit flow
5. Content delivery API: endpoint serving content manifest + text files
6. App content sync: background fetch, incremental download, offline fallback
7. Content versioning: version identifiers, deprecation, answer key updates
8. Topic bank refresh pipeline: seasonal/topical topic generation
9. Railway deployment: batch job scheduling, API hosting
10. Monitoring: generation success rate, rejection rate, sync failure alerts

## References
- Primer parallel: The Primer's content is inexhaustible — it always has
  a new story, a new lesson, a new challenge. The reader never "finishes" it.
- MeTube pipeline: Proven batch generation and deployment pattern.
