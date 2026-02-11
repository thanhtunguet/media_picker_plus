# Suggested Commands

## Linting & Formatting
```sh
flutter analyze          # Check for issues
dart format lib/ test/   # Format code
```

## Testing
```sh
flutter test             # Run all tests
flutter test test/<file> # Run specific test file
```

## Building / Running Example
```sh
cd example && flutter run  # Run the example app
```

## Notes
- **Never commit** — user commits manually
- After any change, run `flutter analyze` and `dart format`
- Update `CHANGELOG.md` (Unreleased section) after changes
- Update relevant phase file under `plan/` when tasks complete
