# Coding Conventions

**Analysis Date:** 2026-07-06

## Naming Patterns

**Files:**
- `.dart` extension for all Dart source files
- Snake_case for file names: `main.dart`, `widget_test.dart`
- Entry file: `main.dart` in `lib/` directory

**Classes:**
- PascalCase for all class names: `MyApp`, `MyHomePage`
- Widget classes should suffix descriptors: prefer `MyAppWidget`, `MyHomePage` for widget types
- State classes use `_MyAppState` pattern when splitting State from StatefulWidget

**Functions:**
- camelCase for all function names: `main()`, `build()`, `runApp()`
- Avoid leading underscore unless function is private to file scope
- Private functions use `_functionName` convention

**Variables:**
- camelCase for variable and parameter names: `context`, `tester`, `seedColor`
- Constants use camelCase in Dart (not UPPER_SNAKE_CASE): `myConstant`
- Const keyword used for compile-time constants: `const MyApp()`, `const Text('Hello')`

**Types/Generics:**
- Use full type annotations: `Widget build(BuildContext context)`
- Avoid `var` when type is not obvious; prefer explicit types
- Use `final` for variables that won't be reassigned
- Use `const` for widget construction when possible for performance

## Code Style

**Formatting:**
- Tool: Dart formatter (integrated in Flutter SDK, activated via `flutter format`)
- Indentation: 2 spaces (Flutter standard)
- Line length: 80 characters (configurable, Flutter recommends)
- Spacing: 1 blank line between methods, 2 blank lines between classes

**Linting:**
- Tool: `flutter_lints` 6.0.0 via `package:flutter_lints/flutter.yaml`
- Activated in: `analysis_options.yaml`
- Run with: `flutter analyze`
- Rules can be disabled per-file with `// ignore_for_file: rule_name` or per-line with `// ignore: rule_name`
- Default rules focus on Flutter best practices, null safety, and code quality

## Import Organization

**Order:**
1. Dart SDK imports: `import 'dart:async';`, `import 'dart:ui';`
2. Flutter framework imports: `import 'package:flutter/material.dart';`
3. Package imports: `import 'package:cupertino_icons/cupertino_icons.dart';`
4. Relative imports: `import 'main.dart';`, `import '../widgets/my_widget.dart';`

**Path Aliases:**
- Not currently configured in this project
- When configuring, use `.packages` or define in `pubspec.yaml` under `environment:` section

**Import Best Practices:**
- Use `package:` imports for consistency, not relative imports in production code
- Only use relative imports when necessary in test files
- Group imports by category with blank line separation

## Error Handling

**Patterns:**
- Currently minimal error handling in scaffold code
- Use try-catch for exception handling: `try { } catch (e) { }`
- Dart uses null safety by default (non-nullable by default)
- Use `?.` operator for safe navigation: `obj?.method()`
- Use `??` operator for null coalescing: `value ?? defaultValue`
- Use `late` keyword for late initialization of non-nullable variables

## Logging

**Framework:** No explicit logging framework currently in use; uses Flutter's default logging

**Patterns:**
- Avoid `print()` statements in production (flutter_lints includes `avoid_print` rule)
- Use `debugPrint()` for debug output: `debugPrint('Message')`
- No centralized logging service configured yet
- Consider `logging` package for structured logging in future versions

## Comments

**When to Comment:**
- Comments should explain WHY, not WHAT
- Avoid obvious comments: `// increment counter` is unnecessary for `counter++;`
- Comment complex logic, non-obvious performance decisions, or workarounds
- Keep comments concise and up-to-date with code

**Dartdoc/Documentation:**
- Not yet applied to existing code (main.dart is scaffold-generated)
- Use `///` for public API documentation: 
  ```dart
  /// Builds the main application widget.
  /// 
  /// Returns a MaterialApp configured with theme and home page.
  Widget build(BuildContext context) { }
  ```
- Use `//` for regular comments, `///` for documentation
- Document public classes, methods, and properties
- Document parameters with `@param` and return values with `@return`

## Function Design

**Size:** 
- Keep functions small and focused (under 50 lines preferred)
- Extract helpers when build methods exceed 30 lines
- Single Responsibility Principle: one purpose per function

**Parameters:** 
- Use named parameters in constructors for widgets: `MyApp({super.key})`
- Prefer `super.key` over `key: key` in constructor delegation
- Use required keyword for mandatory parameters
- Group related parameters together

**Return Values:** 
- Explicit return types: `Widget build(...)` not just `build(...)`
- Use `void` when function has no return value
- Async functions return `Future<T>`: `Future<void>`, `Future<String>`
- Always return from all code paths (use `return;` for void if needed)

## Module Design

**Exports:** 
- Create barrel files for easy imports: `export 'widgets/my_widget.dart';`
- Prefer explicit exports over re-exporting entire files
- Keep public API minimal and intentional

**Organization:**
- Group related functionality in subdirectories under `lib/`
- Common structure: `lib/widgets/`, `lib/screens/`, `lib/models/`, `lib/services/`
- Tests mirror source structure: `test/widgets/`, `test/screens/`, etc.

---

*Convention analysis: 2026-07-06*
