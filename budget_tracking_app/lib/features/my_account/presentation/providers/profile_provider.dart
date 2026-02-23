import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_tracking_app/features/my_account/domain/models/user_profile.dart';
import '../../../../core/services/location_service.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  final userId =
      ref.watch(authStateProvider.select((user) => user.value?.uid ?? 'guest'));
  return ProfileNotifier(userId);
});

class ProfileNotifier extends StateNotifier<UserProfile> {
  final String userId;
  ProfileNotifier(this.userId) : super(UserProfile()) {
    _loadProfile();
  }

  String get _prefsKey => 'user_profile_settings_$userId';

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      // Check mounted after async operation but before state update
      if (!mounted) return;

      if (jsonString != null) {
        state = UserProfile.fromJson(json.decode(jsonString))
            .copyWith(isLoaded: true);
      } else {
        state = state.copyWith(isLoaded: true);
        _detectAndSetCurrency();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        state = state.copyWith(isLoaded: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      await prefs.setString(_prefsKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  void updateLanguage(String lang) {
    state = state.copyWith(language: lang);
    _saveProfile();
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveProfile();
  }

  void updateProfileType(ProfileType type) {
    state = state.copyWith(profileType: type);
    _saveProfile();
  }

  void toggleBiometrics(bool enabled) {
    state = state.copyWith(isBiometricEnabled: enabled);
    _saveProfile();
  }

  void updateSeedColor(Color? color) {
    state = state.copyWith(seedColor: color);
    _saveProfile();
  }

  Future<void> _detectAndSetCurrency() async {
    try {
      final locationService = LocationService();
      final countryCode = await locationService.getUserCountryCode();
      if (countryCode != null && mounted) {
        final currency = _mapCountryToCurrency(countryCode);
        state = state.copyWith(currency: currency);
        _saveProfile();
      }
    } catch (e) {
      debugPrint('Error detecting currency: $e');
    }
  }

  String _mapCountryToCurrency(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'US':
        return 'USD';
      case 'LK':
        return 'LKR';
      case 'IN':
        return 'INR';
      case 'GB':
        return 'GBP';
      case 'AU':
        return 'AUD';
      case 'CA':
        return 'CAD';
      case 'JP':
        return 'JPY'; // Yen
      case 'AE':
        return 'AED';
      case 'SG':
        return 'SGD';
      // Euro Zone (simplified list)
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE':
      case 'GR':
      case 'PT':
      case 'AT':
      case 'FI':
      case 'IE':
        return 'EUR';
      default:
        return 'USD';
    }
  }
}
