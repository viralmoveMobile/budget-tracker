import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../cash_book/domain/models/cash_book_entry.dart';

/// Service for syncing cash book entries to/from Firestore
class CashBookSyncService {
  final String currentUserId;
  final FirestoreService _firestoreService = FirestoreService();

  CashBookSyncService({required this.currentUserId});

  /// Sync cash book entry to Firestore
  Future<void> syncEntryToFirestore(CashBookEntry entry) async {
    try {
      print('[CashBookSync] Syncing entry ${entry.id} to Firestore');

      // Convert entry to Firestore format
      final entryData = entry.toMap();
      entryData['syncedAt'] = FieldValue.serverTimestamp();

      // Upload to Firestore under user's shared cash book
      await _firestoreService.firestore
          .collection('shared_cash_books')
          .doc(currentUserId)
          .collection('entries')
          .doc(entry.id)
          .set(entryData);

      print('[CashBookSync] ✓ Entry synced successfully');
    } catch (e) {
      print('[CashBookSync] Error syncing entry: $e');
      rethrow;
    }
  }

  /// Delete entry from Firestore
  Future<void> deleteEntryFromFirestore(String entryId) async {
    try {
      print('[CashBookSync] Deleting entry $entryId from Firestore');

      await _firestoreService.firestore
          .collection('shared_cash_books')
          .doc(currentUserId)
          .collection('entries')
          .doc(entryId)
          .delete();

      print('[CashBookSync] ✓ Entry deleted successfully');
    } catch (e) {
      print('[CashBookSync] Error deleting entry: $e');
      rethrow;
    }
  }

  /// Stream shared entries from a specific user
  Stream<List<CashBookEntry>> streamSharedEntries(
      String ownerId, int profileType) {
    print('[CashBookSync] Streaming entries from user: $ownerId');

    return _firestoreService.firestore
        .collection('shared_cash_books')
        .doc(ownerId)
        .collection('entries')
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              // Remove syncedAt before creating entry object
              data.remove('syncedAt');
              return CashBookEntry.fromMap(data);
            } catch (e) {
              print('[CashBookSync] Error parsing entry ${doc.id}: $e');
              return null;
            }
          })
          .whereType<CashBookEntry>()
          .where((e) => e.profileType.index == profileType)
          .toList();

      print('[CashBookSync] Received ${entries.length} shared entries');
      return entries;
    });
  }

  /// Stream entries from all users sharing with current user
  Stream<List<CashBookEntry>> streamAllSharedEntries(
    List<String> sharedUserIds,
    int profileType,
  ) {
    if (sharedUserIds.isEmpty) {
      return Stream.value([]);
    }

    print(
        '[CashBookSync] Streaming entries from ${sharedUserIds.length} users');

    // For single user, stream directly
    if (sharedUserIds.length == 1) {
      return streamSharedEntries(sharedUserIds.first, profileType);
    }

    // For multiple users, merge streams
    final streams =
        sharedUserIds.map((userId) => streamSharedEntries(userId, profileType));
    return _combineEntryStreams(streams.toList());
  }

  /// Combine multiple entry streams into one
  Stream<List<CashBookEntry>> _combineEntryStreams(
    List<Stream<List<CashBookEntry>>> streams,
  ) {
    if (streams.isEmpty) {
      return Stream.value([]);
    }

    if (streams.length == 1) {
      return streams.first;
    }

    // Combine streams by listening to all and merging results
    return Stream.value([]).asyncExpand((initial) async* {
      final List<List<CashBookEntry>> allEntries = [];

      for (final stream in streams) {
        await for (final entries in stream) {
          allEntries.add(entries);
          // Flatten and yield combined list
          yield allEntries.expand((list) => list).toList();
        }
      }
    });
  }
}
