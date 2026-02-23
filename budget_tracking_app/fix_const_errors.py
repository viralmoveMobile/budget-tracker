#!/usr/bin/env python3
"""
Fix const keywords where theme methods are used.
These methods require runtime context, so const must be removed.
"""

import re
from pathlib import Path

BASE_DIR = r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features'

def fix_const_issues(file_path):
    """Remove const where AppTheme methods are used."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Pattern: const Text/Icon/TextStyle using AppTheme methods
        # Replace 'const Text(' with 'Text(' when followed by AppTheme method call
        patterns = [
            (r'const (Text|Icon|TextStyle)\((.*?AppTheme\.(getTextColor|getSurfaceColor|getBackgroundColor|getDividerColor|getBorderColor)\(context.*?\))',
             r'\1(\2'),
        ]
        
        for pattern, replacement in patterns:
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        
        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            changes = len(re.findall(r'AppTheme\.get\w+Color\(context', content))
            print(f"[OK] {file_path.name}: Fixed const issues")
            return True
        
        return False
            
    except Exception as e:
        print(f"[ERROR] {file_path.name}: {e}")
        return False

def main():
    files_fixed = 0
    
    # Target specific files that have the issue
    problem_files = [
        'sharing/presentation/pages/sharing_overview_page.dart',
        'sharing/presentation/pages/shared_data_hub_page.dart',
        'settings/presentation/pages/settings_overview_page.dart',
        'settings/presentation/pages/help_support_page.dart',
        'my_account/presentation/pages/profile_page.dart',
        'holidays/presentation/pages/holiday_detail_page.dart',
        'expenses/presentation/pages/expense_list_screen.dart',
        'data_management/presentation/pages/data_management_page.dart',
        'cash_book/presentation/pages/cash_book_page.dart',
        'analytics/presentation/pages/analytics_dashboard_page.dart',
    ]
    
    for file_rel in problem_files:
        file_path = Path(BASE_DIR) / file_rel
        if file_path.exists():
            if fix_const_issues(file_path):
                files_fixed += 1
    
    print(f"\n{files_fixed} files fixed")

if __name__ == '__main__':
    main()
