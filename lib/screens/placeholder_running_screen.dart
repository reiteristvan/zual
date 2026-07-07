import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Minimal Start-destination stand-in (D-01).
///
/// This is a compile-time stub only — [SetupScreen] needs a concrete
/// `PlaceholderRunningScreen` to navigate to. Task 3 of this plan replaces
/// this body with the real shrinking-circle + back-control + auto-return
/// contract (D-01..D-04); nothing here is meant to be user-visible yet.
class PlaceholderRunningScreen extends StatelessWidget {
  const PlaceholderRunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppTokens.bg);
  }
}
