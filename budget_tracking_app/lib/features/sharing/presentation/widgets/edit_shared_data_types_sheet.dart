import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class EditSharedDataTypesSheet extends StatefulWidget {
  final String memberEmail;
  final List<String> currentDataTypes;
  final Function(List<String>) onSave;

  const EditSharedDataTypesSheet({
    super.key,
    required this.memberEmail,
    required this.currentDataTypes,
    required this.onSave,
  });

  @override
  State<EditSharedDataTypesSheet> createState() =>
      _EditSharedDataTypesSheetState();
}

class _EditSharedDataTypesSheetState extends State<EditSharedDataTypesSheet> {
  late Set<String> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.currentDataTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.gapLg,
          Text(
            'Edit Shared Data',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'Select which data types to share with ${widget.memberEmail}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          AppSpacing.gapXl,
          _buildDataTypeOption(
            'Expenses',
            'expenses',
            Icons.receipt_long_rounded,
            AppTheme.expensesColor,
            'Share your expense transactions',
          ),
          _buildDataTypeOption(
            'Cash Book',
            'cash_book',
            Icons.book_rounded,
            AppTheme.accountsColor,
            'Share cash book transactions',
          ),
          _buildDataTypeOption(
            'Budgets',
            'budgets',
            Icons.savings_rounded,
            AppTheme.primaryColor,
            'Share budget limits',
          ),
          AppSpacing.gapXl,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedTypes.isEmpty
                      ? null
                      : () {
                          widget.onSave(_selectedTypes.toList());
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r12),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
        ],
      ),
    );
  }

  Widget _buildDataTypeOption(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    final isSelected = _selectedTypes.contains(value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedTypes.add(value);
            } else {
              _selectedTypes.remove(value);
            }
          });
        },
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            AppSpacing.gapMd,
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32, top: 4),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        activeColor: color,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
