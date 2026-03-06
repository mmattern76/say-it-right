# E6: Visual Pyramid Builder (iPad/Mac)

## Vision
The abstract becomes tangible. On iPad, the user drags argument blocks
into a visual tree — grouping supports under a governing thought,
connecting evidence to claims, watching the pyramid take shape. When the
structure is MECE, the blocks glow. When there's a gap, a placeholder
pulses. When two blocks overlap, they flash red. The user *sees* structural
thinking, not just reads about it. This is Tetris for arguments.

## Status
- [x] Epic defined
- [ ] Stories broken down (by Analyst)
- [ ] Sprint assigned
- [ ] Implementation complete
- [ ] QA complete

## Scope

### In Scope
- **Visual pyramid component**:
  - Tree/hierarchy visualisation with draggable blocks
  - Blocks represent: governing thought, support points, evidence
  - Drag-and-drop to arrange blocks into a pyramid structure
  - Visual feedback: connection lines, grouping indicators
  - MECE validation: visual cues when groups are clean vs. overlapping/incomplete
- **"Build the pyramid" / "Bau die Pyramide" session type**:
  - Barbara provides a claim and a pile of unsorted supporting points
  - User arranges them into a proper pyramid via drag-and-drop
  - Barbara evaluates the arrangement against the answer key
  - Feedback is visual (highlighting correct/incorrect placements) + textual
- **"Fix this mess" visual upgrade**:
  - The E4 text restructuring exercise gets a visual variant on iPad/Mac
  - Present the broken argument as disarranged blocks
  - User drags them into correct order/grouping
- **iPad-optimised layout**:
  - Pyramid builder fills the main canvas area
  - Barbara's feedback in a side panel or overlay
  - Multi-touch gesture support (drag, pinch to zoom, two-finger pan)
- **Mac-optimised layout**:
  - Mouse/trackpad drag-and-drop
  - Keyboard shortcuts for common actions (group, ungroup, swap)
  - Wider canvas with Barbara in sidebar

### Out of Scope
- iPhone version of the pyramid builder (screen too small; iPhone stays voice/text)
- Free-form pyramid creation from scratch (user always works with provided blocks)
- Export/share pyramid visualisations (future consideration)
- Animation of Barbara interacting with the pyramid (blocks only, Barbara stays in her panel)
- Collaborative pyramid building (multiplayer, future consideration)

### Success Criteria
- [ ] Drag-and-drop feels fluid and satisfying on iPad (60fps, responsive)
- [ ] Blocks snap into logical positions in the tree hierarchy
- [ ] MECE validation provides immediate, clear visual feedback
- [ ] "Build the pyramid" exercise completes end-to-end: scrambled blocks → arranged → evaluated
- [ ] "Fix this mess" visual variant works on iPad alongside the text variant
- [ ] Mac drag-and-drop works with mouse/trackpad, keyboard shortcuts functional
- [ ] Users report that the visual exercise helps them understand pyramid structure better than text-only
- [ ] Pyramid builder handles various tree sizes (2-level simple to 3-level complex)

## Design Decisions
- **iPad/Mac only**: The pyramid builder requires screen real estate and precise input. iPhone gets the voice-first experience instead — each platform plays to its strengths.
- **Provided blocks, not freeform**: The user works with blocks Barbara gives them. This constrains the exercise to be evaluatable and prevents open-ended complexity.
- **SwiftUI Canvas + drag gestures**: Native SwiftUI for rendering and gesture handling. No web views or third-party charting libraries.
- **Visual feedback over numerical scoring**: The pyramid builder's feedback is primarily visual (colours, animations, connection lines) with Barbara's textual commentary as supplement.
- **Progressive complexity**: Level 1 exercises have 4–6 blocks (simple 2-level pyramid). Level 2 has 8–10 blocks (3-level). Level 3+ has 12+ blocks with deliberate red herrings that don't belong.

## Dependencies
- Depends on: E2 (app shell), E3 (learner profile — difficulty calibration), E4 (practice text library with answer keys — "Fix this mess" content)
- Blocked by: nothing beyond E2–E4
- Enables: nothing directly — this is the premium interaction mode for tablet/desktop

## Technical Considerations
- SwiftUI drag-and-drop: `onDrag` / `onDrop` modifiers, or custom `DragGesture` for more control
- Tree layout algorithm: position nodes in a balanced pyramid (root top-centre, children below, evenly spaced)
- Block sizing: dynamic based on text length, with minimum/maximum constraints
- MECE validation logic: compare user's grouping against answer key grouping; highlight overlaps (two blocks that cover the same concept) and gaps (missing group)
- Connection lines: drawn with SwiftUI `Path` or `Canvas`, animated on placement
- Answer key matching: flexible — the answer key defines valid groups, not exact positions. Multiple arrangements can be correct.
- Haptic feedback on iPad: `UIImpactFeedbackGenerator` for block placement, success, error
- Performance: target 60fps during drag operations with up to 15 blocks on screen

## Open Questions
- [ ] What visual metaphor for the blocks? Cards? Bricks? Tiles? Should they have colour-coding by type (claim vs. evidence vs. support)?
- [ ] How to represent MECE visually? Grouping outlines? Colour zones? Explicit "group" containers?
- [ ] Should blocks be freely positioned (magnetic snap) or constrained to grid positions in the tree?
- [ ] How to handle the "red herring" blocks at higher levels? (Drag to a discard zone? Barbara tells you "that doesn't belong"?)
- [ ] Should the pyramid animate as it builds (connections draw themselves, blocks settle into place)?
- [ ] Accessibility: how does the pyramid builder work with VoiceOver? (Alternative text-based grouping interface?)

## Story Candidates
1. Tree layout engine: calculate node positions for a balanced pyramid given N blocks
2. Draggable block component: visual block with text, drag gesture, snap behaviour
3. Drop zone logic: detect valid placement positions, snap-to-grid, parent-child relationships
4. Connection line renderer: draw lines between parent and child blocks
5. MECE validation engine: compare user grouping to answer key, identify overlaps and gaps
6. Visual feedback system: colour coding, glow effects, pulse animations for validation states
7. "Build the pyramid" session integration: provide blocks → user arranges → evaluate → feedback
8. "Fix this mess" visual variant: present broken argument as disarranged blocks
9. Red herring blocks: discard zone or rejection mechanism for blocks that don't belong
10. iPad layout: full canvas + Barbara sidebar, multi-touch gestures
11. Mac layout: mouse drag-and-drop, keyboard shortcuts, wider canvas
12. Haptic feedback integration (iPad)
13. Progressive complexity: block count and tree depth calibrated to user level
14. Animation polish: block settling, connection drawing, success celebration

## References
- Primer parallel: The Primer's interactive illustrations — the reader doesn't
  just read about concepts, they manipulate them physically.
- Concept mapping research: Visual arrangement of ideas significantly improves
  retention and understanding of hierarchical relationships.
