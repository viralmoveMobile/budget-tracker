#!/usr/bin/env python3
"""Quick fix for final 5 errors."""
import re
from pathlib import Path

def remove_const_from_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Simple approach: remove const from any line that has AppTheme in nearby context
    lines = content.split('\n')
    new_lines = []
    
    for i, line in enumerate(lines):
        if 'const ' in line and 'AppTheme' not in line:
            # Check next 10 lines for AppTheme
            window = '\n'.join(lines[i:min(i+10, len(lines))])
            if 'AppTheme.get' in window and 'context' in window:
                line = re.sub(r'\bconst\s+', '', line, count=1)
        new_lines.append(line)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))

# Fix remaining files
files = [
    r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features\accounts\presentation\pages\accounts_overview_page.dart',
    r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features\sharing\presentation\pages\sharing_overview_page.dart',
]

for f in files:
    if Path(f).exists():
        remove_const_from_file(f)
        print(f"[OK] {Path(f).name}")
