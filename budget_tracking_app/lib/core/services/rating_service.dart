import 'package:flutter/material.dart';
import 'package:rate_my_app/rate_my_app.dart';

/// Service to manage app rating prompts
class RatingService {
  static final RatingService instance = RatingService._init();

  RatingService._init();

  late RateMyApp _rateMyApp;
  bool _isInitialized = false;

  /// Initialize the rating service with conditions
  Future<void> init() async {
    if (_isInitialized) return;

    _rateMyApp = RateMyApp(
      minDays: 3, // Show after 3 days
      minLaunches: 5, // Show after 5 launches
      remindDays: 7, // Remind after 7 days if "Maybe Later"
      remindLaunches: 10, // Remind after 10 more launches
      googlePlayIdentifier: 'com.yourcompany.budget_tracking_app',
      appStoreIdentifier: 'your-app-store-id',
    );

    await _rateMyApp.init();
    _isInitialized = true;
  }

  /// Check conditions and show rating dialog if appropriate
  Future<void> checkAndShowRating(BuildContext context) async {
    if (!_isInitialized) {
      await init();
    }

    if (!context.mounted) return;

    _rateMyApp.showRateDialog(
      context,
      title: 'Rate Budget Tracker',
      message:
          'If you enjoy using Budget Tracker, would you mind taking a moment to rate it? It won\'t take more than a minute. Thanks for your support!',
      rateButton: 'RATE NOW',
      noButton: 'NO THANKS',
      laterButton: 'MAYBE LATER',
      listener: (button) {
        switch (button) {
          case RateMyAppDialogButton.rate:
            print('[RatingService] User chose to rate');
            break;
          case RateMyAppDialogButton.later:
            print('[RatingService] User chose later');
            break;
          case RateMyAppDialogButton.no:
            print('[RatingService] User declined');
            break;
        }
        return true;
      },
      dialogStyle: const DialogStyle(
        titleAlign: TextAlign.center,
        messageAlign: TextAlign.center,
        messagePadding: EdgeInsets.only(bottom: 20),
      ),
      onDismissed: () {
        _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
      },
    );
  }

  /// Show rating dialog immediately (for testing or manual triggers)
  Future<void> showRatingDialog(BuildContext context) async {
    if (!_isInitialized) {
      await init();
    }

    if (!context.mounted) return;

    await _rateMyApp.showRateDialog(
      context,
      title: 'Rate Budget Tracker',
      message:
          'If you enjoy using Budget Tracker, would you mind taking a moment to rate it? It won\'t take more than a minute. Thanks for your support!',
      rateButton: 'RATE NOW',
      noButton: 'NO THANKS',
      laterButton: 'MAYBE LATER',
      ignoreNativeDialog: false,
      dialogStyle: const DialogStyle(
        titleAlign: TextAlign.center,
        messageAlign: TextAlign.center,
        messagePadding: EdgeInsets.only(bottom: 20),
      ),
    );
  }

  /// Check if conditions are met without showing dialog
  Future<bool> shouldShowRating() async {
    if (!_isInitialized) {
      await init();
    }
    return _rateMyApp.shouldOpenDialog;
  }

  /// Reset rating status (for testing)
  Future<void> reset() async {
    if (_isInitialized) {
      await _rateMyApp.reset();
    }
  }
}
