<!-- refreshed: 2026-07-06 -->
# Architecture

**Analysis Date:** 2026-07-06

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│               Flutter UI Layer (Widgets)                     │
│  MyApp (Material Theme) → MyHomePage (Scaffold Layout)       │
│            `lib/main.dart`                                   │
└────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│             Flutter Framework Layer                          │
│  Material Design, Theming, Widget State Management           │
└────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│          Platform Abstraction / Native Bridge                │
│  (Flutter Engine handles iOS, Android, Web)                  │
└────────────────────────────────────────────────────────────┘
         ↓
┌──────────────────┬──────────────────┬───────────────────────┐
│   Android        │      Web         │      iOS              │
│   Runtime        │    Browser       │    (iOS config        │
│   `android/`     │    `web/`        │    not yet present)   │
└──────────────────┴──────────────────┴───────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **MyApp** | Root widget; Material theme initialization; app entry point | `lib/main.dart` |
| **MyHomePage** | Main UI screen; Scaffold with AppBar and centered text | `lib/main.dart` |
| **Flutter Framework** | Handles widget lifecycle, state, rendering, gesture handling | (Flutter SDK) |
| **Android Platform** | Native Android app wrapper, permissions, lifecycle | `android/app/src/main/` |
| **Web Platform** | HTML/Canvas entry point, browser integration | `web/` |

## Pattern Overview

**Overall:** Single-file monolithic widget tree with stateless composition

**Key Characteristics:**
- Entry point: `main()` function calls `runApp(const MyApp())`
- Root widget: `MyApp` extends `StatelessWidget` for immutability
- Theme: Material Design 3 with `ColorScheme.fromSeed()`
- Platform coverage: Android and Web (iOS configuration omitted)
- Testing: Widget test checks for text presence via `WidgetTester`

## Layers

**UI Layer:**
- Purpose: Render visual interface and handle user interactions
- Location: `lib/main.dart`
- Contains: `MyApp` (root), `MyHomePage` (screen), Material components
- Depends on: Flutter framework, Material Design package
- Used by: Flutter runtime, platform-specific wrappers

**Platform Layer:**
- Purpose: Native platform integration and app initialization
- Location: `android/app/src/main/`, `web/`
- Contains: Android manifest, Kotlin main activity, web HTML entry point
- Depends on: Flutter embedding (Android), web JavaScript runtime
- Used by: Operating system / web browser

## Data Flow

### Primary Request Path (App Launch)

1. Platform native entry point (`android/app/src/main/MainActivity` or `web/index.html`)
2. Flutter bootstrap loads Dart VM and compiled code
3. `main()` function executes → `runApp(MyApp())`
4. Flutter builds widget tree: `MyApp` → `MaterialApp` → `MyHomePage`
5. `MyHomePage.build()` returns `Scaffold` with `AppBar` and centered text
6. Framework renders to canvas/native surface
7. Platform displays rendered output

### Testing Flow

1. `flutter test` invokes test runner
2. `WidgetTester.pumpWidget(MyApp())` builds widget tree in test environment
3. `find.text('Hello, World!')` queries widget tree
4. `expect()` assertion validates result

**State Management:**
- No state management library (GetX, Riverpod, Provider) currently used
- All widgets are `StatelessWidget` — no local state
- Theme applied via `ThemeData` and `ColorScheme`

## Key Abstractions

**Material Design Application:**
- Purpose: Provide consistent Material Design UI across platforms
- Examples: `MaterialApp`, `Scaffold`, `AppBar`, `Center`
- Pattern: Material Design 3 with deep purple seed color

**Widget Composition:**
- Purpose: Declarative UI building
- Examples: `MyApp` (root), `MyHomePage` (screen)
- Pattern: Functional widget composition via `build()` methods

## Entry Points

**Main Entry Point (Dart):**
- Location: `lib/main.dart` (line 3-5: `main()` function)
- Triggers: App launch (all platforms)
- Responsibilities: Initialize `MyApp` widget and pass to Flutter runtime

**Android Entry Point (Native):**
- Location: `android/app/src/main/AndroidManifest.xml` (lines 6-27)
- Triggers: Android app launch
- Responsibilities: Declare `MainActivity`, set theme, configure activity lifecycle

**Web Entry Point (HTML):**
- Location: `web/index.html` (line 36)
- Triggers: Browser loads page
- Responsibilities: Load Flutter bootstrap and HTML metadata

## Architectural Constraints

- **Platform support:** Android and Web only (iOS not configured)
- **State management:** Stateless design — no global state container
- **Dart version:** Requires Dart SDK 3.10.7+
- **Widget model:** Single-file definition — all code in `main.dart`
- **Theme:** Hardcoded Material Design 3 with deep purple seed
- **Navigation:** No routing/navigation framework (only single screen)

## Anti-Patterns

### All Code in Single File

**What happens:** Entire app logic and UI defined in `lib/main.dart`

**Why it's wrong:** As app grows, this file becomes unmaintainable; difficult to test individual components; violates separation of concerns

**Do this instead:** Create modular structure:
- `lib/screens/` — Screen widgets
- `lib/widgets/` — Reusable widget components
- `lib/models/` — Data classes
- `lib/services/` — Business logic

### No State Management Layer

**What happens:** Widgets are all `StatelessWidget` with no way to manage application state

**Why it's wrong:** When data needs to persist across screens or update across multiple widgets, there's no mechanism; impossible to handle user interactions that change app state

**Do this instead:** Adopt a state management pattern:
- Provider pattern (minimal, Flutter-recommended)
- Riverpod (type-safe evolution of Provider)
- GetX (opinionated, all-in-one)

### Hardcoded Theme

**What happens:** Theme colors baked into `ThemeData` in `main.dart`

**Why it's wrong:** Cannot easily support dark mode, theme switching, or platform-specific theming without editing main widget

**Do this instead:** Extract theme to separate file:
- `lib/theme/app_theme.dart` — Define `lightTheme`, `darkTheme`
- Pass to `MaterialApp.theme` and `MaterialApp.darkTheme`

## Error Handling

**Strategy:** None currently implemented

**Patterns:**
- No error boundaries or error handling in widgets
- Flutter default error handling (red error screens in debug)

**Recommended approach:** Implement try-catch in async operations and error widgets once app has backend integration.

## Cross-Cutting Concerns

**Logging:** None implemented (Flutter default stdout logging via `print()`)

**Validation:** None implemented — app has no user input

**Authentication:** None implemented — no backend or user identity

---

*Architecture analysis: 2026-07-06*
