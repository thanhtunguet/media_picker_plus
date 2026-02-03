# Zed Flutter Debugging

This project includes a Zed debug configuration at `.zed/debug.json` for running the example Flutter app.

## Prerequisites
- Zed installed
- Flutter SDK available in PATH
- A Dart/Flutter debug adapter extension available in Zed (adapter name may be "Dart"; update if needed)

## Usage
1. Open the repo in Zed.
2. Open the Debug panel.
3. Select "Flutter (example)" and start debugging.

## Notes
- The configuration launches the app from `example/`.
- If your adapter uses a different name, change "adapter" in `.zed/debug.json`.
- Add device flags via `toolArgs` if needed (for example `["-d", "macos"]`).
