import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../expenses/data/models/expense.dart';
import '../repositories/firestore_sharing_repository.dart';

/// Service to sync expense data to/from Firestore for sharing
class ExpenseSyncService {
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserId;

  ExpenseSyncService({required this.currentUserId});

  /// Sync a local expense to Firestore (for sharing with others)
  Future<void> syncExpenseToFirestore(Expense expense) async {
    try {
      print('[ExpenseSync] Syncing expense ${expense.id} to Firestore');

      // Convert expense to Firestore format
      final expenseData = expense.toMap();
      expenseData['syncedAt'] = FieldValue.serverTimestamp();

      // Upload to Firestore under user's shared expenses
      await _firestoreService
          .sharedExpenses(currentUserId)
          .doc(expense.id)
          .set(expenseData);

      print('[ExpenseSync] ✓ Expense synced successfully');
    } catch (e) {
      print('[ExpenseSync] Error syncing expense: $e');
      rethrow;
    }
  }

  /// Delete synced expense from Firestore
  Future<void> deleteExpenseFromFirestore(String expenseId) async {
    try {
      await _firestoreService
          .sharedExpenses(currentUserId)
          .doc(expenseId)
          .delete();
    } catch (e) {
      print('[ExpenseSync] Error deleting expense: $e');
      rethrow;
    }
  }

  /// Stream expenses shared by a specific user
  Stream<List<Expense>> streamSharedExpenses(String ownerId, int profileType) {
    print('[ExpenseSync] Streaming expenses from user: $ownerId');

    return _firestoreService
        .sharedExpenses(ownerId)
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              // Remove syncedAt before creating Expense object
              data.remove('syncedAt');
              return Expense.fromMap(data);
            } catch (e) {
              print('[ExpenseSync] Error parsing expense ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Expense>()
          .where((e) =>
              e.profileType.index == profileType) // Filter by profileType
          .toList();

      print('[ExpenseSync] Received ${expenses.length} shared expenses');
      return expenses;
    });
  }

  /// Stream all expenses from users sharing with me
  Stream<List<Expense>> streamAllSharedExpenses(
    List<String> sharedUserIds,
    int profileType,
  ) {
    if (sharedUserIds.isEmpty) {
      return Stream.value([]);
    }

    // This will merge multiple streams
    print(
        '[ExpenseSync] Streaming expenses from ${sharedUserIds.length} users');

    // For now, stream from first user (can be enhanced to merge multiple streams)
    if (sharedUserIds.length == 1) {
      return streamSharedExpenses(sharedUserIds.first, profileType);
    }

    // For multiple users, we need to merge streams
    // Simple implementation: create a stream for each user and combine
    final streams = sharedUserIds
        .map((userId) => streamSharedExpenses(userId, profileType));

    // Combine all streams into one
    return _combineExpenseStreams(streams.toList());
  }

  /// Combine multiple expense streams into one
  Stream<List<Expense>> _combineExpenseStreams(
    List<Stream<List<Expense>>> streams,
  ) async* {
    // Listen to all streams and combine results
    final controllers = <StreamController<List<Expense>>>[];
    final allExpenses = <String, Expense>{}; // Use Map to avoid duplicates

    for (final stream in streams) {
      final controller = StreamController<List<Expense>>();
      controllers.add(controller);

      stream.listen((expenses) {
        // Add expenses to combined map
        for (final expense in expenses) {
          allExpenses[expense.id] = expense;
        }
        controller.add(allExpenses.values.toList());
      });
    }

    // Yield combined results
    await for (final _ in controllers.first.stream) {
      yield allExpenses.values.toList();
    }

    // Cleanup
    for (final controller in controllers) {
      await controller.close();
    }
  }

  /// Check if user has active shares
  Future<bool> hasActiveShares() async {
    try {
      final sharingRepo = FirestoreSharingRepository(
        currentUserId: currentUserId,
        currentUserEmail: '', // Not needed for this check
      );

      // Check if user has any active shares (either as owner or recipient)
      final myShares = await sharingRepo.streamMyShares().first;
      final sharedWithMe = await sharingRepo.streamUsersSharedWithMe().first;

      return myShares.isNotEmpty || sharedWithMe.isNotEmpty;
    } catch (e) {
      print('[ExpenseSync] Error checking active shares: $e');
      return false;
    }
  }
}
