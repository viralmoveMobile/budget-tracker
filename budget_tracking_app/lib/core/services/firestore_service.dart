import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore service for database operations
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get shares => _firestore.collection('shares');
  CollectionReference get invitations => _firestore.collection('invitations');

  // Shared expenses are organized by owner: /shared_expenses/{ownerId}/expenses/{expenseId}
  CollectionReference sharedExpenses(String ownerId) => _firestore
      .collection('shared_expenses')
      .doc(ownerId)
      .collection('expenses');

  /// Initialize Firestore settings
  Future<void> initialize() async {
    // Note: Offline persistence is enabled by default in cloud_firestore v6+
    // No need to call enablePersistence anymore
    print('Firestore: Initialized (offline persistence enabled by default)');
  }

  /// Create or update user document in Firestore
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      await users.doc(uid).set({
        'email': email,
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Firestore: Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user document by email
  Future<DocumentSnapshot?> getUserByEmail(String email) async {
    try {
      final querySnapshot =
          await users.where('email', isEqualTo: email).limit(1).get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.first;
    } catch (e) {
      print('Firestore: Error getting user by email: $e');
      return null;
    }
  }

  /// Check if Firestore is connected
  Future<bool> isConnected() async {
    try {
      await _firestore.collection('_health_check').doc('test').get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
