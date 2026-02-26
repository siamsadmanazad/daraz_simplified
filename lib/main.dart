/// main.dart
///
/// Application entry point.
///
/// Startup sequence:
///   1. WidgetsFlutterBinding.ensureInitialized() — required before any
///      async platform calls.
///   2. SharedPreferences.getInstance() — load persisted auth session BEFORE
///      the widget tree builds so the router redirect has the token
///      immediately and doesn't flash the login screen for returning users.
///   3. Wrap everything in ProviderScope — required by Riverpod.
///      We override [sharedPreferencesProvider] with the loaded instance so
///      any provider can access prefs synchronously via ref.read().
///   4. MaterialApp.router reads the GoRouter from [appRouterProvider] and
///      applies the app theme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/shared_preferences_provider.dart';

void main() async {
  // Step 1: Initialise bindings before any platform channel calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Load SharedPreferences.
  // This must complete BEFORE ProviderScope starts so that
  // authNotifierProvider.build() can call ref.read(sharedPreferencesProvider)
  // synchronously without hitting the "not overridden" error.
  final prefs = await SharedPreferences.getInstance();

  // Step 3: Start the app with Riverpod scope.
  runApp(
    ProviderScope(
      overrides: [
        // Inject the already-initialised SharedPreferences instance.
        // Any provider that calls ref.read(sharedPreferencesProvider) will
        // receive this concrete instance instead of the placeholder.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DarazApp(),
    ),
  );
}

/// Root application widget.
///
/// Extends [ConsumerWidget] so it can read [appRouterProvider] from Riverpod.
/// Using ConsumerWidget here (not ConsumerStatefulWidget) because the root
/// widget has no local state — it only reads the router once.
class DarazApp extends ConsumerWidget {
  const DarazApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router — it is a const Provider and never changes.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Daraz Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // GoRouter integration: provide config instead of home/routes.
      routerConfig: router,
    );
  }
}
