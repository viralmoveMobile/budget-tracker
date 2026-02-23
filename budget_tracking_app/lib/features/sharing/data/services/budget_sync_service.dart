import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../expenses/data/models/budget_limit.dart';

/// Service for syncing budget limits to/from Firestore
class BudgetSyncService {
  final String currentUserId;
  final FirestoreService _firestoreService = FirestoreService();

  BudgetSyncService({required this.currentUserId});

  /// Sync budget limit to Firestore
  Future<void> syncBudgetToFirestore(BudgetLimit budget) async {
    try {
      print('[BudgetSync] Syncing budget ${budget.id} to Firestore');

      // Convert budget to Firestore format
      final budgetData = budget.toMap();
      budgetData['syncedAt'] = FieldValue.serverTimestamp();

      // Upload to Firestore under user's shared budgets
      await _firestoreService.firestore
          .collection('shared_budgets')
          .doc(currentUserId)
          .collection('budgets')
          .doc(budget.id)
          .set(budgetData);

      print('[BudgetSync] ✓ Budget synced successfully');
    } catch (e) {
      print('[BudgetSync] Error syncing budget: $e');
      rethrow;
    }
  }

  /// Delete budget from Firestore
  Future<void> deleteBudgetFromFirestore(String budgetId) async {
    try {
      print('[BudgetSync] Deleting budget $budgetId from Firestore');

      await _firestoreService.firestore
          .collection('shared_budgets')
          .doc(currentUserId)
          .collection('budgets')
          .doc(budgetId)
          .delete();

      print('[BudgetSync] ✓ Budget deleted successfully');
    } catch (e) {
      print('[BudgetSync] Error deleting budget: $e');
      rethrow;
    }
  }

  /// Stream shared budgets from a specific user
  Stream<List<BudgetLimit>> streamSharedBudgets(
      String ownerId, int profileType) {
    print('[BudgetSync] Streaming budgets from user: $ownerId');

    return _firestoreService.firestore
        .collection('shared_budgets')
        .doc(ownerId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) {
      final budgets = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              // Remove syncedAt before creating budget object
              data.remove('syncedAt');
              return BudgetLimit.fromMap(data);
            } catch (e) {
              print('[BudgetSync] Error parsing budget ${doc.id}: $e');
              return null;
            }
          })
          .whereType<BudgetLimit>()
          .where((b) => b.profileType.index == profileType)
          .toList();

      print('[BudgetSync] Received ${budgets.length} shared budgets');
      return budgets;
    });
  }

  /// Stream budgets from all users sharing with current user
  Stream<List<BudgetLimit>> streamAllSharedBudgets(
    List<String> sharedUserIds,
    int profileType,
  ) {
    if (sharedUserIds.isEmpty) {
      return Stream.value([]);
    }

    print('[BudgetSync] Streaming budgets from ${sharedUserIds.length} users');

    // For single user, stream directly
    if (sharedUserIds.length == 1) {
      return streamSharedBudgets(sharedUserIds.first, profileType);
    }

    // For multiple users, merge streams
    final streams =
        sharedUserIds.map((userId) => streamSharedBudgets(userId, profileType));
    return _combineBudgetStreams(streams.toList());
  }

  /// Combine multiple budget streams into one
  Stream<List<BudgetLimit>> _combineBudgetStreams(
    List<Stream<List<BudgetLimit>>> streams,
  ) {
    if (streams.isEmpty) {
      return Stream.value([]);
    }

    if (streams.length == 1) {
      return streams.first;
    }

    // Combine streams by listening to all and merging results
    return Stream.value([]).asyncExpand((initial) async* {
      final List<List<BudgetLimit>> allBudgets = [];

      for (final stream in streams) {
        await for (final budgets in stream) {
          allBudgets.add(budgets);
          // Flatten and yield combined list
          yield allBudgets.expand((list) => list).toList();
        }
      }
    });
  }
}
