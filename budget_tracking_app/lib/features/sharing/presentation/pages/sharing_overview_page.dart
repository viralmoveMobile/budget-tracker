import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/firestore_sharing_provider.dart';
import '../../domain/models/share_invitation.dart';

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
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        appBar: AppBar(
          title: Text('Sharing',
              style:
                  TextStyle(color: AppTheme.getSurfaceColor(context), fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.sharingColor,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom:  TabBar(
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            tabs: [
              Tab(icon: Icon(Icons.inbox_rounded), text: 'Received'),
              Tab(icon: Icon(Icons.send_rounded), text: 'Sent'),
              Tab(icon: Icon(Icons.people_rounded), text: 'Active'),
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
          label: Text('Send Invite',
              style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.person_add_rounded),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
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
          padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
          itemCount: shares.length,
          itemBuilder: (context, index) {
            final share = shares[index];
            return _buildShareCard(share);
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildInvitationCard(ShareInvitation invitation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    invitation.ownerName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.ownerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        invitation.ownerEmail,
                        style: TextStyle(color: AppTheme.getTextColor(context, isSecondary: true), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: invitation.sharedDataTypes
                  .map((type) => Chip(
                        label: Text(
                          type,
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        padding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(sharingActionsProvider.notifier)
                          .rejectInvitation(invitation.id);
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
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
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentInvitationCard(ShareInvitation invitation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, color: AppTheme.getTextColor(context, isSecondary: true)),
        ),
        title: Text(
          invitation.recipientEmail,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${invitation.status.name}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: invitation.sharedDataTypes
                  .map((type) => Chip(
                        label: Text(type, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.grey[100],
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
        trailing: invitation.status == InvitationStatus.pending
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () {
                  ref
                      .read(sharingActionsProvider.notifier)
                      .cancelInvitation(invitation.id);
                },
              )
            : null,
      ),
    );
  }

  Widget _buildShareCard(share) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            share.ownerEmail[0].toUpperCase(),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          share.ownerEmail,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: share.dataTypes
                  .map<Widget>((type) => Chip(
                        label: Text(type, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.green[50],
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.getTextColor(context, isSecondary: true, opacity: 0.5)),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppTheme.getTextColor(context, isSecondary: true)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showInviteDialog(BuildContext context) {
    final selectedDataTypes = <String>{}; // Local state for dialog

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send Invitation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'friend@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select data to share:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Expenses'),
                value: selectedDataTypes.contains('expenses'),
                onChanged: (checked) {
                  setDialogState(() {
                    if (checked == true) {
                      selectedDataTypes.add('expenses');
                    } else {
                      selectedDataTypes.remove('expenses');
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Cash Book'),
                value: selectedDataTypes.contains('cash_book'),
                onChanged: (checked) {
                  setDialogState(() {
                    if (checked == true) {
                      selectedDataTypes.add('cash_book');
                    } else {
                      selectedDataTypes.remove('cash_book');
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Budgets'),
                value: selectedDataTypes.contains('budgets'),
                onChanged: (checked) {
                  setDialogState(() {
                    if (checked == true) {
                      selectedDataTypes.add('budgets');
                    } else {
                      selectedDataTypes.remove('budgets');
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
              child: const Text('Cancel'),
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
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
