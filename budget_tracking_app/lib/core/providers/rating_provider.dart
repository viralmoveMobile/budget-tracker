import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rating_service.dart';

/// Provider for rating service instance
final ratingServiceProvider = Provider<RatingService>((ref) {
  return RatingService.instance;
});

/// Provider to track if rating has been shown
final hasShownRatingProvider = StateProvider<bool>((ref) => false);
