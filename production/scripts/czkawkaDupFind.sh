#!/usr/bin/env bash

# ================================================================
# CZKAWKA DUPLICATE SCANNER WRAPPER
# ================================================================
#
# DESCRIPTION:
# This script provides a convenient wrapper around the linux_czkawka_cli duplicate
# scanner. It handles parameter collection, output format selection, and
# file extension management automatically.
#
# USAGE:
#   ./czkawkaDupFind.sh [directory] [output_name] [options]
#   
#   Parameters:
#   - directory:   Directory to scan for duplicates (optional - will prompt)
#   - output_name: Output filename without extension (optional - will prompt)
#   - options:     -f for text format, -p for JSON format (default: -p)
#
# EXAMPLES:
#   ./czkawkaDupFind.sh /home/user/Documents duplicates_scan
#   ./czkawkaDupFind.sh /home/user/Photos photos_dup -f
#   ./czkawkaDupFind.sh  # Interactive mode
#
# OUTPUT FORMATS:
#   -p (default): JSON format (.json) - machine readable, works with table converter
#   -f:           Text format (.txt) - human readable
#
# REQUIREMENTS:
#   - linux_czkawka_cli installed and in PATH
#   - Read permissions on target directory
#
# Author: claude.ai on 23/07/2025
# ================================================================

# --- Default Values ---
OUTPUT_FORMAT="-p"  # Default to JSON format
OUTPUT_EXT=".json"

# --- Parameter Processing ---
SCAN_DIR="${1:-}"
OUTPUT_NAME="${2:-}"

# Process format option from any position in arguments
for arg in "$@"; do
  case $arg in
    -f)
      OUTPUT_FORMAT="-f"
      OUTPUT_EXT=".txt"
      echo "📝 Selected: Text format output"
      ;;
    -p)
      OUTPUT_FORMAT="-p"
      OUTPUT_EXT=".json"
      echo "📋 Selected: JSON format output (required for CSV conversion)"
      ;;
  esac
done

# --- Interactive Parameter Collection ---
if [ -z "$SCAN_DIR" ]; then
  echo "🔍 CZKAWKA DUPLICATE SCANNER"
  echo "=============================="
  echo
  read -rp "Enter directory to scan for duplicates: " SCAN_DIR
fi

if [ -z "$OUTPUT_NAME" ]; then
  read -rp "Enter output filename (without extension): " OUTPUT_NAME
fi

# Construct full output path with appropriate extension
OUTPUT_FILE="${OUTPUT_NAME}${OUTPUT_EXT}"

# --- Validation ---
echo
echo "Validating setup..."

# Check if linux_czkawka_cli is available
if ! command -v linux_czkawka_cli &>/dev/null; then
  echo "❌ Error: linux_czkawka_cli is not installed or not in PATH"
  echo "   Install from: https://github.com/qarmin/czkawka"
  echo "   Or install via package manager (e.g., snap install czkawka)"
  exit 1
fi

# Check if scan directory exists
if [ ! -d "$SCAN_DIR" ]; then
  echo "❌ Error: Directory '$SCAN_DIR' does not exist or is not accessible"
  exit 1
fi

# Check if scan directory is readable
if [ ! -r "$SCAN_DIR" ]; then
  echo "❌ Error: No read permission for directory '$SCAN_DIR'"
  exit 1
fi

# Warn if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
  echo "⚠️  Warning: Output file '$OUTPUT_FILE' already exists"
  read -rp "   Overwrite? (y/N): " OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "❌ Scan cancelled"
    exit 1
  fi
fi

# --- Scan Execution ---
echo
echo "🚀 Starting duplicate scan..."
echo "📁 Scanning: $SCAN_DIR"
echo "📄 Output: $OUTPUT_FILE"
echo "🔧 Format: $OUTPUT_FORMAT ($OUTPUT_EXT format)"
echo

# Record start time for duration calculation
START_TIME=$(date +%s)

# Execute linux_czkawka_cli with appropriate parameters
echo "Running: linux_czkawka_cli dup -d \"$SCAN_DIR\" $OUTPUT_FORMAT \"$OUTPUT_FILE\""
echo "----------------------------------------"

# Run the command and capture both stdout and stderr
# linux_czkawka_cli outputs informational messages to stderr, so we need to handle this properly
linux_czkawka_cli dup -d "$SCAN_DIR" "$OUTPUT_FORMAT" "$OUTPUT_FILE" 2>&1
COMMAND_EXIT_CODE=$?

# Check if the command succeeded by verifying exit code and output file existence
# Exit codes: 0 = success (no duplicates found), 11 = success (duplicates found), 1 = error
if ([ $COMMAND_EXIT_CODE -eq 0 ] || [ $COMMAND_EXIT_CODE -eq 11 ]) && [ -f "$OUTPUT_FILE" ]; then
  # Calculate scan duration
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  
  echo
  echo "✅ Scan completed successfully!"
  if [ $COMMAND_EXIT_CODE -eq 11 ]; then
    echo "🎯 Duplicate files were found!"
  else
    echo "✨ No duplicate files found in the scanned directory"
  fi
  echo "⏱️  Duration: ${DURATION} seconds"
  echo "📄 Results saved to: $OUTPUT_FILE"
  
  # Provide file size information
  if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "📊 File size: $FILE_SIZE"
    
    # Provide format-specific next steps
    if [ "$OUTPUT_FORMAT" = "-p" ]; then
      echo
      echo "💡 Next steps:"
      echo "   To convert to readable table format, use:"
      echo "   ./czkawka_to_table.sh \"$OUTPUT_FILE\" [main_folder] [output.csv]"
    else
      echo
      echo "💡 The results are in human-readable text format"
      echo "   View with: less \"$OUTPUT_FILE\" or cat \"$OUTPUT_FILE\""
    fi
  fi
  
else
  echo
  echo "❌ Scan failed!"
  echo "   Exit code: $COMMAND_EXIT_CODE"
  if [ ! -f "$OUTPUT_FILE" ]; then
    echo "   Output file was not created"
  else
    echo "   Output file exists but command reported failure"
  fi
  echo "   Check the error messages above for details"
  exit 1
fi

echo
echo "🎉 Duplicate scan process completed!"
