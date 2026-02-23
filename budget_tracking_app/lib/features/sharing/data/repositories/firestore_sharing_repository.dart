import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/models/share_invitation.dart';
import '../../domain/models/sharing_relationship.dart';

class FirestoreSharingRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserId;
  final String currentUserEmail;

  FirestoreSharingRepository({
    required this.currentUserId,
    required this.currentUserEmail,
  });

  // ====== INVITATIONS ======

  /// Create a new share invitation
  Future<String> createShareInvitation({
    required String ownerName,
    required String recipientEmail,
    required List<String> sharedDataTypes,
  }) async {
    try {
      // Check if recipient exists in Firestore users
      final recipientDoc =
          await _firestoreService.getUserByEmail(recipientEmail);

      // Create invitation
      final invitation = ShareInvitation(
        id: '', // Will be set by Firestore
        ownerId: currentUserId,
        ownerEmail: currentUserEmail,
        ownerName: ownerName,
        recipientEmail: recipientEmail,
        status: InvitationStatus.pending,
        sharedDataTypes: sharedDataTypes,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final docRef =
          await _firestoreService.invitations.add(invitation.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating share invitation: $e');
      rethrow;
    }
  }

  /// Get invitations sent to current user (by email)
  Stream<List<ShareInvitation>> streamMyInvitations() {
    return _firestoreService.invitations
        .where('recipientEmail', isEqualTo: currentUserEmail)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      final invitations = snapshot.docs
          .map((doc) => ShareInvitation.fromFirestore(doc))
          .where((inv) => !inv.isExpired)
          .toList();

      // Sort in memory to avoid needing composite index
      invitations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invitations;
    });
  }

  /// Get invitations I've sent to others
  Stream<List<ShareInvitation>> streamSentInvitations() {
    return _firestoreService.invitations
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final invitations = snapshot.docs
          .map((doc) => ShareInvitation.fromFirestore(doc))
          .toList();

      // Sort in memory to avoid needing composite index
      invitations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invitations;
    });
  }

  /// Accept an invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      final invitationDoc =
          await _firestoreService.invitations.doc(invitationId).get();

      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation = ShareInvitation.fromFirestore(invitationDoc);

      // Create sharing relationship
      final shareId = '${invitation.ownerId}_$currentUserId';
      await _firestoreService.shares.doc(shareId).set(
            SharingRelationship(
              id: shareId,
              ownerId: invitation.ownerId,
              ownerEmail: invitation.ownerEmail,
              ownerName: invitation.ownerName,
              recipientId: currentUserId,
              recipientEmail: currentUserEmail,
              dataTypes: invitation.sharedDataTypes,
              permission: SharePermission.view,
              status: 'active',
              createdAt: DateTime.now(),
            ).toFirestore(),
          );

      // Update invitation status
      await _firestoreService.invitations.doc(invitationId).update({
        'status': InvitationStatus.accepted.name,
      });
    } catch (e) {
      print('Error accepting invitation: $e');
      rethrow;
    }
  }

  /// Reject an invitation
  Future<void> rejectInvitation(String invitationId) async {
    try {
      await _firestoreService.invitations.doc(invitationId).update({
        'status': InvitationStatus.rejected.name,
      });
    } catch (e) {
      print('Error rejecting invitation: $e');
      rethrow;
    }
  }

  /// Cancel a sent invitation
  Future<void> cancelInvitation(String invitationId) async {
    try {
      await _firestoreService.invitations.doc(invitationId).delete();
    } catch (e) {
      print('Error canceling invitation: $e');
      rethrow;
    }
  }

  // ====== SHARING RELATIONSHIPS ======

  /// Get users who are sharing data with me
  Stream<List<SharingRelationship>> streamUsersSharedWithMe() {
    return _firestoreService.shares
        .where('recipientId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharingRelationship.fromFirestore(doc))
            .toList());
  }

  /// Get users I'm sharing data with
  Stream<List<SharingRelationship>> streamMyShares() {
    return _firestoreService.shares
        .where('ownerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SharingRelationship.fromFirestore(doc))
            .toList());
  }

  /// Remove a share (revoke access)
  Future<void> removeShare(String shareId) async {
    try {
      await _firestoreService.shares.doc(shareId).delete();
    } catch (e) {
      print('Error removing share: $e');
      rethrow;
    }
  }

  /// Update share permission
  Future<void> updateSharePermission(
    String shareId,
    SharePermission permission,
  ) async {
    try {
      await _firestoreService.shares.doc(shareId).update({
        'permission': permission.name,
      });
    } catch (e) {
      print('Error updating share permission: $e');
      rethrow;
    }
  }

  /// Pause/Resume a share
  Future<void> toggleShareStatus(String shareId, bool isActive) async {
    try {
      await _firestoreService.shares.doc(shareId).update({
        'status': isActive ? 'active' : 'paused',
      });
    } catch (e) {
      print('Error toggling share status: $e');
      rethrow;
    }
  }

  /// Update shared data types for a relationship
  Future<void> updateDataTypes(String userId, List<String> dataTypes) async {
    try {
      // Update the relationship where current user is the owner sharing with this userId
      final shareId = '${currentUserId}_$userId';
      await _firestoreService.shares.doc(shareId).update({
        'sharedDataTypes': dataTypes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating data types: $e');
      rethrow;
    }
  }
}
