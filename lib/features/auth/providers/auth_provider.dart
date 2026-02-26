/// auth_provider.dart
///
/// Manages authentication state using an [AsyncNotifier].
///
/// State machine:
///   AsyncLoading  → login() in progress
///   AsyncData     → authenticated (token + userId stored)
///   AsyncError    → login failed (bad credentials / network)
///   null data     → logged-out / initial state
///
/// Token persistence:
///   We use [SharedPreferences] (web-compatible) to survive page refreshes.
///   Keys: 'auth_token' and 'auth_user_id'.
///
/// Usage in UI:
///   final state = ref.watch(authNotifierProvider);
///   state.when(data: ..., loading: ..., error: ...);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/providers/shared_preferences_provider.dart';

// ── Storage key constants ───────────────────────────────────────────────────

/// SharedPreferences key for the JWT token.
const _kToken = 'auth_token';

/// SharedPreferences key for the logged-in user's numeric ID.
const _kUserId = 'auth_user_id';

// ── AuthState ───────────────────────────────────────────────────────────────

/// Represents the authenticated user's session data.
/// When this is null inside AsyncData, the user is logged out.
class AuthState {
  final String token;
  final int userId;

  const AuthState({required this.token, required this.userId});
}

// ── AuthNotifier ────────────────────────────────────────────────────────────

/// AsyncNotifier that drives the login/logout lifecycle.
///
/// Extends [AsyncNotifier] so it can expose async loading states to the UI
/// while keeping the login logic inside the notifier (not in the widget).
class AuthNotifier extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async {
    // On first build, restore any persisted session so the user stays
    // logged in after a page refresh.
    return _restoreSession();
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Attempts to log in with the given credentials.
  /// Sets state to AsyncLoading → AsyncData (success) | AsyncError (failure).
  Future<void> login(String username, String password) async {
    // Show loading spinner while the network request is in flight.
    state = const AsyncLoading();

    // Wrap in AsyncValue.guard so any thrown DioException is automatically
    // converted to AsyncError — no try/catch needed in the widget.
    state = await AsyncValue.guard(() async {
      final api = ApiService();

      // Step 1: Authenticate and get JWT token.
      final loginResponse = await api.login(username, password);

      // Step 2: The Fakestore /auth/login doesn't return a userId.
      //         We use userId = 2 as the default profile user for this demo.
      //         In a real app you'd decode the JWT or have a /me endpoint.
      const int userId = 2;

      // Step 3: Persist the session so it survives page refreshes.
      await _persistSession(loginResponse.token, userId);

      return AuthState(token: loginResponse.token, userId: userId);
    });
  }

  /// Clears the token from storage and resets state to null (logged out).
  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);

    // Setting AsyncData(null) signals "logged out but not errored".
    state = const AsyncData(null);
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Reads persisted credentials from SharedPreferences.
  /// Returns null if no session exists (first launch / after logout).
  Future<AuthState?> _restoreSession() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(_kToken);
    final userId = prefs.getInt(_kUserId);

    if (token == null || userId == null) return null;
    return AuthState(token: token, userId: userId);
  }

  /// Writes credentials to SharedPreferences so they survive page refresh.
  Future<void> _persistSession(String token, int userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kToken, token);
    await prefs.setInt(_kUserId, userId);
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

/// The primary auth provider watched throughout the app.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState?>(AuthNotifier.new);

/// Convenience provider: true when the user holds a valid session.
/// Widgets can watch this to decide whether to show login or home.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.valueOrNull != null;
});

/// Fetches the logged-in user's profile from /users/{id}.
/// Returns null when not authenticated.
final userProfileProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState == null) return null;

  final api = ApiService();
  return api.getUser(authState.userId);
});
