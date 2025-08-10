#!/usr/bin/env python3
"""
============================================================================
DUPLICATE FILE ROLLBACK UTILITY
============================================================================

DESCRIPTION:
Rollback utility for duplicate file operations. Reverses actions performed
by the duplicate_executor.py script using the rollback JSON data.

USAGE:
python rollback_duplicates.py <rollback_file.json> [--dry-run] [--verbose]

SAFETY FEATURES:
- Dry run mode to preview rollback actions
- Validation of rollback data integrity  
- Selective rollback (by timestamp or operation type)
- Comprehensive logging of rollback operations

Author: claude.ai (Rollback utility for duplicate file management)
Date: August 2025
============================================================================
"""

import argparse
import json
import logging
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class RollbackStats:
    """Statistics for rollback operations."""
    total_operations: int = 0
    successful_rollbacks: int = 0
    failed_rollbacks: int = 0
    skipped_operations: int = 0


class DuplicateRollback:
    """Utility class for rolling back duplicate file operations."""
    
    def __init__(self, dry_run: bool = False, verbose: bool = False):
        self.dry_run = dry_run
        self.verbose = verbose
        self.stats = RollbackStats()
        
        # Setup logging
        self._setup_logging()
    
    def _setup_logging(self):
        """Initialize logging configuration."""
        log_level = logging.DEBUG if self.verbose else logging.INFO
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        formatter = logging.Formatter('%(levelname)s - %(message)s')
        console_handler.setFormatter(formatter)
        
        # Configure logger
        self.logger = logging.getLogger('DuplicateRollback')
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(console_handler)
        
        # Log session start
        self.logger.info("=" * 50)
        self.logger.info("Duplicate File Rollback Utility")
        self.logger.info(f"Mode: {'DRY RUN' if self.dry_run else 'EXECUTE'}")
        self.logger.info("=" * 50)
    
    def load_rollback_data(self, rollback_file: Path) -> Optional[Dict]:
        """Load and validate rollback data from JSON file."""
        if not rollback_file.exists():
            self.logger.error(f"Rollback file not found: {rollback_file}")
            return None
        
        try:
            with open(rollback_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Validate required fields
            required_fields = ['timestamp', 'operations']
            for field in required_fields:
                if field not in data:
                    self.logger.error(f"Missing required field in rollback data: {field}")
                    return None
            
            self.logger.info(f"Loaded rollback data with {len(data['operations'])} operations")
            self.logger.info(f"Original session: {data['timestamp']}")
            if data.get('dry_run'):
                self.logger.info("Original session was a dry run")
            
            return data
            
        except json.JSONDecodeError as e:
            self.logger.error(f"Invalid JSON in rollback file: {e}")
            return None
        except Exception as e:
            self.logger.error(f"Error reading rollback file: {e}")
            return None
    
    def rollback_delete_operation(self, operation: Dict) -> bool:
        """Rollback a delete operation by restoring from backup."""
        original_path = Path(operation['original_path'])
        backup_path = Path(operation['backup_path'])
        
        if self.dry_run:
            self.logger.info(f"[DRY-RUN] Would restore deleted file: {backup_path} -> {original_path}")
            return True
        
        try:
            if not backup_path.exists():
                self.logger.error(f"Backup file not found: {backup_path}")
                return False
            
            if original_path.exists():
                self.logger.warning(f"Target file already exists: {original_path}")
                return False
            
            # Create parent directory if needed
            original_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Restore file from backup
            shutil.copy2(backup_path, original_path)
            
            self.logger.info(f"Restored deleted file: {original_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to restore {original_path}: {e}")
            return False
    
    def rollback_link_operation(self, operation: Dict) -> bool:
        """Rollback a link operation by removing link and restoring original."""
        target_path = Path(operation['target_path'])
        backup_path = Path(operation['backup_path'])
        operation_type = operation['operation_type']
        
        if self.dry_run:
            self.logger.info(f"[DRY-RUN] Would rollback {operation_type}: remove link {target_path}, restore from {backup_path}")
            return True
        
        try:
            # Remove the link
            if target_path.exists() or target_path.is_symlink():
                target_path.unlink()
            else:
                self.logger.warning(f"Link file not found: {target_path}")
            
            # Restore original file from backup if backup exists
            if backup_path.exists():
                shutil.copy2(backup_path, target_path)
                self.logger.info(f"Rollback {operation_type}: restored {target_path}")
                return True
            else:
                self.logger.error(f"Backup file not found: {backup_path}")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to rollback {operation_type} for {target_path}: {e}")
            return False
    
    def rollback_operation(self, operation: Dict) -> bool:
        """Rollback a single operation."""
        operation_type = operation.get('operation_type', '')
        
        if operation_type == 'delete':
            return self.rollback_delete_operation(operation)
        elif operation_type in ['softlink', 'hardlink']:
            return self.rollback_link_operation(operation)
        else:
            self.logger.warning(f"Unknown operation type: {operation_type}")
            self.stats.skipped_operations += 1
            return False
    
    def execute_rollback(self, rollback_file: Path, 
                        operation_types: Optional[List[str]] = None,
                        after_timestamp: Optional[str] = None,
                        before_timestamp: Optional[str] = None) -> int:
        """Execute rollback operations."""
        # Load rollback data
        data = self.load_rollback_data(rollback_file)
        if not data:
            return 1
        
        operations = data['operations']
        
        # Filter operations if criteria specified
        if operation_types:
            operations = [op for op in operations if op.get('operation_type') in operation_types]
            self.logger.info(f"Filtered to {len(operations)} operations of types: {operation_types}")
        
        if after_timestamp:
            operations = [op for op in operations if op.get('timestamp', '') > after_timestamp]
            self.logger.info(f"Filtered to {len(operations)} operations after {after_timestamp}")
        
        if before_timestamp:
            operations = [op for op in operations if op.get('timestamp', '') < before_timestamp]
            self.logger.info(f"Filtered to {len(operations)} operations before {before_timestamp}")
        
        if not operations:
            self.logger.info("No operations to rollback")
            return 0
        
        self.stats.total_operations = len(operations)
        
        # Process operations in reverse order (LIFO)
        self.logger.info(f"Starting rollback of {len(operations)} operations...")
        
        for i, operation in enumerate(reversed(operations), 1):
            self.logger.info(f"Rollback {i}/{len(operations)}: {operation.get('operation_type')} - {operation.get('original_path')}")
            
            if self.rollback_operation(operation):
                self.stats.successful_rollbacks += 1
            else:
                self.stats.failed_rollbacks += 1
        
        # Show final statistics
        self.show_final_statistics()
        
        return 0 if self.stats.failed_rollbacks == 0 else 2
    
    def show_final_statistics(self):
        """Display final rollback statistics."""
        print("\n" + "=" * 50)
        print("ROLLBACK COMPLETE")
        print("=" * 50)
        print(f"\nSTATISTICS:")
        print(f"  Total operations: {self.stats.total_operations}")
        print(f"  Successful rollbacks: {self.stats.successful_rollbacks}")
        print(f"  Failed rollbacks: {self.stats.failed_rollbacks}")
        print(f"  Skipped operations: {self.stats.skipped_operations}")
        
        if self.dry_run:
            print(f"\nDRY RUN COMPLETE - No changes were made")
            print(f"Remove --dry-run flag to execute the rollback")
        
        print("\n" + "=" * 50)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Rollback duplicate file operations",
        epilog="""
Examples:
    python rollback_duplicates.py rollback.json --dry-run
    python rollback_duplicates.py rollback.json --verbose
    python rollback_duplicates.py rollback.json --operation-type delete
    python rollback_duplicates.py rollback.json --after 2025-08-10T10:00:00
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'rollback_file',
        type=Path,
        help='JSON file containing rollback data'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview rollback actions without executing them'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Show detailed output for all operations'
    )
    
    parser.add_argument(
        '--operation-type',
        action='append',
        choices=['delete', 'softlink', 'hardlink'],
        help='Only rollback specific operation types (can be used multiple times)'
    )
    
    parser.add_argument(
        '--after',
        type=str,
        help='Only rollback operations after this timestamp (ISO format)'
    )
    
    parser.add_argument(
        '--before',
        type=str,
        help='Only rollback operations before this timestamp (ISO format)'
    )
    
    args = parser.parse_args()
    
    # Create rollback utility and execute
    rollback = DuplicateRollback(dry_run=args.dry_run, verbose=args.verbose)
    return rollback.execute_rollback(
        args.rollback_file,
        operation_types=args.operation_type,
        after_timestamp=args.after,
        before_timestamp=args.before
    )


if __name__ == "__main__":
    sys.exit(main())
