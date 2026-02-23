#!/usr/bin/env python3
"""
Script to replace common hardcoded colors with theme-aware equivalents.
Run from the project root directory.
"""

import re
import os
from pathlib import Path

# Base directory
BASE_DIR = r'e:\Kalpa\ViralMove\Projects\BudgetTrackingApp\budget_tracking_app\lib\features'

# Common replacements
REPLACEMENTS = [
    # Text colors
    (r'color:\s*Colors\.black87', 'color: AppTheme.getTextColor(context)'),
    (r'color:\s*Colors\.black54', 'color: AppTheme.getTextColor(context, opacity: 0.6)'),
    (r'color:\s*Colors\.black45', 'color: AppTheme.getTextColor(context, opacity: 0.5)'),
    (r'color:\s*Colors\.black38', 'color: AppTheme.getTextColor(context, opacity: 0.4)'),
    (r'color:\s*Colors\.black26', 'color: AppTheme.getTextColor(context, opacity: 0.3)'),
    (r'color:\s*Colors\.black12', 'color: AppTheme.getTextColor(context, opacity: 0.15)'),
    
    # Grey colors (secondary text)
    (r'color:\s*Colors\.grey\[600\]', 'color: AppTheme.getTextColor(context, isSecondary: true)'),
    (r'color:\s*Colors\.grey\[500\]', 'color: AppTheme.getTextColor(context, isSecondary: true, opacity: 0.9)'),
    (r'color:\s*Colors\.grey\[400\]', 'color: AppTheme.getTextColor(context, isSecondary: true, opacity: 0.7)'),
    (r'color:\s*Colors\.grey\[300\]', 'color: AppTheme.getTextColor(context, isSecondary: true, opacity: 0.5)'),
    (r'color:\s*Colors\.grey\[200\]', 'color: AppTheme.getBorderColor(context, opacity: 0.3)'),
    (r'color:\s*Colors\.grey\[100\]', 'color: AppTheme.getDividerColor(context)'),
    
    # White colors on colored backgrounds (keep as is for contrast)
    # Colors.white -> leave if on primary color background
    
    # Background/Surface colors
    (r'backgroundColor:\s*Colors\.white(?![,.])', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor'),
    (r'color:\s*Colors\.white(?=\s*[,;])', 'color: AppTheme.getSurfaceColor(context)'),
    
    # Dividers and borders
    (r'Colors\.black\.withOpacity\(0\.05\)', 'AppTheme.getDividerColor(context)'),
    (r'Colors\.black\.withOpacity\(0\.03\)', 'AppTheme.getDividerColor(context)'),
    (r'Colors\.grey\.withOpacity\(0\.1\)', 'AppTheme.getBorderColor(context)'),
    (r'Colors\.grey\.withOpacity\(0\.2\)', 'AppTheme.getBorderColor(context)'),
]

def process_file(file_path):
    """Process a single Dart file."""
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
            print(f"[OK] {file_path.relative_to(BASE_DIR)}: {changes} replacements")
            return changes
        
        return 0
            
    except Exception as e:
        print(f"[ERROR] {file_path}: {e}")
        return 0

def main():
    """Process all page and screen files."""
    total_changes = 0
    files_processed = 0
    
    # Find all _page.dart and _screen.dart files
    for pattern in ['**/*_page.dart', '**/*_screen.dart']:
        for file_path in Path(BASE_DIR).glob(pattern):
            changes = process_file(file_path)
            if changes > 0:
                total_changes += changes
                files_processed += 1
    
    print(f"\n{files_processed} files updated with {total_changes} total changes")

if __name__ == '__main__':
    main()
