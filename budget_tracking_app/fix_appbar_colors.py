#!/usr/bin/env python3
"""
Script to fix remaining theme issues:
1. AppBar iconTheme colors
2. Tab colors  
3. Floating action buttons
"""

import re
import os
from pathlib import Path

BASE_DIR = r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features'

# Replacements for AppBars and special widgets
REPLACEMENTS = [
    # AppBars with white icon theme - keep white on colored AppBars
    # (r'iconTheme:\s*const\s*IconThemeData\(color:\s*Colors\.white\)', 
    #  'iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white)'),
    
    # Tab colors - adapt to theme
    (r'indicatorColor:\s*Colors\.white', 
     'indicatorColor: Theme.of(context).colorScheme.onPrimary'),
    (r'labelColor:\s*Colors\.white(?![,\.])',
     'labelColor: Theme.of(context).colorScheme.onPrimary'),
    (r'unselectedLabelColor:\s*Colors\.white70',
     'unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)'),
     
    # Remaining grey colors
    (r'color:\s*Colors\.grey\b(?!\[|\.|withOpacity)',
     'color: AppTheme.getTextColor(context, isSecondary: true)'),
    (r'Colors\.grey\.shade\d+',
     'AppTheme.getBorderColor(context)'),
]

def process_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        changes = 0
        
        for pattern, replacement in REPLACEMENTS:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                changes += re.subn(pattern, replacement, content)[1]
                content = new_content
        
        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] {file_path.name}: {changes} replacements")
            return changes
        
        return 0
            
    except Exception as e:
        print(f"[ERROR] {file_path.name}: {e}")
        return 0

def main():
    total_changes = 0
    files_processed = 0
    
    for pattern in ['**/*_page.dart', '**/*_screen.dart']:
        for file_path in Path(BASE_DIR).glob(pattern):
            changes = process_file(file_path)
            if changes > 0:
                total_changes += changes
                files_processed += 1
    
    print(f"\n{files_processed} files updated with {total_changes} total changes")

if __name__ == '__main__':
    main()
