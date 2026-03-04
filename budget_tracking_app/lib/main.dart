import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'features/home/presentation/pages/main_shell.dart';
import 'features/splash/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/my_account/presentation/providers/profile_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/firestore_service.dart';
import 'core/services/rating_service.dart';
// import 'firebase_options.dart'; // Uncomment when configured

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('main(): Initializing Firebase...');
    await Firebase.initializeApp();
    print('main(): Firebase initialized successfully.');

    // Initialize Firestore
    print('main(): Initializing Firestore...');
    await FirestoreService().initialize();
    print('main(): Firestore initialized successfully.');

    // Initialize Rating Service
    print('main(): Initializing Rating Service...');
    await RatingService.instance.init();
    print('main(): Rating Service initialized successfully.');
  } catch (e) {
    print('CRITICAL: Firebase Initialization Failed!');
    print('Error: $e');
    print(
        'Make sure google-services.json (Android) or GoogleService-Info.plist (iOS) is correctly placed.');
  }

  print('main(): Starting app with ProviderScope...');
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
  print('main(): runApp called successfully.');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('MyApp: build() called, watching profileProvider...');
    final profile = ref.watch(profileProvider);
    print(
        'MyApp: profileProvider obtained (isLoaded: ${profile.isLoaded}, themeMode: ${profile.themeMode})');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Everyday Expenses',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      locale: Locale(profile.language),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('si'), // Sinhala
      ],
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Auth State
    final firebaseUserAsync = ref.watch(authStateProvider);

    // Determine if logged in (strictly Firebase user)
    final isLoggedIn = firebaseUserAsync.value != null;

    return isLoggedIn ? const MainShell() : const LoginPage();
  }
}
