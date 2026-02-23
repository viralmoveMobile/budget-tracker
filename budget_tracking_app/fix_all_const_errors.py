#!/usr/bin/env python3
"""
Comprehensive fix for all remaining const expression errors.
This will remove 'const' from any widget that uses AppTheme methods.
"""

import re
from pathlib import Path

BASE_DIR = r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features'

def fix_file(file_path):
    """Fix const issues in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Remove 'const' before any Text/Icon/TextStyle/Container/Column/Expanded that contains AppTheme methods
        # This is a comprehensive fix that removes const from entire widget trees
        patterns = [
            # Remove const from widget constructors with AppTheme usage
            (r'const\s+(Text|Icon|TextStyle|Container|Column|Row|Expanded|Center|SizedBox|Padding)\s*\(([^;]*?AppTheme\.[a-zA-Z]+\([^)]*context[^;]*?\))',
             r'\1(\2'),
        ]
        
        for pattern, replacement in patterns:
            # Use DOTALL to match across lines
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        
        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] {file_path.name}")
            return True
        
        return False
            
    except Exception as e:
        print(f"[ERROR] {file_path.name}: {e}")
        return False

def main():
    """Fix all files with errors."""
    problem_files = [
        'exchange/presentation/pages/currency_converter_page.dart',
        'expenses/presentation/pages/expense_list_screen.dart',
        'holidays/presentation/pages/holiday_detail_page.dart',
        'holidays/presentation/pages/holiday_list_page.dart',
        'home/presentation/pages/home_page.dart',
        'invoices/presentation/pages/invoice_list_page.dart',
        'invoices/presentation/pages/invoice_settings_page.dart',
        'invoices/presentation/pages/create_invoice_page.dart',
        'sharing/presentation/pages/shared_data_hub_page.dart',
        'sharing/presentation/pages/sharing_overview_page.dart',
    ]
    
    fixed = 0
    for file_rel in problem_files:
        file_path = Path(BASE_DIR) / file_rel
        if file_path.exists():
            if fix_file(file_path):
                fixed += 1
    
    print(f"\n{fixed} files fixed")

if __name__ == '__main__':
    main()
