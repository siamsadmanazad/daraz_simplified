/// shared_preferences_provider.dart
///
/// Exposes a [SharedPreferences] instance as a Riverpod provider so it can be
/// injected into any AsyncNotifier without importing platform code directly.
///
/// Pattern: the provider is overridden in main.dart AFTER the async init:
///   await SharedPreferences.getInstance()  →  override on ProviderScope
///
/// This way the prefs object is always synchronously available inside providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the initialised [SharedPreferences] singleton.
/// Must be overridden in main.dart before the widget tree starts.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This line is intentionally unreachable at runtime.
  // If this executes it means the override in main.dart was forgotten.
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});
