#!/usr/bin/env python3
"""
============================================================================
DUPLICATE FILE ACTION EXECUTOR (Python Version)
============================================================================

DESCRIPTION:
Executes actions defined in your duplicates CSV/ODS data.
Supports: soft links, hard links, file deletion with comprehensive safety checks.

USAGE:
1. Export your spreadsheet to CSV format (keep headers)
2. python duplicate_executor.py duplicates.csv [--dry-run] [--verbose]

SAFETY FEATURES:
- Dry run mode to preview all actions
- Comprehensive file existence and permission checks
- Backup creation for destructive operations
- Detailed logging of all operations
- Rollback capability for link operations
- Robust CSV parsing with proper quote handling

Author: claude.ai (Enhanced Python version for Czkawka duplicate management)
Date: August 2025
============================================================================
"""

import argparse
import csv
import json
import logging
import os
import shutil
import stat
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union
from dataclasses import dataclass, asdict
from enum import Enum


class ActionType(Enum):
    """Supported duplicate file actions."""
    SOFTLINK_ORIGINAL = "SOFTLINK_ORIGINAL"
    SOFTLINK_DUPLICATE = "SOFTLINK_DUPLICATE"
    HARDLINK_ORIGINAL = "HARDLINK_ORIGINAL"
    HARDLINK_DUPLICATE = "HARDLINK_DUPLICATE"
    DELETE_ORIGINAL = "DELETE_ORIGINAL"
    DELETE_DUPLICATE = "DELETE_DUPLICATE"
    DELETE_BOTH = "DELETE_BOTH"


class ValidationResult(Enum):
    """File validation results."""
    SUCCESS = 0
    ERROR = 1
    CROSS_DEVICE = 2


@dataclass
class DuplicateEntry:
    """Represents a duplicate file entry from CSV."""
    row_num: int
    original_folder: str
    original_file: str
    duplicate_folder: str
    duplicate_file: str
    size: str
    hash_value: str
    keep_orig: str
    keep_dup: str
    action: str
    notes: str = ""
    
    @property
    def original_path(self) -> Path:
        return Path(self.original_folder) / self.original_file
    
    @property
    def duplicate_path(self) -> Path:
        return Path(self.duplicate_folder) / self.duplicate_file


@dataclass
class OperationStats:
    """Statistics for file operations."""
    total_rows: int = 0
    processed_rows: int = 0
    softlinks_created: int = 0
    hardlinks_created: int = 0
    files_deleted: int = 0
    errors: int = 0
    skipped: int = 0


@dataclass
class RollbackEntry:
    """Entry for rollback operations."""
    timestamp: str
    operation_type: str
    original_path: str
    target_path: str
    backup_path: str
    status: str = "active"


class DuplicateFileExecutor:
    """Main class for executing duplicate file actions."""
    
    def __init__(self, dry_run: bool = False, verbose: bool = False):
        self.dry_run = dry_run
        self.verbose = verbose
        self.stats = OperationStats()
        
        # Setup directories
        self.base_dir = Path.home() / "tmp" / "2delete" / "duplicatesHandling"
        self.backup_dir = self.base_dir / "duplicate_backups" / datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.base_dir / "duplicate_actions.log"
        self.rollback_file = self.base_dir / "duplicate_rollback.json"
        
        # Rollback entries
        self.rollback_entries: List[RollbackEntry] = []
        
        # Setup logging
        self._setup_logging()
        self._setup_directories()
    
    def _setup_logging(self):
        """Initialize logging configuration."""
        # Ensure base directory exists for logging
        self.base_dir.mkdir(parents=True, exist_ok=True)
        
        # Configure logging
        log_level = logging.DEBUG if self.verbose else logging.INFO
        
        # File handler
        file_handler = logging.FileHandler(self.log_file, mode='a', encoding='utf-8')
        file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        file_handler.setFormatter(file_formatter)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        console_formatter = logging.Formatter('%(levelname)s - %(message)s')
        console_handler.setFormatter(console_formatter)
        
        # Configure logger
        self.logger = logging.getLogger('DuplicateExecutor')
        self.logger.setLevel(logging.DEBUG)
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)
        
        # Log session start
        self.logger.info("=" * 60)
        self.logger.info("Duplicate File Action Executor - Session Start")
        self.logger.info(f"Mode: {'DRY RUN' if self.dry_run else 'EXECUTE'}")
        self.logger.info(f"Verbose: {self.verbose}")
    
    def _setup_directories(self):
        """Create necessary directories."""
        self.logger.info(f"Duplicates handling directory: {self.base_dir}")
        
        if not self.dry_run:
            self.backup_dir.mkdir(parents=True, exist_ok=True)
            self.logger.info(f"Backup directory created: {self.backup_dir}")
        else:
            self.logger.info("DRY RUN mode - backup directory will not be created")
    
    def check_prerequisites(self) -> bool:
        """Check system prerequisites."""
        self.logger.info("Checking system prerequisites...")
        
        # Check if we can create files in the base directory
        try:
            test_file = self.base_dir / "test_write"
            test_file.touch()
            test_file.unlink()
        except (PermissionError, OSError) as e:
            self.logger.error(f"Cannot write to handling directory {self.base_dir}: {e}")
            return False
        
        # Check Python version
        if sys.version_info < (3, 6):
            self.logger.error(f"Python 3.6+ required, found {sys.version}")
            return False
        
        self.logger.info("Prerequisites check passed")
        return True
    
    def validate_file_paths(self, entry: DuplicateEntry, action: ActionType) -> ValidationResult:
        """Validate file paths and permissions."""
        orig_path = entry.original_path
        dup_path = entry.duplicate_path
        
        # Check file existence based on action requirements
        try:
            if action in [ActionType.DELETE_ORIGINAL, ActionType.SOFTLINK_ORIGINAL, ActionType.HARDLINK_ORIGINAL]:
                if not orig_path.exists():
                    self.logger.error(f"Original file not found: {orig_path}")
                    return ValidationResult.ERROR
                if not dup_path.exists():
                    self.logger.error(f"Duplicate file not found: {dup_path}")
                    return ValidationResult.ERROR
            
            elif action in [ActionType.DELETE_DUPLICATE, ActionType.SOFTLINK_DUPLICATE, ActionType.HARDLINK_DUPLICATE]:
                if not orig_path.exists():
                    self.logger.error(f"Original file not found: {orig_path}")
                    return ValidationResult.ERROR
                if not dup_path.exists():
                    self.logger.error(f"Duplicate file not found: {dup_path}")
                    return ValidationResult.ERROR
            
            elif action == ActionType.DELETE_BOTH:
                if not orig_path.exists() and not dup_path.exists():
                    self.logger.error(f"Neither file exists: {orig_path}, {dup_path}")
                    return ValidationResult.ERROR
            
            # Check write permissions for directories
            if orig_path.exists() and not os.access(orig_path.parent, os.W_OK):
                self.logger.error(f"No write permission for directory: {orig_path.parent}")
                return ValidationResult.ERROR
            
            if dup_path.exists() and not os.access(dup_path.parent, os.W_OK):
                self.logger.error(f"No write permission for directory: {dup_path.parent}")
                return ValidationResult.ERROR
            
            # For hard links, check if files are on same filesystem
            if action in [ActionType.HARDLINK_ORIGINAL, ActionType.HARDLINK_DUPLICATE]:
                try:
                    orig_stat = orig_path.stat()
                    dup_stat = dup_path.parent.stat()
                    
                    if orig_stat.st_dev != dup_stat.st_dev:
                        self.logger.warning(f"Files on different filesystems, hard link not possible: {orig_path} <-> {dup_path}")
                        return ValidationResult.CROSS_DEVICE
                except OSError as e:
                    self.logger.error(f"Cannot check filesystem info: {e}")
                    return ValidationResult.ERROR
            
        except OSError as e:
            self.logger.error(f"File system error during validation: {e}")
            return ValidationResult.ERROR
        
        return ValidationResult.SUCCESS
    
    def create_backup(self, file_path: Path, backup_name: str) -> bool:
        """Create a backup of a file."""
        if self.dry_run:
            self.logger.info(f"[DRY-RUN] Would backup: {file_path} -> {self.backup_dir}/{backup_name}")
            return True
        
        if not file_path.exists():
            return True  # Nothing to backup
        
        try:
            backup_path = self.backup_dir / backup_name
            shutil.copy2(file_path, backup_path)
            self.logger.info(f"Backup created: {backup_name}")
            return True
        except (OSError, shutil.Error) as e:
            self.logger.error(f"Failed to create backup for {file_path}: {e}")
            return False
    
    def execute_soft_link(self, source_file: Path, target_file: Path, action_type: str) -> bool:
        """Create a soft link."""
        if self.dry_run:
            self.logger.info(f"[DRY-RUN] Would create soft link: {target_file} -> {source_file}")
            return True
        
        try:
            # Create backup of target before replacing with link
            backup_name = f"softlink_{target_file.name}_{datetime.now().strftime('%H%M%S')}"
            if not self.create_backup(target_file, backup_name):
                return False
            
            # Remove target and create soft link
            if target_file.exists():
                target_file.unlink()
            
            target_file.symlink_to(source_file)
            
            # Log rollback entry
            rollback_entry = RollbackEntry(
                timestamp=datetime.now().isoformat(),
                operation_type="softlink",
                original_path=str(source_file),
                target_path=str(target_file),
                backup_path=str(self.backup_dir / backup_name)
            )
            self.rollback_entries.append(rollback_entry)
            
            self.logger.info(f"Soft link created: {target_file} -> {source_file}")
            self.stats.softlinks_created += 1
            return True
            
        except OSError as e:
            self.logger.error(f"Failed to create soft link {target_file} -> {source_file}: {e}")
            # Try to restore from backup if it exists
            backup_path = self.backup_dir / backup_name
            if backup_path.exists():
                try:
                    shutil.copy2(backup_path, target_file)
                    self.logger.info("Restored target file from backup")
                except Exception as restore_error:
                    self.logger.error(f"Failed to restore backup: {restore_error}")
            return False
    
    def execute_hard_link(self, source_file: Path, target_file: Path, action_type: str) -> bool:
        """Create a hard link."""
        if self.dry_run:
            self.logger.info(f"[DRY-RUN] Would create hard link: {target_file} -> {source_file}")
            return True
        
        try:
            # Create backup of target before replacing with link
            backup_name = f"hardlink_{target_file.name}_{datetime.now().strftime('%H%M%S')}"
            if not self.create_backup(target_file, backup_name):
                return False
            
            # Remove target and create hard link
            if target_file.exists():
                target_file.unlink()
            
            target_file.hardlink_to(source_file)
            
            # Log rollback entry
            rollback_entry = RollbackEntry(
                timestamp=datetime.now().isoformat(),
                operation_type="hardlink",
                original_path=str(source_file),
                target_path=str(target_file),
                backup_path=str(self.backup_dir / backup_name)
            )
            self.rollback_entries.append(rollback_entry)
            
            self.logger.info(f"Hard link created: {target_file} -> {source_file}")
            self.stats.hardlinks_created += 1
            return True
            
        except OSError as e:
            self.logger.error(f"Failed to create hard link {target_file} -> {source_file}: {e}")
            # Try to restore from backup if it exists
            backup_path = self.backup_dir / backup_name
            if backup_path.exists():
                try:
                    shutil.copy2(backup_path, target_file)
                    self.logger.info("Restored target file from backup")
                except Exception as restore_error:
                    self.logger.error(f"Failed to restore backup: {restore_error}")
            return False
    
    def execute_delete(self, file_path: Path, file_type: str) -> bool:
        """Delete a file with backup."""
        if self.dry_run:
            self.logger.info(f"[DRY-RUN] Would delete {file_type}: {file_path}")
            return True
        
        if not file_path.exists():
            self.logger.warning(f"File to delete does not exist: {file_path}")
            return True  # Consider this successful since the end result is the same
        
        try:
            # Create backup before deletion
            backup_name = f"deleted_{file_path.name}_{datetime.now().strftime('%H%M%S')}"
            if not self.create_backup(file_path, backup_name):
                return False
            
            # Delete the file
            file_path.unlink()
            
            # Log rollback entry
            rollback_entry = RollbackEntry(
                timestamp=datetime.now().isoformat(),
                operation_type="delete",
                original_path=str(file_path),
                target_path="",
                backup_path=str(self.backup_dir / backup_name)
            )
            self.rollback_entries.append(rollback_entry)
            
            self.logger.info(f"Deleted {file_type}: {file_path}")
            self.stats.files_deleted += 1
            return True
            
        except OSError as e:
            self.logger.error(f"Failed to delete {file_type} {file_path}: {e}")
            return False
    
    def process_action(self, entry: DuplicateEntry) -> bool:
        """Process a single action from the CSV."""
        self.logger.info(f"Processing row {entry.row_num}: {entry.action}")
        
        try:
            action = ActionType(entry.action)
        except ValueError:
            if entry.action in ["", "REVIEW_NEEDED", "Action"]:
                self.logger.info(f"Row {entry.row_num}: No valid action ('{entry.action}') or needs review, skipping")
                self.stats.skipped += 1
                return True
            else:
                self.logger.warning(f"Unknown action '{entry.action}' for row {entry.row_num}, skipping")
                self.stats.skipped += 1
                return False
        
        # Validate file paths and permissions
        validation_result = self.validate_file_paths(entry, action)
        
        if validation_result == ValidationResult.ERROR:
            self.logger.error(f"Validation failed for row {entry.row_num}, skipping")
            self.stats.errors += 1
            return False
        elif validation_result == ValidationResult.CROSS_DEVICE:
            self.logger.warning(f"Cross-device hard link attempted, skipping row {entry.row_num}")
            self.stats.skipped += 1
            return False
        
        # Execute the appropriate action
        success = False
        orig_path = entry.original_path
        dup_path = entry.duplicate_path
        
        if action == ActionType.SOFTLINK_ORIGINAL:
            # Keep duplicate, link original to it
            success = self.execute_soft_link(dup_path, orig_path, "original")
        elif action == ActionType.SOFTLINK_DUPLICATE:
            # Keep original, link duplicate to it
            success = self.execute_soft_link(orig_path, dup_path, "duplicate")
        elif action == ActionType.HARDLINK_ORIGINAL:
            # Keep duplicate, hard link original to it
            success = self.execute_hard_link(dup_path, orig_path, "original")
        elif action == ActionType.HARDLINK_DUPLICATE:
            # Keep original, hard link duplicate to it
            success = self.execute_hard_link(orig_path, dup_path, "duplicate")
        elif action == ActionType.DELETE_ORIGINAL:
            # Delete original, keep duplicate
            success = self.execute_delete(orig_path, "original")
        elif action == ActionType.DELETE_DUPLICATE:
            # Delete duplicate, keep original
            success = self.execute_delete(dup_path, "duplicate")
        elif action == ActionType.DELETE_BOTH:
            # Delete both files
            success1 = self.execute_delete(orig_path, "original")
            success2 = self.execute_delete(dup_path, "duplicate")
            success = success1 and success2
        
        if success:
            self.stats.processed_rows += 1
        else:
            self.stats.errors += 1
        
        return success
    
    def parse_csv_file(self, csv_file: Path) -> List[DuplicateEntry]:
        """Parse CSV file and return list of duplicate entries."""
        if not csv_file.exists():
            self.logger.error(f"CSV file not found: {csv_file}")
            # Show available CSV files
            csv_files = list(csv_file.parent.glob("*.csv"))
            if csv_files:
                self.logger.info("Available CSV files:")
                for f in csv_files:
                    self.logger.info(f"  {f.name}")
            else:
                self.logger.info("No CSV files found in current directory")
            return []
        
        entries = []
        try:
            with open(csv_file, 'r', encoding='utf-8', newline='') as f:
                # Try to detect delimiter
                sample = f.read(1024)
                f.seek(0)
                
                dialect = csv.Sniffer().sniff(sample, delimiters=',;\t')
                reader = csv.reader(f, dialect)
                
                for row_num, row in enumerate(reader, 1):
                    # Skip header rows and summary rows
                    if row_num <= 2:
                        self.logger.info(f"Skipping row {row_num} (header/summary)")
                        continue
                    
                    # Skip empty rows
                    if not any(row) or len(row) < 10:
                        if any(row):  # Only warn if row has some content but insufficient columns
                            self.logger.warning(f"Row {row_num} has insufficient columns, skipping")
                        continue
                    
                    # Parse row (accounting for empty first column)
                    try:
                        entry = DuplicateEntry(
                            row_num=row_num,
                            original_folder=row[1].strip() if len(row) > 1 else "",
                            original_file=row[2].strip() if len(row) > 2 else "",
                            duplicate_folder=row[3].strip() if len(row) > 3 else "",
                            duplicate_file=row[4].strip() if len(row) > 4 else "",
                            size=row[5].strip() if len(row) > 5 else "",
                            hash_value=row[6].strip() if len(row) > 6 else "",
                            keep_orig=row[7].strip() if len(row) > 7 else "",
                            keep_dup=row[8].strip() if len(row) > 8 else "",
                            action=row[9].strip() if len(row) > 9 else "",
                            notes=row[10].strip() if len(row) > 10 else ""
                        )
                        
                        # Debug output
                        if self.verbose:
                            self.logger.debug(f"Row {row_num} parsed: orig='{entry.original_path}' dup='{entry.duplicate_path}' action='{entry.action}'")
                        
                        entries.append(entry)
                        self.stats.total_rows += 1
                        
                        # Progress indicator
                        if self.stats.total_rows % 50 == 0:
                            self.logger.info(f"Parsed {self.stats.total_rows} rows...")
                            
                    except Exception as e:
                        self.logger.error(f"Error parsing row {row_num}: {e}")
                        continue
                        
        except Exception as e:
            self.logger.error(f"Error reading CSV file {csv_file}: {e}")
            return []
        
        self.logger.info(f"Successfully parsed {len(entries)} entries from CSV")
        return entries
    
    def save_rollback_data(self):
        """Save rollback data to JSON file."""
        if not self.rollback_entries and not self.dry_run:
            return
        
        rollback_data = {
            "timestamp": datetime.now().isoformat(),
            "dry_run": self.dry_run,
            "backup_directory": str(self.backup_dir),
            "operations": [asdict(entry) for entry in self.rollback_entries]
        }
        
        try:
            with open(self.rollback_file, 'w', encoding='utf-8') as f:
                json.dump(rollback_data, f, indent=2, ensure_ascii=False)
            self.logger.info(f"Rollback data saved to: {self.rollback_file}")
        except Exception as e:
            self.logger.error(f"Failed to save rollback data: {e}")
    
    def show_final_statistics(self):
        """Display final processing statistics."""
        print("\n" + "=" * 60)
        print("DUPLICATE FILE PROCESSING COMPLETE")
        print("=" * 60)
        print(f"\nSTATISTICS:")
        print(f"  Total rows processed: {self.stats.total_rows}")
        print(f"  Successful operations: {self.stats.processed_rows}")
        print(f"  Soft links created: {self.stats.softlinks_created}")
        print(f"  Hard links created: {self.stats.hardlinks_created}")
        print(f"  Files deleted: {self.stats.files_deleted}")
        print(f"  Errors encountered: {self.stats.errors}")
        print(f"  Rows skipped: {self.stats.skipped}")
        
        if not self.dry_run:
            print(f"\nBACKUP AND RECOVERY:")
            print(f"  Handling directory: {self.base_dir}")
            print(f"  Backup directory: {self.backup_dir}")
            print(f"  Log file: {self.log_file}")
            print(f"  Rollback data: {self.rollback_file}")
            print(f"\nTo rollback operations:")
            print(f"  python rollback_duplicates.py {self.rollback_file}")
        else:
            print(f"\nDRY RUN COMPLETE - No changes were made")
            print(f"Remove --dry-run flag to execute the operations")
        
        print("\n" + "=" * 60)
    
    def execute(self, csv_file: Path) -> int:
        """Main execution method."""
        self.logger.info(f"Processing CSV file: {csv_file}")
        
        # Check prerequisites
        if not self.check_prerequisites():
            return 1
        
        # Parse CSV file
        entries = self.parse_csv_file(csv_file)
        if not entries:
            self.logger.error("No valid entries found in CSV file")
            return 1
        
        # Process all entries
        for entry in entries:
            self.process_action(entry)
        
        # Save rollback data
        self.save_rollback_data()
        
        # Show final statistics
        self.show_final_statistics()
        
        # Return appropriate exit code
        if self.stats.errors > 0:
            self.logger.warning(f"Completed with {self.stats.errors} errors")
            return 2
        else:
            self.logger.info("All operations completed successfully")
            return 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Execute duplicate file actions from CSV data",
        epilog="""
CSV Format Expected (with headers):
    Column A: (empty column)
    Column B: OriginalFolder
    Column C: OriginalFile  
    Column D: DuplicateFolder
    Column E: DuplicateFile
    Column F: Size
    Column G: Hash
    Column H: KeepOrig
    Column I: KeepDup
    Column J: Action
    Column K: NOTES

Supported Actions:
    SOFTLINK_ORIGINAL    - Keep duplicate, soft link original to it
    SOFTLINK_DUPLICATE   - Keep original, soft link duplicate to it
    HARDLINK_ORIGINAL    - Keep duplicate, hard link original to it  
    HARDLINK_DUPLICATE   - Keep original, hard link duplicate to it
    DELETE_ORIGINAL      - Delete original file, keep duplicate
    DELETE_DUPLICATE     - Delete duplicate file, keep original
    DELETE_BOTH          - Delete both files (use with caution)
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'csv_file',
        type=Path,
        help='CSV file containing duplicate file data'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview actions without executing them'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Show detailed output for all operations'
    )
    
    args = parser.parse_args()
    
    # Create executor and run
    executor = DuplicateFileExecutor(dry_run=args.dry_run, verbose=args.verbose)
    return executor.execute(args.csv_file)


if __name__ == "__main__":
    sys.exit(main())
