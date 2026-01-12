## Development rules

- Run `flutter analyze` to see remaining issues and fix all the issues that are related to your changes.
- Run `dart format` to re-format the code after your changes.
- Never commit your changes. User will do it manually.

## Plan & Update

- Follow the plan and tasks in `@TODOs.md` (index) and the phase files under `plan/`.
- `TODOs.md` must remain index-only (intro + links). Do not add detailed checklists there.
- When you complete or add a task, update it in the correct phase file:
  - Phase 0 (Completed): `plan/phase-0-completed.md`
  - Phase 1 (Platform Completion): `plan/phase-1-platform-completion.md`
  - Phase 2 (Testing & Quality): `plan/phase-2-testing-quality.md`
  - Phase 3 (Enhancements + technical debt): `plan/phase-3-enhancement.md`
  - Phase 4 (Future Enhancements / backlog): `plan/phase-4-future.md`
- When a task is completed:
  - Mark it `[x]` in its phase file (or move it to Phase 0 if it’s a milestone-level completion).
  - Keep task descriptions stable; append sub-bullets for notes/decisions instead of rewriting history.
- Add your changes to `@CHANGELOG.md` in `Unreleased section`. We will use them as release notes for new version.
- Update docs in `doc` folder (Please notice that the folder name is in singular form)
