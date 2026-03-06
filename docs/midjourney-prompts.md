# Barbara — Midjourney Prompts

All prompts needed to generate artwork for Say it right! / Sag's richtig!

## Character Description

Barbara is a middle-aged woman (late 40s to mid 50s), well-spoken and
sharp. Think experienced elementary school teacher who now coaches older
students. She wears glasses, dresses professionally but not formally,
and has an expressive face that communicates approval or disapproval
before she says a word. She is not a cartoon mascot — she should feel
like a real person rendered in illustration style.

## Visual Style

**Style**: Semi-realistic editorial illustration. More grounded than
Professor Albert's comic cel-shaded look — Barbara should feel like she
could step out of a quality children's book illustration for older readers.
Clean lines, warm lighting, subtle shading. Think Quentin Blake meets
editorial portrait.

**Color palette**:
- Hair: warm auburn/chestnut brown, neatly styled (shoulder-length or tied back)
- Skin: warm natural tones
- Glasses: dark rectangular frames (not round — she's precise, not whimsical)
- Clothing: navy cardigan or blazer over a cream blouse, occasionally a burgundy scarf
- Accent colours: navy (#2C3E6B), burgundy (#8B2E4F), cream (#FFF5E6)

## Workflow

1. Generate **Attentive** avatar first — this is the reference image
2. Use `--sref <seed_from_attentive>` on all subsequent prompts
3. If available, use `--cref <attentive_image_url>` for character reference
4. Generate 4 variations of each, pick the most consistent
5. Post-process: ensure same crop, size, color balance, transparent background

---

## App Icon (1024x1024, no transparency)

**File**: `AppIcon.png` → drop into `App/Assets.xcassets/AppIcon.appiconset/`

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
intelligent confident expression, slight knowing smile,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders, centered composition,
solid warm cream background (#FFF5E6),
app icon design, bold and readable at small sizes,
--style raw --ar 1:1 --v 6.1
```

> Note: App icons must NOT have transparency. Use a solid background.
> After generation, export at exactly 1024x1024px.

---

## Launch Screen Image (@2x: 400x600, @3x: 600x900, transparent bg)

**Files**: `launch-barbara@2x.png`, `launch-barbara@3x.png`
→ drop into `App/Assets.xcassets/launch-barbara.imageset/`

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
standing with arms lightly crossed, one hand gesturing,
confident welcoming posture, slight smile,
navy cardigan over cream blouse, burgundy scarf accent,
full upper body portrait, waist up,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette, transparent background,
centered composition, suitable for mobile app splash screen,
--style raw --ar 2:3 --v 6.1
```

---

## Avatar Expressions (all @2x: 240x240, @3x: 360x360, transparent bg)

All avatar files go into `App/Assets.xcassets/barbara-{name}.imageset/`.
Each imageset expects `barbara-{name}@2x.png` and `barbara-{name}@3x.png`.

Circular crop, head and shoulders only, transparent background.

### Attentive (Default)

Barbara's resting state. Listening, present, expecting something good from you.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
calm attentive expression, slight confident smile, direct gaze,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders,
--style raw --ar 1:1 --v 6.1
```

### Raised Eyebrow

When the user is rambling, being vague, or giving mush. Barbara's signature look.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
one eyebrow raised skeptically, slight tilt of head,
lips pressed together in patient disapproval,
you-can-do-better expression, not angry but unimpressed,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders,
--style raw --ar 1:1 --v 6.1
```

### Nodding

When the user's structure is improving. Measured approval — not celebration.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
slight approving nod, chin dipped, gentle satisfied expression,
eyes showing quiet respect, restrained positive assessment,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders,
--style raw --ar 1:1 --v 6.1
```

### Crossed Arms

When the user is being lazy, not trying, or submitting without effort.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
arms crossed, direct no-nonsense gaze, firm but not hostile,
I'm-waiting expression, patient sternness,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head shoulders and crossed arms visible,
--style raw --ar 1:1 --v 6.1
```

### Warm Smile

Rare. When the user nails a hard exercise. Barbara's praise is earned.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
genuine warm smile, eyes crinkled with pride,
radiant expression of earned approval, truly impressed,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders,
--style raw --ar 1:1 --v 6.1
```

### Thinking

When Barbara is "reading" the user's response. Processing, evaluating.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
thoughtful analytical expression, eyes slightly narrowed,
finger touching temple, considering something carefully,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders,
--style raw --ar 1:1 --v 6.1
```

### Explaining

When Barbara is teaching a concept. Animated, engaged, gesturing.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
engaged explaining expression, one hand raised making a point,
eyebrows slightly raised, mouth open mid-sentence,
animated but composed, teacher in her element,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head shoulders and gesturing hand visible,
--style raw --ar 1:1 --v 6.1
```

### Disappointed

When the user submits the same mistake again, or doesn't apply feedback.

```
editorial illustration of a sharp middle-aged female teacher,
warm auburn hair neatly styled, dark rectangular glasses,
slightly disappointed expression, head tilted,
look of we-talked-about-this, not angry but deflated,
lips in a thin line, eyes showing restrained frustration,
navy cardigan over cream blouse,
semi-realistic illustration style, clean lines, warm lighting,
navy burgundy and cream palette,
circular portrait, head and shoulders,
--style raw --ar 1:1 --v 6.1
```

---

## Asset Drop-In Checklist

After generating all images, drop them into the asset catalog:

```
App/Assets.xcassets/
├── AppIcon.appiconset/
│   └── AppIcon.png                       (1024x1024, solid bg)
├── launch-barbara.imageset/
│   ├── launch-barbara@2x.png            (400x600, transparent)
│   └── launch-barbara@3x.png            (600x900, transparent)
├── barbara-attentive.imageset/
│   ├── barbara-attentive@2x.png         (240x240, transparent)
│   └── barbara-attentive@3x.png         (360x360, transparent)
├── barbara-raised-eyebrow.imageset/
│   ├── barbara-raised-eyebrow@2x.png
│   └── barbara-raised-eyebrow@3x.png
├── barbara-nodding.imageset/
│   ├── barbara-nodding@2x.png
│   └── barbara-nodding@3x.png
├── barbara-crossed-arms.imageset/
│   ├── barbara-crossed-arms@2x.png
│   └── barbara-crossed-arms@3x.png
├── barbara-warm-smile.imageset/
│   ├── barbara-warm-smile@2x.png
│   └── barbara-warm-smile@3x.png
├── barbara-thinking.imageset/
│   ├── barbara-thinking@2x.png
│   └── barbara-thinking@3x.png
├── barbara-explaining.imageset/
│   ├── barbara-explaining@2x.png
│   └── barbara-explaining@3x.png
└── barbara-disappointed.imageset/
    ├── barbara-disappointed@2x.png
    └── barbara-disappointed@3x.png
```

**Total: 19 files** (1 app icon + 2 launch + 16 avatar expressions)

## Expression → Mood Mapping

The hidden metadata tag `mood` in Barbara's response maps to expressions:

| Metadata mood | Expression | When Barbara uses it |
|---------------|------------|---------------------|
| `attentive` | Attentive | Default, listening, start of session |
| `skeptical` | Raised Eyebrow | Vague response, mush words, buried lead |
| `approving` | Nodding | Structure improving, revision is better |
| `waiting` | Crossed Arms | Lazy attempt, no real effort, unchanged revision |
| `proud` | Warm Smile | Nailed it. Clean pyramid. Real improvement. |
| `evaluating` | Thinking | Processing user's response, loading |
| `teaching` | Explaining | Introducing a concept, giving a lesson |
| `disappointed` | Disappointed | Same mistake repeated, feedback not applied |

## Validation

- [ ] All expressions clearly distinguishable at 60pt size
- [ ] Character looks consistent across all expressions (same person)
- [ ] Colors match palette (hair auburn, glasses dark, cardigan navy, blouse cream)
- [ ] Barbara looks competent and warm, never mean or intimidating
- [ ] Even "crossed arms" and "disappointed" read as strict-teacher, not hostile
- [ ] "Warm smile" feels genuinely earned, not generic cheerfulness
- [ ] Transparent backgrounds render correctly on both light and dark modes
- [ ] App icon has solid background, readable at 29pt (smallest iOS usage)
- [ ] Circular crop on avatars — no cut-off hair at edges
- [ ] Style is clearly distinct from Professor Albert (semi-realistic vs. comic cel-shaded)
