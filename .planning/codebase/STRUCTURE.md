# Codebase Structure

**Analysis Date:** 2026-07-06

## Directory Layout

```
zual/
├── lib/                      # Dart source code
│   └── main.dart             # App entry point and all UI code
├── test/                     # Dart test files
│   └── widget_test.dart      # UI widget tests
├── web/                      # Web platform configuration
│   ├── index.html            # Web entry point HTML
│   ├── manifest.json         # PWA manifest
│   ├── favicon.png           # Web favicon
│   └── icons/                # Web app icons
├── android/                  # Android platform code
│   ├── app/                  # Android app module
│   │   ├── build.gradle      # Android app build config
│   │   └── src/main/         # Android source and resources
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/       # Kotlin MainActivity
│   │       └── res/          # Android resources (drawables, icons, colors)
│   └── gradle/wrapper/       # Gradle build tool
├── .planning/                # GSD planning directory
│   └── codebase/             # Codebase analysis documents
├── design/                   # Design assets (untracked)
├── pubspec.yaml              # Dart/Flutter package manifest
├── pubspec.lock              # Locked dependency versions
├── analysis_options.yaml     # Dart linter configuration
├── .gitignore                # Git ignore rules
└── README.md                 # Project readme
```

## Directory Purposes

**`lib/`:**
- Purpose: Dart source code for the application
- Contains: Widget definitions, business logic, models, services
- Key files: `main.dart` (currently the only file)

**`test/`:**
- Purpose: Dart test files (unit, widget, integration)
- Contains: Test suites using `flutter_test`
- Key files: `widget_test.dart` (widget test for Hello, World!)

**`web/`:**
- Purpose: Web platform-specific configuration and assets
- Contains: HTML entry point, PWA manifest, web icons
- Key files: `index.html` (loads Flutter web bootstrap)

**`android/`:**
- Purpose: Android platform-specific code and configuration
- Contains: Android manifest, Gradle build config, Kotlin code, native resources
- Key files: `AndroidManifest.xml` (app metadata, MainActivity declaration)

**`.planning/`:**
- Purpose: GSD (Getting Stuff Done) planning and analysis
- Contains: Project plans, phase documents, codebase analysis
- Key files: `codebase/ARCHITECTURE.md`, `codebase/STRUCTURE.md`

**`design/`:**
- Purpose: Design assets and mockups (untracked in git)
- Contains: Figma exports, design specs, UI mockups
- Committed: No (present in working directory)

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Dart app entry point — defines `main()` function and root widget
- `web/index.html`: Web entry point — loads Flutter JavaScript bootstrap
- `android/app/src/main/AndroidManifest.xml`: Android entry point — declares MainActivity

**Configuration:**
- `pubspec.yaml`: Flutter/Dart package manifest — declares dependencies and app metadata
- `analysis_options.yaml`: Linter configuration — activates `flutter_lints/flutter.yaml`
- `android/app/build.gradle`: Android build configuration — app version, signing, dependencies
- `web/manifest.json`: PWA manifest — app metadata for web install

**Core Logic:**
- `lib/main.dart`: Entire app logic and UI (MyApp and MyHomePage widgets)

**Testing:**
- `test/widget_test.dart`: Widget test verifying "Hello, World!" text appears

**Platform Resources:**
- `android/app/src/main/res/`: Android drawable assets, colors, strings
- `web/icons/`: Web app icons for PWA

## Naming Conventions

**Files:**
- Dart files: `snake_case.dart` (e.g., `main.dart`, `widget_test.dart`)
- Android resources: lowercase with underscores (e.g., `ic_launcher.xml`)
- Web files: lowercase with hyphens (e.g., `manifest.json`)

**Directories:**
- Dart source: `lib/`
- Tests: `test/`
- Platform-specific: `web/`, `android/`, `ios/` (if present)

**Classes and Widgets:**
- PascalCase for all class/widget names (e.g., `MyApp`, `MyHomePage`)
- Avoid trailing `Page` or `Screen` suffix convention is not established yet

## Where to Add New Code

**New Feature (Screen/Page):**
- Primary code: Create new file in `lib/screens/` (needs to be created)
  - Example: `lib/screens/home_screen.dart`, `lib/screens/settings_screen.dart`
- Tests: Create corresponding file in `test/screens/` (needs to be created)
  - Example: `test/screens/home_screen_test.dart`
- Update: Import and navigate to new screen in `lib/main.dart` (or routing configuration once added)

**New Reusable Component/Widget:**
- Implementation: `lib/widgets/` (directory to be created)
  - Example: `lib/widgets/custom_app_bar.dart`, `lib/widgets/profile_card.dart`
- Usage: Import in screen/widget files where needed

**New Business Logic (Service):**
- Implementation: `lib/services/` (directory to be created)
  - Example: `lib/services/api_service.dart`, `lib/services/auth_service.dart`
- Usage: Inject or call from screen/widget

**Shared Models/Data Classes:**
- Implementation: `lib/models/` (directory to be created)
  - Example: `lib/models/user.dart`, `lib/models/post.dart`
- Usage: Import in services and screens

**Utilities and Helpers:**
- Implementation: `lib/utils/` (directory to be created)
  - Example: `lib/utils/constants.dart`, `lib/utils/extensions.dart`
- Usage: Import where needed

**Current State:** All code currently lives in `lib/main.dart`. Before adding new features, establish directory structure above.

## Special Directories

**`build/`:**
- Purpose: Compiled build artifacts
- Generated: Yes (by `flutter build` / `flutter run`)
- Committed: No (.gitignore)

**`.dart_tool/`:**
- Purpose: Dart/Flutter tool cache and package resolution
- Generated: Yes (by `flutter pub get`)
- Committed: No (.gitignore)

**`.idea/`:**
- Purpose: IntelliJ IDEA / Android Studio IDE metadata
- Generated: Yes (by IDE)
- Committed: No (.gitignore)

**`design/`:**
- Purpose: Design assets and mockups
- Generated: No (manually created)
- Committed: No (untracked — visible in `git status`)

---

*Structure analysis: 2026-07-06*
