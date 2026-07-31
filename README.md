# DartMini IDE

A purely mobile-first Flutter app called DartMini IDE (beta).

## Features
- Deep black/dark gradient background
- Top AppBar with title and run button
- Horizontal scrollable Toolbar
- Full-screen Code Editor with multiple tabs
- Draggable bottom sheet for Output console
- Auto-save every 2 seconds using Hive
- Full Dart syntax highlighting
- OneCompiler API execution support (default)

## Security
The default OneCompiler API preset is secured using environment variables. To run the app successfully with the default API key, you must provide it at build/run time.

### How to Run
Use `--dart-define` to supply the API key:

```bash
flutter run --dart-define=ONE_COMPILER_KEY=oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac
```

If you don't supply the key, the default preset will not be able to authenticate with OneCompiler. You can still use the custom API builder in the Settings tab.
