import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Help & Support',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Quick Start Tutorials'),
          const SizedBox(height: 12),
          _buildTutorialItem(
            context,
            'Getting Started',
            'Learn the basics of tracking your first expense.',
            Icons.play_circle_outline_rounded,
            Colors.blue,
          ),
          _buildTutorialItem(
            context,
            'Managing Multiple Accounts',
            'How to set up pots for savings, cash, and bank.',
            Icons.account_balance_wallet_rounded,
            Colors.purple,
          ),
          _buildTutorialItem(
            context,
            'Custom Invoicing',
            'Setting up your business profile and sending bills.',
            Icons.description_rounded,
            Colors.orange,
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Frequently Asked Questions'),
          const SizedBox(height: 12),
          _buildFAQCard(context),
          const SizedBox(height: 40),
          _buildContactSupport(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.help_center_rounded,
              color: AppTheme.getSurfaceColor(context), size: 48),
          const SizedBox(height: 16),
          Text(
            'How can we help you today?',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Search through our curated guides and FAQs to master your finances.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.getTextColor(context, opacity: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTutorialItem(BuildContext context, String title, String subtitle,
      IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppTheme.getDividerColor(context),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.6),
                fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppTheme.getTextColor(context, opacity: 0.3)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tutorial: $title is coming soon!')),
          );
        },
      ),
    ).animate().slideX(begin: 0.1, end: 0).fadeIn();
  }

  Widget _buildFAQCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.getDividerColor(context),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildFAQItem(
            context,
            'Is my data stored in the cloud?',
            'No, all your financial records are stored strictly on your local device. We value your privacy above all else.',
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildFAQItem(
            context,
            'How can I back up my data?',
            'You can create manual backups by exporting your data to CSV or Excel in the Settings > Backup & Restore section.',
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildFAQItem(
            context,
            'Is the application free to use?',
            'Yes! Master Budget Tracking is completely free for personal use, including invoicing and account management.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.getTextColor(context))),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Text(answer,
            style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.6),
                fontSize: 13,
                height: 1.5)),
      ],
    );
  }

  Widget _buildContactSupport(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text('Still have questions?',
              style: TextStyle(
                  color: AppTheme.getTextColor(context, opacity: 0.6),
                  fontSize: 14)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email_outlined, size: 18),
            label: const Text('Contact Support Team',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
