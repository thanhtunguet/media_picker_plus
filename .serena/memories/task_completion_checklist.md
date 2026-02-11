# Task Completion Checklist

When a task is completed:

1. Run `flutter analyze` — fix any issues related to your changes
2. Run `dart format lib/ test/` — reformat changed files
3. Update `CHANGELOG.md` — add entry under `## Unreleased`
4. Update the correct phase file under `plan/`:
   - Phase 0 (done): `plan/phase-0-completed.md`
   - Phase 1: `plan/phase-1-platform-completion.md`
   - Phase 2: `plan/phase-2-testing-quality.md`
   - Phase 3: `plan/phase-3-enhancement.md`
   - Phase 4 (backlog): `plan/phase-4-future.md`
5. Mark completed tasks `[x]` in the phase file
6. **Do NOT commit** — user does it manually
