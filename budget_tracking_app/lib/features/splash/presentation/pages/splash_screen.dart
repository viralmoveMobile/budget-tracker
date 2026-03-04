import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';
import '../../../common/services/location_service.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import 'onboarding_page.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

const _kOnboardingDoneKey = 'onboarding_done';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _errorMessage = null);

    // Keep brand visible for minimum 2 seconds
    final splashTimer = Future.delayed(const Duration(seconds: 2));

    // Trigger background currency detection
    ref.read(primaryCurrencyProvider.future).catchError((_) => '');

    await splashTimer;

    // Wait for profile to load (max ~3s)
    int attempts = 0;
    while (!ref.read(profileProvider).isLoaded && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 150));
      attempts++;
    }

    // Check biometric authentication if enabled
    final profile = ref.read(profileProvider);
    if (profile.isBiometricEnabled) {
      final authenticated = await _authenticate();
      if (!authenticated) return;
    }

    if (mounted) _navigateToNext();
  }

  Future<bool> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return true;

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      setState(() => _isAuthenticating = false);

      if (!didAuthenticate) {
        setState(() => _errorMessage = 'Authentication failed');
      }

      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric Auth Error: $e');
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      return false;
    }
  }

  Future<void> _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_kOnboardingDoneKey) ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            onboardingDone ? const AuthWrapper() : const OnboardingPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0DCDA3),
              Color(0xFF0A9B7A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // App icon / logo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),

              AppSpacing.gapXl,

              // App name
              const Text(
                'Everyday Expenses',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 10),

              Text(
                'Smart Financial Management',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

              const Spacer(flex: 3),

              // Bottom indicator / error
              if (_isAuthenticating) ...[
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ).animate().fadeIn(),
                AppSpacing.gapMd,
                Text(
                  'Authenticating...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ).animate().fadeIn(),
              ] else if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapLg,
                OutlinedButton(
                  onPressed: _initializeApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r12)),
                  ),
                  child: const Text('Try Again'),
                ),
              ] else ...[
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
