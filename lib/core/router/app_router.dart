/// app_router.dart
///
/// Declarative URL-based navigation using go_router.
///
/// Routes:
///   /login    → LoginScreen      (public — redirected here when logged out)
///   /home     → ProductListingScreen  (protected — requires auth)
///   /profile  → ProfileScreen    (protected — requires auth)
///
/// Redirect logic:
///   Every navigation checks [isAuthenticatedProvider]:
///   - Unauthenticated → always redirect to /login
///   - Authenticated on /login → redirect to /home
///   - Authenticated on /home or /profile → allow through
///
/// The router is exposed as a Riverpod [Provider] so it can read
/// auth state without a BuildContext.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/products/screens/product_listing_screen.dart';

/// The [GoRouter] instance, exposed as a Riverpod provider so it can be
/// passed directly to [MaterialApp.router] without a global variable.
final appRouterProvider = Provider<GoRouter>((ref) {
  // RouterNotifier bridges Riverpod auth state changes to GoRouter's
  // refresh mechanism so redirects fire automatically on login/logout.
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',

    // refreshListenable: notifier → GoRouter re-evaluates the redirect
    // whenever auth state changes (e.g. login completes or logout called).
    refreshListenable: notifier,

    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) {
        // Not logged in + trying to access a protected route → send to login.
        return '/login';
      }

      if (isAuthenticated && isOnLogin) {
        // Already logged in but on login page → send to home.
        return '/home';
      }

      // No redirect needed.
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const ProductListingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],

    // Custom error page for unknown routes.
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// [ChangeNotifier] that listens to Riverpod auth state and notifies
/// [GoRouter] to re-run its redirect function.
///
/// GoRouter requires a [Listenable] for [refreshListenable]. We bridge
/// Riverpod's subscription model to ChangeNotifier here.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    // Listen to auth state changes and notify GoRouter to re-check redirects.
    ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
  }
}
