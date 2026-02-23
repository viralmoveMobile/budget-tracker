#!/usr/bin/env python3
"""
Final comprehensive fix for all remaining const expression errors.
Removes 'const' keywords before widgets that use AppTheme methods.
"""

import re
from pathlib import Path

BASE_DIR = r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features'

def fix_const_expressions(file_path):
    """Remove const from widgets using AppTheme methods."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        lines = content.split('\n')
        new_lines = []
        
        for i, line in enumerate(lines):
            # If line contains 'const' and the next few lines contain AppTheme method calls
            if 'const ' in line and not line.strip().startswith('//'):
                # Check next 5 lines for AppTheme usage
                check_lines = '\n'.join(lines[i:min(i+10, len(lines))])
                if 'AppTheme.get' in check_lines and 'context' in check_lines:
                    # Remove 'const ' from this line
                    line = re.sub(r'\bconst\s+', '', line, count=1)
            
            new_lines.append(line)
        
        content = '\n'.join(new_lines)
        
        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
            
    except Exception as e:
        print(f"[ERROR] {file_path.name}: {e}")
        return False

def main():
    """Fix all files with const expression errors."""
    problem_files = [
        'analytics/presentation/pages/analytics_dashboard_page.dart',
        'auth/presentation/pages/login_page.dart',
        'cash_book/presentation/pages/cash_book_page.dart',
        'exchange/presentation/pages/currency_converter_page.dart',
        'holidays/presentation/pages/holiday_list_page.dart',
        'home/presentation/pages/home_page.dart',
        'invoices/presentation/pages/invoice_list_page.dart',
        'sharing/presentation/pages/shared_data_hub_page.dart',
        'sharing/presentation/pages/sharing_overview_page.dart',
    ]
    
    fixed = 0
    for file_rel in problem_files:
        file_path = Path(BASE_DIR) / file_rel
        if file_path.exists():
            if fix_const_expressions(file_path):
                print(f"[OK] {file_path.name}")
                fixed += 1
    
    print(f"\n{fixed} files fixed")

if __name__ == '__main__':
    main()
