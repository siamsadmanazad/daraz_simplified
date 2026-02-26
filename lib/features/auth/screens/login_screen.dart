/// login_screen.dart
///
/// The entry screen shown to unauthenticated users.
///
/// UI layout:
///   - Orange Daraz-style header with logo text
///   - Username and password text fields
///   - Login button (shows spinner during request)
///   - Error banner if credentials are wrong / network fails
///
/// On successful login the router automatically navigates to /home because
/// [isAuthenticatedProvider] flips to true and the GoRouter redirect fires.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── Form state ──────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controls whether the password field shows plain text or bullets.
  bool _obscurePassword = true;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks.
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Called when the Login button is tapped.
  /// Validates the form, then delegates to [AuthNotifier.login].
  Future<void> _submit() async {
    // Don't submit if the form has validation errors.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authNotifierProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch auth state so the loading spinner and error banner react instantly.
    final authState = ref.watch(authNotifierProvider);

    final isLoading = authState.isLoading;

    // Extract error message when login fails.
    final errorMessage = authState.hasError
        ? _friendlyError(authState.error)
        : null;

    return Scaffold(
      // ── Background ───────────────────────────────────────────────────────
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView here is fine — this is a standalone screen,
          // NOT inside the CustomScrollView hierarchy used on the home screen.
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // ── Daraz-style header ────────────────────────────────────────
              _buildHeader(),

              const SizedBox(height: 32),

              // ── Login card ───────────────────────────────────────────────
              _buildLoginCard(isLoading, errorMessage),

              const SizedBox(height: 16),

              // ── Demo credentials hint ─────────────────────────────────────
              _buildHint(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Private builders ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, bottom: 32),
      child: Column(
        children: [
          // Orange circle with "D" mimicking the Daraz logo.
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6000),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Daraz Clone',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6000),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Powered by Fakestore API',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading, String? errorMessage) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign In',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── Error banner ──────────────────────────────────────────────
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Username field ────────────────────────────────────────────
              TextFormField(
                controller: _usernameController,
                enabled: !isLoading,
                decoration: _inputDecoration(
                  label: 'Username',
                  hint: 'e.g. mor_2314',
                  icon: Icons.person_outline,
                ),
                // Basic presence check — real auth validation happens server-side.
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // ── Password field ────────────────────────────────────────────
              TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  label: 'Password',
                  hint: '••••••',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),

              // ── Login button ──────────────────────────────────────────────
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Demo credentials',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Username: mor_2314\nPassword: 83r5^_',
            style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  /// Converts a raw exception into a user-facing message.
  String _friendlyError(Object? error) {
    if (error == null) return 'An unknown error occurred.';
    final msg = error.toString();
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Invalid username or password.';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Login failed. Please try again.';
  }
}
