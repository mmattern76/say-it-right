# Diamond Age Portfolio — Linting Standards

Canonical SwiftLint and SwiftFormat configuration for all Diamond Age portfolio apps.

## Files

- `.swiftlint.yml` — SwiftLint rules (complexity limits, naming, custom rules)
- `.swiftformat` — SwiftFormat style (indentation, wrapping, imports)

## Usage in a new project

### Option A: Symlink (preferred for monorepo or sibling directories)

```bash
ln -s ../config/linting/.swiftlint.yml .swiftlint.yml
ln -s ../config/linting/.swiftformat .swiftformat
```

### Option B: Copy

```bash
cp config/linting/.swiftlint.yml .swiftlint.yml
cp config/linting/.swiftformat .swiftformat
```

## Project-specific adjustments

- **Included paths**: Edit `included:` in `.swiftlint.yml` to match your source layout
- **Excluded paths**: Add project-specific exclusions under `excluded:`
- **Do NOT weaken rules**: If a rule is too strict, fix the code, don't loosen the limit
- **Per-line disables only**: Use `// swiftlint:disable:next rule_name` with a comment — never file-wide or global disables

## Scripts

Each project should have:

- `scripts/lint.sh` — check mode (CI/pre-commit)
- `scripts/format.sh` — auto-fix mode (developer workflow)

## Prerequisites

```bash
brew install swiftlint swiftformat
```
