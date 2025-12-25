# Task Completion Checklist

When a task is completed, follow these steps:

## 1. Code Quality
- [ ] Run `flutter analyze` to check for issues
- [ ] Fix all issues related to your changes
- [ ] Run `dart format .` to format the code

## 2. Documentation
- [ ] Update relevant plan files under `plan/` directory:
  - Phase 0 (Completed): `plan/phase-0-completed.md`
  - Phase 1 (Platform Completion): `plan/phase-1-platform-completion.md`
  - Phase 2 (Testing & Quality): `plan/phase-2-testing-quality.md`
  - Phase 3 (Enhancements): `plan/phase-3-enhancement.md`
  - Phase 4 (Future): `plan/phase-4-future.md`
- [ ] Mark completed tasks with `[x]` in the appropriate phase file
- [ ] Add changes to `CHANGELOG.md` in the "Unreleased" section
- [ ] Keep `TODOs.md` as index-only (intro + links)

## 3. Important Rules
- **NEVER commit changes** - User will do it manually
- **NEVER skip hooks** (--no-verify, --no-gpg-sign, etc.)
- Keep task descriptions stable in plan files
- Append sub-bullets for notes instead of rewriting history