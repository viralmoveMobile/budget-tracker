import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/firestore_sharing_provider.dart';
import '../../domain/models/share_invitation.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class SharingOverviewPage extends ConsumerStatefulWidget {
  const SharingOverviewPage({super.key});

  @override
  ConsumerState<SharingOverviewPage> createState() =>
      _SharingOverviewPageState();
}

class _SharingOverviewPageState extends ConsumerState<SharingOverviewPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(myInvitationsProvider);
    final sentInvitationsAsync = ref.watch(sentInvitationsProvider);
    final sharesAsync = ref.watch(usersSharedWithMeProvider);

    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        withTealHeader: true,
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppAppBar(
          title: Text('Sharing',
              style: TextStyle(
                  color: AppTheme.getSurfaceColor(context),
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: const Icon(Icons.inbox_rounded, size: 20),
                child:
                    Text('Received (${invitationsAsync.value?.length ?? 0})'),
              ),
              Tab(
                icon: const Icon(Icons.send_rounded, size: 20),
                child:
                    Text('Sent (${sentInvitationsAsync.value?.length ?? 0})'),
              ),
              Tab(
                icon: const Icon(Icons.people_rounded, size: 20),
                child: Text('Active (${sharesAsync.value?.length ?? 0})'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReceivedTab(invitationsAsync),
            _buildSentTab(sentInvitationsAsync),
            _buildActiveSharesTab(sharesAsync),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'sharing_fab',
          onPressed: () => _showInviteDialog(context),
          label: const Text('Send Invite',
              style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.person_add_rounded),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeroStat(
      BuildContext context, int count, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
              AppSpacing.gapXs,
              Text(
                label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            '$count',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(AsyncValue<List<ShareInvitation>> invitationsAsync) {
    return invitationsAsync.when(
      data: (invitations) {
        if (invitations.isEmpty) {
          return _buildEmptyState(
            'No Invitations',
            'You haven\'t received any sharing invitations yet',
            Icons.inbox_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _buildInvitationCard(invitation);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSentTab(AsyncValue<List<ShareInvitation>> sentAsync) {
    return sentAsync.when(
      data: (sent) {
        if (sent.isEmpty) {
          return _buildEmptyState(
            'No Sent Invitations',
            'You haven\'t sent any invitations yet',
            Icons.send_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: sent.length,
          itemBuilder: (context, index) {
            final invitation = sent[index];
            return _buildSentInvitationCard(invitation);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildActiveSharesTab(AsyncValue sharesAsync) {
    return sharesAsync.when(
      data: (shares) {
        if (shares.isEmpty) {
          return _buildEmptyState(
            'No Active Shares',
            'No one is sharing data with you yet',
            Icons.people_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: shares.length,
          itemBuilder: (context, index) {
            final share = shares[index];
            return _buildShareCard(share);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildInvitationCard(ShareInvitation invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    invitation.ownerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.ownerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        invitation.ownerEmail,
                        style: TextStyle(
                            color: AppTheme.getTextColor(context,
                                isSecondary: true),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: invitation.sharedDataTypes
                  .map((type) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(sharingActionsProvider.notifier)
                          .rejectInvitation(invitation.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r12)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(sharingActionsProvider.notifier)
                          .acceptInvitation(invitation.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r12)),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildSentInvitationCard(ShareInvitation invitation) {
    final isPending = invitation.status == InvitationStatus.pending;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person_rounded,
                  color: AppTheme.primaryColor, size: 22),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.recipientEmail,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  AppSpacing.gapXs,
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: invitation.sharedDataTypes
                        .map((type) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(type,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.amber.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPending ? 'Pending' : 'Accepted',
                style: TextStyle(
                  color: isPending ? Colors.orange[700] : AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isPending)
              IconButton(
                icon: const Icon(Icons.cancel_outlined,
                    color: AppTheme.dangerColor, size: 20),
                onPressed: () {
                  ref
                      .read(sharingActionsProvider.notifier)
                      .cancelInvitation(invitation.id);
                },
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildShareCard(share) {
    final name = share.ownerEmail.split('@').first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        subtitle: Text(
          share.ownerEmail,
          style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextColor(context, isSecondary: true)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 14),
              SizedBox(width: 4),
              Text(
                'Active',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              message,
              style: TextStyle(
                  color: AppTheme.getTextColor(context, isSecondary: true)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  void _showInviteDialog(BuildContext context) {
    final selectedDataTypes = <String>{};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.r24)),
          title: const Text('Send Invitation',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'friend@example.com',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppTheme.primaryColor),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              AppSpacing.gapLg,
              const Text(
                'Select data to share:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              AppSpacing.gapSm,
              for (final type in ['expenses', 'cash_book', 'budgets'])
                CheckboxListTile(
                  title: Text(
                    type == 'cash_book'
                        ? 'Cash Book'
                        : '${type[0].toUpperCase()}${type.substring(1)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  value: selectedDataTypes.contains(type),
                  activeColor: AppTheme.primaryColor,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selectedDataTypes.add(type);
                      } else {
                        selectedDataTypes.remove(type);
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _emailController.clear();
              },
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: selectedDataTypes.isEmpty
                  ? null
                  : () {
                      ref
                          .read(sharingActionsProvider.notifier)
                          .sendShareInvitation(
                            recipientEmail: _emailController.text,
                            sharedDataTypes: selectedDataTypes.toList(),
                          );
                      Navigator.pop(dialogContext);
                      _emailController.clear();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r12)),
              ),
              child: const Text('Send',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
