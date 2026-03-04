import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/providers/auth_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final userId =
      ref.watch(authStateProvider.select((user) => user.value?.uid ?? 'guest'));
  return LocationService(userId);
});

class LocationService {
  static const String _ipApiUrl = 'https://ipapi.co/json/';
  static const String _primaryCurrencyPrefix = 'primary_currency_code_';

  final String userId;

  LocationService(this.userId);

  String get _primaryCurrencyKey => '$_primaryCurrencyPrefix$userId';

  Future<String> getCurrentLocationCurrencyCode() async {
    // 1. Try to detect via System Locale (fast, offline)
    try {
      final locale = Platform.localeName;
      final format = NumberFormat.simpleCurrency(locale: locale);
      final localeCurrency = format.currencyName;
      if (localeCurrency != null && localeCurrency.length == 3) {
        return localeCurrency;
      }
    } catch (_) {
      // Fallback to network if locale detection fails
    }

    // 2. Try to detect via IP (refined, requires network)
    try {
      final response = await http
          .get(Uri.parse(_ipApiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currency = data['currency'] as String?;
        if (currency != null && currency.length == 3) {
          return currency;
        }
      }
    } on TimeoutException catch (_) {
      debugPrint('Location detection timed out (using fallback USD).');
    } catch (e) {
      debugPrint('Error detecting location via IP (using fallback USD): $e');
    }
    return 'USD';
  }

  Future<String> getPrimaryCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_primaryCurrencyKey);

    if (stored != null) return stored;

    // If not stored, detect it for the first time
    final detected = await getCurrentLocationCurrencyCode();
    await prefs.setString(_primaryCurrencyKey, detected);
    return detected;
  }

  Future<void> setPrimaryCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryCurrencyKey, code);
  }
}

final primaryCurrencyProvider = FutureProvider<String>((ref) {
  return ref.watch(locationServiceProvider).getPrimaryCurrencyCode();
});

final currentLocationCurrencyProvider = FutureProvider<String>((ref) {
  return ref.watch(locationServiceProvider).getCurrentLocationCurrencyCode();
});
