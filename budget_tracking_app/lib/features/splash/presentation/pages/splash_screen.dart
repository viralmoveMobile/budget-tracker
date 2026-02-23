import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart'; // Import for AuthWrapper
import '../../../common/services/location_service.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';

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
    print('SplashScreen: initState called, starting initialization...');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('SplashScreen: _initializeApp started');
    setState(() {
      _errorMessage = null;
    });

    // 1. Start the minimum splash timer (ensure branding visibility)
    print('SplashScreen: starting 2-second timer...');
    final splashTimer = Future.delayed(const Duration(seconds: 2));

    // 2. Initialize Primary Currency in background (non-blocking)
    print('SplashScreen: triggering background currency detection...');
    ref.read(primaryCurrencyProvider.future).then((_) {
      print('SplashScreen: currency detection completed in background');
    }).catchError((e) {
      print('SplashScreen: currency detection failed (ignored): $e');
    });

    // 3. Wait for the timer
    print('SplashScreen: waiting for timer...');
    await splashTimer;
    print('SplashScreen: timer finished.');

    // 4. Wait for profile to be loaded with timeout
    print('SplashScreen: waiting for profile load...');
    int attempts = 0;
    while (!ref.read(profileProvider).isLoaded && attempts < 20) {
      print('SplashScreen: profile load attempt ${attempts + 1}/20...');
      await Future.delayed(const Duration(milliseconds: 150));
      attempts++;
    }

    final isLoaded = ref.read(profileProvider).isLoaded;
    print('SplashScreen: profile isLoaded = $isLoaded');

    if (!isLoaded) {
      print(
          'SplashScreen: WARNING - profile did not load in time, proceeding anyway');
    }

    // 5. Check for Biometric Authentication
    final profile = ref.read(profileProvider);
    print(
        'SplashScreen: checking biometrics (enabled: ${profile.isBiometricEnabled})...');
    if (profile.isBiometricEnabled) {
      final authenticated = await _authenticate();
      if (!authenticated) {
        print('SplashScreen: authentication failed, staying on splash screen');
        return; // Stay on splash screen if authentication failed
      }
      print('SplashScreen: authentication successful');
    }

    if (mounted) {
      print('SplashScreen: navigating to next screen...');
      _navigateToNext();
    } else {
      print('SplashScreen: WARNING - widget not mounted, skipping navigation');
    }
  }

  Future<bool> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; // Fallback if not supported but somehow enabled
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow passcode fallback if biometric fails
        ),
      );

      setState(() {
        _isAuthenticating = false;
      });

      if (!didAuthenticate) {
        setState(() {
          _errorMessage = 'Authentication failed';
        });
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

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'Budget Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 12),

            const Text(
              'Smart Financial Management',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 48),

            // Loading Indicator / Error Message
            if (_isAuthenticating)
              const Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Authenticating...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ).animate().fadeIn()
            else if (_errorMessage != null)
              Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.dangerColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ).animate().fadeIn()
            else
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
