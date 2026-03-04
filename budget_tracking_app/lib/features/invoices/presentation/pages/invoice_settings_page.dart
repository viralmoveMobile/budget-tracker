import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice_settings.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class InvoiceSettingsPage extends ConsumerStatefulWidget {
  const InvoiceSettingsPage({super.key});

  @override
  ConsumerState<InvoiceSettingsPage> createState() =>
      _InvoiceSettingsPageState();
}

class _InvoiceSettingsPageState extends ConsumerState<InvoiceSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(invoiceSettingsProvider).asData?.value;
      if (settings != null) {
        _companyNameController.text = settings.companyName;
        _companyAddressController.text = settings.companyAddress;
        _companyEmailController.text = settings.companyEmail;
        _companyPhoneController.text = settings.companyPhone;
        _taxRateController.text = settings.defaultTaxRate.toString();
        _hourlyRateController.text = settings.defaultHourlyRate.toString();
        _bankNameController.text = settings.bankName;
        _accountNameController.text = settings.accountName;
        _accountNumberController.text = settings.accountNumber;
        _routingNumberController.text = settings.routingNumber ?? '';
      }
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _taxRateController.dispose();
    _hourlyRateController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newSettings = InvoiceSettings(
        companyName: _companyNameController.text,
        companyAddress: _companyAddressController.text,
        companyEmail: _companyEmailController.text,
        companyPhone: _companyPhoneController.text,
        defaultTaxRate: double.tryParse(_taxRateController.text) ?? 0.0,
        defaultHourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
        bankName: _bankNameController.text,
        accountName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        routingNumber: _routingNumberController.text.isEmpty
            ? null
            : _routingNumberController.text,
      );

      ref.read(invoiceSettingsProvider.notifier).updateSettings(newSettings);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: const AppAppBar(
        title: Text('Invoice Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('BUSINESS DETAILS'),
              _buildCard([
                _buildTextField('Company Name', _companyNameController,
                    Icons.business_rounded),
                _buildTextField('Address', _companyAddressController,
                    Icons.location_on_rounded,
                    maxLines: 2),
                _buildTextField(
                    'Email', _companyEmailController, Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress),
                _buildTextField(
                    'Phone', _companyPhoneController, Icons.phone_rounded,
                    keyboardType: TextInputType.phone),
              ]),
              AppSpacing.gapXxl,
              _buildSectionTitle('TAX & RATES'),
              _buildCard([
                _buildTextField('Default VAT / Tax Rate (%)',
                    _taxRateController, Icons.percent_rounded,
                    keyboardType: TextInputType.number),
                _buildTextField('Default Hourly Rate', _hourlyRateController,
                    Icons.timer_rounded,
                    keyboardType: TextInputType.number),
              ]),
              AppSpacing.gapXxl,
              _buildSectionTitle('BANK INFORMATION'),
              _buildCard([
                _buildTextField('Bank Name', _bankNameController,
                    Icons.account_balance_rounded),
                _buildTextField('Account Name', _accountNameController,
                    Icons.person_rounded),
                _buildTextField('Account Number', _accountNumberController,
                    Icons.numbers_rounded),
                _buildTextField('Routing / IBAN (Optional)',
                    _routingNumberController, Icons.tag_rounded),
              ]),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r16)),
                  elevation: 0,
                ),
                child: const Text('Save Settings',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: AppSpacing.cardPadding,
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          filled: true,
          fillColor: AppTheme.backgroundLight.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}
