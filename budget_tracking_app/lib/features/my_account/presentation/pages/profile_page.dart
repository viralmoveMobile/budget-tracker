import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import 'package:budget_tracking_app/features/my_account/domain/models/user_profile.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      try {
        final bool canAuthenticateWithBiometrics =
            await auth.canCheckBiometrics;
        final bool canAuthenticate =
            canAuthenticateWithBiometrics || await auth.isDeviceSupported();

        if (canAuthenticate) {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to enable biometric login',
            options: const AuthenticationOptions(biometricOnly: true),
          );

          if (didAuthenticate) {
            ref.read(profileProvider.notifier).toggleBiometrics(true);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Authentication failed')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Biometric authentication not supported or not set up')),
            );
          }
        }
      } catch (e) {
        debugPrint('Biometric Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    } else {
      ref.read(profileProvider.notifier).toggleBiometrics(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final userAsync = ref.watch(authStateProvider);

    return AppScaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppAppBar(
        title: Text('My Account'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => _buildUserHeader(profile, user),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => _buildUserHeader(profile, null),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            _buildSectionHeader('Security'),
            _buildSecurityCard(profile),
            const SizedBox(height: AppTheme.spaceLg),
            _buildSectionHeader('Personalization'),
            _buildPersonalizationCard(profile),
            const SizedBox(height: AppTheme.spaceLg),
            _buildSectionHeader('User Management'),
            _buildUserManagementCard(profile),
            const SizedBox(height: AppTheme.space2xl),
            Center(
              child: TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout',
                              style: TextStyle(color: AppTheme.dangerColor)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                },
                child: const Text('Logout',
                    style:
                        TextStyle(color: AppTheme.dangerColor, fontSize: 16)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildUserHeader(UserProfile profile, User? user) {
    final String displayName = user?.displayName ?? 'User';
    final String displayEmail = user?.email ??
        (profile.profileType == ProfileType.personal
            ? 'Personal Profile'
            : 'Business Profile');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: AppTheme.elevatedCardDecoration(
          color: AppTheme.getSurfaceColor(context)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Icon(Icons.person,
                    color: Theme.of(context).colorScheme.primary, size: 30)
                : null,
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context))),
                Text(displayEmail,
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            AppTheme.getTextColor(context, isSecondary: true))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppTheme.spaceXs, bottom: AppTheme.spaceSm),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary)),
    );
  }

  Widget _buildSecurityCard(UserProfile profile) {
    return Container(
      decoration:
          AppTheme.cardDecoration(color: AppTheme.getSurfaceColor(context)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary),
            title: Text('Biometric Login',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.getTextColor(context))),
            subtitle: Text('Use Fingerprint or Face ID',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context, isSecondary: true))),
            trailing: Switch(
              value: profile.isBiometricEnabled,
              onChanged: _handleBiometricToggle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationCard(UserProfile profile) {
    return Container(
      decoration:
          AppTheme.cardDecoration(color: AppTheme.getSurfaceColor(context)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.brightness_6_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text('Theme Mode',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.getTextColor(context))),
            subtitle: Text(profile.themeMode.name.toUpperCase(),
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context, isSecondary: true))),
            trailing: DropdownButton<ThemeMode>(
              value: profile.themeMode,
              underline: const SizedBox(),
              dropdownColor: AppTheme.getSurfaceColor(context),
              items: ThemeMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.name.toUpperCase(),
                      style: TextStyle(color: AppTheme.getTextColor(context))),
                );
              }).toList(),
              onChanged: (mode) {
                if (mode != null)
                  ref.read(profileProvider.notifier).updateThemeMode(mode);
              },
            ),
          ),
          Divider(
              height: 1, indent: 50, color: AppTheme.getDividerColor(context)),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).colorScheme.primary),
            title: Text('App Language',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.getTextColor(context))),
            subtitle: Text(profile.language == 'en' ? 'English' : 'Sinhala',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context, isSecondary: true))),
            trailing: DropdownButton<String>(
              value: profile.language,
              underline: const SizedBox(),
              dropdownColor: AppTheme.getSurfaceColor(context),
              items: [
                DropdownMenuItem(
                    value: 'en',
                    child: Text('English',
                        style:
                            TextStyle(color: AppTheme.getTextColor(context)))),
                DropdownMenuItem(
                    value: 'si',
                    child: Text('Sinhala',
                        style:
                            TextStyle(color: AppTheme.getTextColor(context)))),
              ],
              onChanged: (lang) {
                if (lang != null)
                  ref.read(profileProvider.notifier).updateLanguage(lang);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementCard(UserProfile profile) {
    return Container(
      decoration:
          AppTheme.cardDecoration(color: AppTheme.getSurfaceColor(context)),
      child: Column(
        children: [
          RadioListTile<ProfileType>(
            title: Text('Personal Profile',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.getTextColor(context))),
            subtitle: Text('For individual expense tracking',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context, isSecondary: true))),
            value: ProfileType.personal,
            groupValue: profile.profileType,
            onChanged: (value) {
              if (value != null)
                ref.read(profileProvider.notifier).updateProfileType(value);
            },
          ),
          Divider(
              height: 1, indent: 50, color: AppTheme.getDividerColor(context)),
          RadioListTile<ProfileType>(
            title: Text('Business Profile',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.getTextColor(context))),
            subtitle: Text('For company/professional use',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextColor(context, isSecondary: true))),
            value: ProfileType.business,
            groupValue: profile.profileType,
            onChanged: (value) {
              if (value != null)
                ref.read(profileProvider.notifier).updateProfileType(value);
            },
          ),
        ],
      ),
    );
  }
}
