import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Privacy Policy',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Data Protection & Transparency'),
            _buildCard(context, [
              _buildPolicyText(
                context,
                'Your privacy is our priority. This application is designed to keep your financial data strictly on your device.',
                isBold: true,
              ),
              const SizedBox(height: 16),
              _buildPolicyText(
                context,
                '1. Local Storage: All expenses, accounts, and financial records are stored locally in an encrypted SQLite database. We do not transmit this data to any external servers without your explicit action (like exporting to CSV).',
              ),
              const SizedBox(height: 12),
              _buildPolicyText(
                context,
                '2. Authentication: We use Firebase Auth for secure login. Only your profile information (Name, Email, Profile Picture) is synced with Google/Firebase services to manage your account access.',
              ),
              const SizedBox(height: 12),
              _buildPolicyText(
                context,
                '3. Security Measures: We support Biometric Authentication (Fingerprint/FaceID) to ensure only you can access your financial hub.',
              ),
              const SizedBox(height: 12),
              _buildPolicyText(
                context,
                '4. Data Retention: Your data is kept as long as the application remains installed. You can delete all your data at any time by clearing the application storage or choosing the delete option in data settings.',
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Third-Party Services'),
            _buildCard(context, [
              _buildBulletPoint(
                  context, 'Firebase: Used for secure user authentication.'),
              _buildBulletPoint(context,
                  'Google Sign-In: Optional method for simplified account creation.'),
              _buildBulletPoint(context,
                  'Device Permissions: We only request access to Storage (for backups) and Biometrics (for security).'),
            ]),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Last Updated: February 2026',
                style: TextStyle(
                    color: AppTheme.getTextColor(context, opacity: 0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.getTextColor(context, opacity: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPolicyText(BuildContext context, String text,
      {bool isBold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isBold
            ? AppTheme.getTextColor(context)
            : AppTheme.getTextColor(context, opacity: 0.6),
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          Expanded(child: _buildPolicyText(context, text)),
        ],
      ),
    );
  }
}
