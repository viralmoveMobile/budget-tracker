import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/holiday_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/holiday.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class AddHolidaySheet extends ConsumerStatefulWidget {
  const AddHolidaySheet({super.key});

  @override
  ConsumerState<AddHolidaySheet> createState() => _AddHolidaySheetState();
}

class _AddHolidaySheetState extends ConsumerState<AddHolidaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final holiday = Holiday(
        id: const Uuid().v4(),
        name: _nameController.text,
        startDate: _startDate,
        endDate: _endDate,
        totalBudget: double.parse(_budgetController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ref.read(holidayListProvider.notifier).addHoliday(holiday);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context, opacity: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Plan New Holiday',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXxl,
              _buildModernTextField(
                controller: _nameController,
                label: 'Holiday Name',
                icon: Icons.beach_access_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _selectDateRange(context),
                borderRadius: BorderRadius.circular(AppSpacing.r16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context, opacity: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          color: AppTheme.primaryColor),
                      AppSpacing.gapLg,
                      Text(
                        '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextColor(context)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _budgetController,
                label: 'Total Budget Limit',
                icon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Budget is required';
                  if (double.tryParse(val) == null)
                    return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              AppSpacing.gapXxl,
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r16),
                  ),
                ),
                child: const Text('Create Plan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: AppTheme.getTextColor(context, isSecondary: true)),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.getBorderColor(context, opacity: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: AppTheme.dangerColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          borderSide: BorderSide(color: AppTheme.dangerColor, width: 2),
        ),
      ),
    );
  }
}
