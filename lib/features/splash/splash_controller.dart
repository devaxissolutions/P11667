import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashControllerProvider = Provider((ref) => SplashController());

class SplashController {
  Future<void> init() async {
    // Simulate initialization delay (e.g., checking auth status, loading prefs)
    // The animation duration in the UI will likely be the governing factor,
    // but this method allows for async work.
    await Future.delayed(const Duration(milliseconds: 1200));
  }
}
