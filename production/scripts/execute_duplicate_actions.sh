#!/bin/bash

# ============================================================================
# DUPLICATE FILE ACTION EXECUTOR
# ============================================================================
# 
# DESCRIPTION:
# Executes the actions defined in your duplicates.ods spreadsheet data.
# Supports: soft links, hard links, file deletion with comprehensive safety checks.
# 
# USAGE:
# 1. Export your spreadsheet to CSV format (keep headers)
# 2. ./execute_duplicate_actions.sh duplicates.csv [--dry-run] [--verbose]
#
# SAFETY FEATURES:
# - Dry run mode to preview all actions
# - Comprehensive file existence and permission checks
# - Backup creation for destructive operations
# - Detailed logging of all operations
# - Rollback capability for link operations
#
# Author: Enhanced for Czkawka duplicate management
# Date: August 2025
# ============================================================================

# Default settings
DRY_RUN=false
VERBOSE=false
DUPLICATES_HANDLING_DIR="$HOME/tmp/2delete/duplicatesHandling"
BACKUP_DIR="$DUPLICATES_HANDLING_DIR/duplicate_backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$DUPLICATES_HANDLING_DIR/duplicate_actions.log"
ROLLBACK_FILE="$DUPLICATES_HANDLING_DIR/duplicate_rollback.log"

# Color codes for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Statistics counters
TOTAL_ROWS=0
PROCESSED_ROWS=0
SOFTLINKS_CREATED=0
HARDLINKS_CREATED=0
FILES_DELETED=0
ERRORS=0
SKIPPED=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        case "$level" in
            "ERROR")   echo -e "${RED}[ERROR] $message${NC}" ;;
            "WARNING") echo -e "${YELLOW}[WARNING] $message${NC}" ;;
            "SUCCESS") echo -e "${GREEN}[SUCCESS] $message${NC}" ;;
            "INFO")    echo -e "${BLUE}[INFO] $message${NC}" ;;
            *)         echo "[$level] $message" ;;
        esac
    fi
}

show_usage() {
    cat << EOF
DUPLICATE FILE ACTION EXECUTOR

Usage: $0 <csv_file> [options]

Options:
    --dry-run    Preview actions without executing them
    --verbose    Show detailed output for all operations
    --help       Show this help message

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

Safety Features:
    - Comprehensive file existence checks
    - Permission validation before operations
    - Automatic backup creation for destructive operations
    - Detailed logging and rollback capabilities
    - Cross-device compatibility checks for hard links

Examples:
    $0 duplicates.csv --dry-run          # Preview all actions
    $0 duplicates.csv --verbose          # Execute with detailed output
    $0 duplicates.csv                    # Execute quietly (errors only)

EOF
}

check_prerequisites() {
    log_message "INFO" "Checking system prerequisites..."
    
    # Check required commands
    local missing_commands=()
    for cmd in ln rm cp readlink stat; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_message "ERROR" "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    # Create necessary directories (always create main dir for logging)
    mkdir -p "$DUPLICATES_HANDLING_DIR" || {
        log_message "ERROR" "Cannot create main handling directory: $DUPLICATES_HANDLING_DIR"
        return 1
    }
    log_message "INFO" "Duplicates handling directory: $DUPLICATES_HANDLING_DIR"
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR" || {
            log_message "ERROR" "Cannot create backup directory: $BACKUP_DIR"
            return 1
        }
        log_message "INFO" "Backup directory created: $BACKUP_DIR"
        
        # Initialize rollback file
        echo "# Rollback commands for duplicate file operations" > "$ROLLBACK_FILE"
        echo "# Generated: $(date)" >> "$ROLLBACK_FILE"
        echo "" >> "$ROLLBACK_FILE"
    else
        log_message "INFO" "DRY RUN mode - backup directory will not be created"
        # Initialize rollback file for dry run (to show what would be done)
        echo "# DRY RUN - Rollback commands that would be generated" > "$ROLLBACK_FILE"
        echo "# Generated: $(date)" >> "$ROLLBACK_FILE"
        echo "" >> "$ROLLBACK_FILE"
    fi
    
    return 0
}

validate_file_paths() {
    local orig_path="$1"
    local orig_file="$2"  
    local dup_path="$3"
    local dup_file="$4"
    local action="$5"
    
    local orig_full="$orig_path/$orig_file"
    local dup_full="$dup_path/$dup_file"
    
    # Check if files exist based on action requirements
    case "$action" in
        "DELETE_ORIGINAL"|"SOFTLINK_ORIGINAL"|"HARDLINK_ORIGINAL")
            if [ ! -f "$orig_full" ]; then
                log_message "ERROR" "Original file not found: $orig_full"
                return 1
            fi
            if [ ! -f "$dup_full" ]; then
                log_message "ERROR" "Duplicate file not found: $dup_full"
                return 1
            fi
            ;;
        "DELETE_DUPLICATE"|"SOFTLINK_DUPLICATE"|"HARDLINK_DUPLICATE")
            if [ ! -f "$orig_full" ]; then
                log_message "ERROR" "Original file not found: $orig_full"
                return 1
            fi
            if [ ! -f "$dup_full" ]; then
                log_message "ERROR" "Duplicate file not found: $dup_full"
                return 1
            fi
            ;;
        "DELETE_BOTH")
            if [ ! -f "$orig_full" ] && [ ! -f "$dup_full" ]; then
                log_message "ERROR" "Neither file exists: $orig_full, $dup_full"
                return 1
            fi
            ;;
    esac
    
    # Check write permissions for directories
    if [ ! -w "$orig_path" ]; then
        log_message "ERROR" "No write permission for directory: $orig_path"
        return 1
    fi
    
    if [ ! -w "$dup_path" ]; then
        log_message "ERROR" "No write permission for directory: $dup_path"  
        return 1
    fi
    
    # For hard links, check if files are on same filesystem
    if [[ "$action" =~ ^HARDLINK_ ]]; then
        local orig_dev=$(stat -c '%d' "$orig_path" 2>/dev/null)
        local dup_dev=$(stat -c '%d' "$dup_path" 2>/dev/null)
        
        if [ "$orig_dev" != "$dup_dev" ]; then
            log_message "WARNING" "Files on different filesystems, hard link not possible: $orig_full <-> $dup_full"
            return 2  # Special return code for cross-device
        fi
    fi
    
    return 0
}

create_backup() {
    local file_path="$1"
    local backup_name="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log_message "INFO" "[DRY-RUN] Would backup: $file_path -> $BACKUP_DIR/$backup_name"
        return 0
    fi
    
    if [ -f "$file_path" ]; then
        cp "$file_path" "$BACKUP_DIR/$backup_name" || {
            log_message "ERROR" "Failed to create backup: $file_path"
            return 1
        }
        log_message "INFO" "Backup created: $backup_name"
    fi
    
    return 0
}

# ============================================================================
# ACTION EXECUTION FUNCTIONS  
# ============================================================================

execute_soft_link() {
    local source_file="$1"
    local target_file="$2" 
    local action_type="$3"
    
    if [ "$DRY_RUN" = true ]; then
        log_message "INFO" "[DRY-RUN] Would create soft link: $target_file -> $source_file"
        return 0
    fi
    
    # Create backup of target before replacing with link
    local backup_name="softlink_$(basename "$target_file")_$(date +%H%M%S)"
    create_backup "$target_file" "$backup_name" || return 1
    
    # Remove target and create soft link
    rm "$target_file" || {
        log_message "ERROR" "Failed to remove target file: $target_file"
        return 1
    }
    
    ln -s "$source_file" "$target_file" || {
        log_message "ERROR" "Failed to create soft link: $target_file -> $source_file"
        # Try to restore from backup
        if [ -f "$BACKUP_DIR/$backup_name" ]; then
            cp "$BACKUP_DIR/$backup_name" "$target_file"
            log_message "INFO" "Restored target file from backup"
        fi
        return 1
    }
    
    # Log rollback command
    echo "rm '$target_file' && cp '$BACKUP_DIR/$backup_name' '$target_file'" >> "$ROLLBACK_FILE"
    
    log_message "SUCCESS" "Soft link created: $target_file -> $source_file"
    ((SOFTLINKS_CREATED++))
    return 0
}

execute_hard_link() {
    local source_file="$1"
    local target_file="$2"
    local action_type="$3"
    
    if [ "$DRY_RUN" = true ]; then
        log_message "INFO" "[DRY-RUN] Would create hard link: $target_file -> $source_file"
        return 0
    fi
    
    # Create backup of target before replacing with link
    local backup_name="hardlink_$(basename "$target_file")_$(date +%H%M%S)"
    create_backup "$target_file" "$backup_name" || return 1
    
    # Remove target and create hard link  
    rm "$target_file" || {
        log_message "ERROR" "Failed to remove target file: $target_file"
        return 1
    }
    
    ln "$source_file" "$target_file" || {
        log_message "ERROR" "Failed to create hard link: $target_file -> $source_file"
        # Try to restore from backup
        if [ -f "$BACKUP_DIR/$backup_name" ]; then
            cp "$BACKUP_DIR/$backup_name" "$target_file"
            log_message "INFO" "Restored target file from backup"
        fi
        return 1
    }
    
    # Log rollback command
    echo "rm '$target_file' && cp '$BACKUP_DIR/$backup_name' '$target_file'" >> "$ROLLBACK_FILE"
    
    log_message "SUCCESS" "Hard link created: $target_file -> $source_file"
    ((HARDLINKS_CREATED++))
    return 0
}

execute_delete() {
    local file_path="$1"
    local file_type="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log_message "INFO" "[DRY-RUN] Would delete $file_type: $file_path"
        return 0
    fi
    
    # Create backup before deletion
    local backup_name="deleted_$(basename "$file_path")_$(date +%H%M%S)"
    create_backup "$file_path" "$backup_name" || return 1
    
    # Delete the file
    rm "$file_path" || {
        log_message "ERROR" "Failed to delete $file_type: $file_path"
        return 1
    }
    
    # Log rollback command
    echo "cp '$BACKUP_DIR/$backup_name' '$file_path'" >> "$ROLLBACK_FILE"
    
    log_message "SUCCESS" "Deleted $file_type: $file_path"
    ((FILES_DELETED++))
    return 0
}

# ============================================================================
# MAIN ACTION PROCESSOR
# ============================================================================

process_action() {
    local orig_path="$1"
    local orig_file="$2"
    local dup_path="$3" 
    local dup_file="$4"
    local action="$5"
    local row_num="$6"
    
    local orig_full="$orig_path/$orig_file"
    local dup_full="$dup_path/$dup_file"
    
    log_message "INFO" "Processing row $row_num: $action"
    
    # Validate file paths and permissions
    validate_file_paths "$orig_path" "$orig_file" "$dup_path" "$dup_file" "$action"
    local validation_result=$?
    
    if [ $validation_result -eq 1 ]; then
        log_message "ERROR" "Validation failed for row $row_num, skipping"
        ((ERRORS++))
        return 1
    elif [ $validation_result -eq 2 ]; then
        log_message "WARNING" "Cross-device hard link attempted, skipping row $row_num"
        ((SKIPPED++))
        return 1
    fi
    
    # Execute the appropriate action
    case "$action" in
        "SOFTLINK_ORIGINAL")
            # Keep duplicate, link original to it
            execute_soft_link "$dup_full" "$orig_full" "original"
            ;;
        "SOFTLINK_DUPLICATE") 
            # Keep original, link duplicate to it
            execute_soft_link "$orig_full" "$dup_full" "duplicate"
            ;;
        "HARDLINK_ORIGINAL")
            # Keep duplicate, hard link original to it
            execute_hard_link "$dup_full" "$orig_full" "original"
            ;;
        "HARDLINK_DUPLICATE")
            # Keep original, hard link duplicate to it  
            execute_hard_link "$orig_full" "$dup_full" "duplicate"
            ;;
        "DELETE_ORIGINAL")
            # Delete original, keep duplicate
            execute_delete "$orig_full" "original"
            ;;
        "DELETE_DUPLICATE")
            # Delete duplicate, keep original
            execute_delete "$dup_full" "duplicate" 
            ;;
        "DELETE_BOTH")
            # Delete both files
            execute_delete "$orig_full" "original" || return 1
            execute_delete "$dup_full" "duplicate"
            ;;
        "")
            log_message "INFO" "No action specified for row $row_num, skipping"
            ((SKIPPED++))
            return 0
            ;;
        *)
            log_message "WARNING" "Unknown action '$action' for row $row_num, skipping"
            ((SKIPPED++))
            return 1
            ;;
    esac
    
    local result=$?
    if [ $result -eq 0 ]; then
        ((PROCESSED_ROWS++))
    else
        ((ERRORS++))
    fi
    
    return $result
}

# ============================================================================
# CSV PROCESSING WITH ALTERNATIVE APPROACH
# ============================================================================

process_csv_file() {
    local csv_file="$1"
    
    if [ ! -f "$csv_file" ]; then
        log_message "ERROR" "CSV file not found: $csv_file"
        echo ""
        echo "Available CSV files in current directory:"
        ls -la *.csv 2>/dev/null || echo "  No CSV files found"
        echo ""
        return 1
    fi
    
    log_message "INFO" "Processing CSV file: $csv_file"
    
    # Use a different approach to avoid the while loop issue
    local line_num=0
    local data_row=0
    
    # Read file into array to avoid piping issues
    mapfile -t lines < "$csv_file"
    
    for line in "${lines[@]}"; do
        ((line_num++))
        
        # Skip header row and summary rows
        if [ $line_num -le 2 ]; then
            log_message "INFO" "Skipping row $line_num (header/summary)"
            continue
        fi
        
        # Skip empty lines
        if [ -z "$line" ]; then
            continue
        fi
        
        # Parse CSV line manually
        IFS=',' read -ra fields <<< "$line"
        
        # Extract fields (accounting for the empty first column)
        if [ ${#fields[@]} -lt 10 ]; then
            log_message "WARNING" "Row $line_num has insufficient columns, skipping"
            continue
        fi
        
        local empty_col="${fields[0]}"
        local orig_path="${fields[1]}"
        local orig_file="${fields[2]}"
        local dup_path="${fields[3]}"
        local dup_file="${fields[4]}"
        local size="${fields[5]}"
        local hash="${fields[6]}"
        local keep_orig="${fields[7]}"
        local keep_dup="${fields[8]}"
        local action="${fields[9]}"
        local notes="${fields[10]:-}"
        
        # Clean up values (remove quotes and trim)
        orig_path=$(echo "$orig_path" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        orig_file=$(echo "$orig_file" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        dup_path=$(echo "$dup_path" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        dup_file=$(echo "$dup_file" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        action=$(echo "$action" | sed 's/^"//; s/"$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        
        ((data_row++))
        ((TOTAL_ROWS++))
        
        # Debug output
        if [ "$VERBOSE" = true ]; then
            log_message "INFO" "Row $data_row parsed: orig='$orig_path/$orig_file' dup='$dup_path/$dup_file' action='$action'"
        fi
        
        # Process the action for this row
        if [ -n "$action" ] && [ "$action" != "REVIEW_NEEDED" ] && [ "$action" != "Action" ]; then
            process_action "$orig_path" "$orig_file" "$dup_path" "$dup_file" "$action" "$data_row"
        else
            log_message "INFO" "Row $data_row: No valid action ('$action') or needs review, skipping"
            ((SKIPPED++))
        fi
        
        # Progress indicator
        if [ $((data_row % 50)) -eq 0 ]; then
            log_message "INFO" "Processed $data_row rows..."
        fi
    done
    
    return 0
}

show_final_statistics() {
    echo ""
    echo "============================================================================"
    echo "DUPLICATE FILE PROCESSING COMPLETE"
    echo "============================================================================"
    echo ""
    echo "STATISTICS:"
    echo "  Total rows processed: $TOTAL_ROWS"
    echo "  Successful operations: $PROCESSED_ROWS"
    echo "  Soft links created: $SOFTLINKS_CREATED"
    echo "  Hard links created: $HARDLINKS_CREATED" 
    echo "  Files deleted: $FILES_DELETED"
    echo "  Errors encountered: $ERRORS"
    echo "  Rows skipped: $SKIPPED"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        echo "BACKUP AND RECOVERY:"
        echo "  Handling directory: $DUPLICATES_HANDLING_DIR"
        echo "  Backup directory: $BACKUP_DIR"
        echo "  Log file: $LOG_FILE"
        echo "  Rollback script: $ROLLBACK_FILE"
        echo ""
        echo "To rollback operations, run:"
        echo "  bash $ROLLBACK_FILE"
    else
        echo "DRY RUN COMPLETE - No changes were made"
        echo "Remove --dry-run flag to execute the operations"
    fi
    
    echo ""
    echo "============================================================================"
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

main() {
    # Parse command line arguments
    local csv_file=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$csv_file" ]; then
                    csv_file="$1"
                else
                    echo "Multiple CSV files specified" >&2
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [ -z "$csv_file" ]; then
        echo "Error: CSV file not specified" >&2
        show_usage
        exit 1
    fi
    
    # Initialize logging
    mkdir -p "$DUPLICATES_HANDLING_DIR" 2>/dev/null  # Ensure directory exists before logging
    echo "=== Duplicate File Action Executor - $(date) ===" >> "$LOG_FILE"
    log_message "INFO" "Starting duplicate file processing"
    log_message "INFO" "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "EXECUTE")"
    log_message "INFO" "CSV file: $csv_file"
    
    # Check prerequisites
    check_prerequisites || {
        log_message "ERROR" "Prerequisites check failed"
        exit 1
    }
    
    # Process the CSV file
    process_csv_file "$csv_file" || {
        log_message "ERROR" "CSV processing failed"
        exit 1
    }
    
    # Show final statistics
    show_final_statistics
    
    # Set exit code based on errors
    if [ $ERRORS -gt 0 ]; then
        log_message "WARNING" "Completed with $ERRORS errors"
        exit 2
    else
        log_message "SUCCESS" "All operations completed successfully"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"
