import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/firestore_sharing_repository.dart';
import '../../domain/models/share_invitation.dart';
import '../../domain/models/sharing_relationship.dart';

// Repository provider
final firestoreSharingRepositoryProvider =
    Provider<FirestoreSharingRepository?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return null;

  return FirestoreSharingRepository(
    currentUserId: user.uid,
    currentUserEmail: user.email ?? '',
  );
});

// ====== INVITATIONS ======

/// Stream of invitations received by current user
final myInvitationsProvider = StreamProvider<List<ShareInvitation>>((ref) {
  final repository = ref.watch(firestoreSharingRepositoryProvider);
  if (repository == null) return Stream.value([]);
  return repository.streamMyInvitations();
});

/// Stream of invitations sent by current user
final sentInvitationsProvider = StreamProvider<List<ShareInvitation>>((ref) {
  final repository = ref.watch(firestoreSharingRepositoryProvider);
  if (repository == null) return Stream.value([]);
  return repository.streamSentInvitations();
});

// ====== SHARING RELATIONSHIPS ======

/// Stream of users sharing data with me
final usersSharedWithMeProvider =
    StreamProvider<List<SharingRelationship>>((ref) {
  final repository = ref.watch(firestoreSharingRepositoryProvider);
  if (repository == null) return Stream.value([]);
  return repository.streamUsersSharedWithMe();
});

/// Stream of users I'm sharing data with
final mySharesProvider = StreamProvider<List<SharingRelationship>>((ref) {
  final repository = ref.watch(firestoreSharingRepositoryProvider);
  if (repository == null) return Stream.value([]);
  return repository.streamMyShares();
});

// ====== ACTIONS CONTROLLER ======

class SharingActionsState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const SharingActionsState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  SharingActionsState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return SharingActionsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class SharingActionsController extends StateNotifier<SharingActionsState> {
  final FirestoreSharingRepository _repository;
  final Ref _ref;

  SharingActionsController(this._repository, this._ref)
      : super(const SharingActionsState());

  /// Create a new share invitation
  Future<void> sendShareInvitation({
    required String recipientEmail,
    required List<String> sharedDataTypes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Use email as owner name since UserProfile doesn't store user's name
      final ownerName = _ref.read(authStateProvider).value?.email ?? 'Unknown';

      await _repository.createShareInvitation(
        ownerName: ownerName,
        recipientEmail: recipientEmail.trim().toLowerCase(),
        sharedDataTypes: sharedDataTypes,
      );

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation sent successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send invitation: $e',
      );
    }
  }

  /// Accept an invitation
  Future<void> acceptInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.acceptInvitation(invitationId);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation accepted!',
      );
      // Invalidate to refresh lists
      _ref.invalidate(myInvitationsProvider);
      _ref.invalidate(usersSharedWithMeProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to accept invitation: $e',
      );
    }
  }

  /// Reject an invitation
  Future<void> rejectInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.rejectInvitation(invitationId);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation rejected.',
      );
      _ref.invalidate(myInvitationsProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reject invitation: $e',
      );
    }
  }

  /// Cancel a sent invitation
  Future<void> cancelInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.cancelInvitation(invitationId);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invitation cancelled.',
      );
      _ref.invalidate(sentInvitationsProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to cancel invitation: $e',
      );
    }
  }

  /// Remove a share relationship
  Future<void> removeShare(String shareId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.removeShare(shareId);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Share removed successfully.',
      );
      _ref.invalidate(mySharesProvider);
      _ref.invalidate(usersSharedWithMeProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to remove share: $e',
      );
    }
  }

  /// Update permission level for a share
  Future<void> updatePermission(
      String shareId, SharePermission permission) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateSharePermission(shareId, permission);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Permission updated.',
      );
      _ref.invalidate(mySharesProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update permission: $e',
      );
    }
  }

  /// Update shared data types for a user
  Future<void> updateDataTypes(String userId, List<String> dataTypes) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateDataTypes(userId, dataTypes);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Shared data types updated!',
      );
      _ref.invalidate(mySharesProvider);
      _ref.invalidate(usersSharedWithMeProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update data types: $e',
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(successMessage: null, errorMessage: null);
  }
}

final sharingActionsProvider =
    StateNotifierProvider<SharingActionsController, SharingActionsState>((ref) {
  final repository = ref.watch(firestoreSharingRepositoryProvider);
  if (repository == null) {
    throw Exception(
        'FirestoreSharingRepository is not available. User must be logged in.');
  }
  return SharingActionsController(repository, ref);
});
