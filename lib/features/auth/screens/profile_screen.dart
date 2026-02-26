/// profile_screen.dart
///
/// Displays the authenticated user's profile data fetched from:
///   GET https://fakestoreapi.com/users/{userId}
///
/// Shows:
///   - Avatar (initials from name)
///   - Full name, username
///   - Email
///   - Phone
///   - Full address (street, suite, city, zip)
///   - Logout button
///
/// All async states (loading / error / data) are handled explicitly so the
/// user always sees meaningful feedback.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the user profile provider — AsyncValue<User?>
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6000),
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        actions: [
          // Logout button placed in the AppBar for quick access.
          TextButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: userAsync.when(
        // ── Loading ─────────────────────────────────────────────────────────
        loading: () => const Center(child: CircularProgressIndicator()),

        // ── Error ────────────────────────────────────────────────────────────
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Could not load profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(userProfileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),

        // ── Data ─────────────────────────────────────────────────────────────
        data: (user) {
          // user can be null if somehow accessed without auth — guard here.
          if (user == null) {
            return const Center(child: Text('Not logged in.'));
          }

          return SingleChildScrollView(
            // SingleChildScrollView here is fine — ProfileScreen is a separate
            // route, completely outside the CustomScrollView on the home screen.
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Avatar ─────────────────────────────────────────────────
                _buildAvatar(user.name.fullName),
                const SizedBox(height: 12),

                // ── Display name + username ────────────────────────────────
                Text(
                  user.name.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // ── Info cards ─────────────────────────────────────────────
                _infoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                _infoCard(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user.phone,
                ),
                _infoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: user.address.fullAddress,
                ),

                const SizedBox(height: 32),

                // ── Logout button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Private builders ─────────────────────────────────────────────────────

  Widget _buildAvatar(String fullName) {
    // Derive initials from the full name — e.g. "John Doe" → "JD"
    final parts = fullName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.first[0].toUpperCase();

    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFFFF6000),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF6000)),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Shows a confirmation dialog before logging out.
  /// On confirm: calls [AuthNotifier.logout] and navigates to /login.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      // GoRouter's redirect will automatically send the user to /login
      // because isAuthenticatedProvider is now false.
      if (context.mounted) context.go('/login');
    }
  }
}
