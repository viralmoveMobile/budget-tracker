import 'package:flutter/material.dart';

enum ProfileType {
  personal,
  business,
}

class UserProfile {
  final String language;
  final ThemeMode themeMode;
  final ProfileType profileType;
  final bool isBiometricEnabled;
  final bool isLoaded;
  final Color? seedColor;
  final String currency;

  UserProfile({
    this.language = 'en',
    this.themeMode = ThemeMode.system,
    this.profileType = ProfileType.personal,
    this.isBiometricEnabled = false,
    this.isLoaded = false,
    this.seedColor,
    this.currency = 'USD',
  });

  UserProfile copyWith({
    String? language,
    ThemeMode? themeMode,
    ProfileType? profileType,
    bool? isBiometricEnabled,
    bool? isLoaded,
    Color? seedColor,
    String? currency,
  }) {
    return UserProfile(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      profileType: profileType ?? this.profileType,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
      seedColor: seedColor ?? this.seedColor,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'themeMode': themeMode.index,
      'profileType': profileType.index,
      'isBiometricEnabled': isBiometricEnabled,
      'seedColor': seedColor?.value,
      'currency': currency,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      language: json['language'] ?? 'en',
      themeMode: ThemeMode.values[json['themeMode'] ?? ThemeMode.system.index],
      profileType:
          ProfileType.values[json['profileType'] ?? ProfileType.personal.index],
      isBiometricEnabled: json['isBiometricEnabled'] ?? false,
      seedColor: json['seedColor'] != null ? Color(json['seedColor']) : null,
      currency: json['currency'] ?? 'USD',
    );
  }
}
