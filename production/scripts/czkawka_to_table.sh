#!/usr/bin/env bash

# ============================================================================
# CZKAWKA DUPLICATE RESULTS TO CSV CONVERTER - one record per duplicate pair
# ============================================================================
# 
# DESCRIPTION:
# This script converts Czkawka JSON duplicate scan results into a readable
# CSV table format. It extracts files from a specified main folder that have
# duplicates elsewhere and creates ONE row per duplicate pair (no reversed pairs).
#
# USAGE:
#   ./czkawka_to_table.sh [json_file] [main_folder] [output_csv]
#   
#   Parameters (all optional - will prompt if missing):
#   - json_file:   Path to Czkawka duplicates.json file
#   - main_folder: Main directory to focus on (files from here go in first column)
#   - output_csv:  Output CSV filename
#
# EXAMPLES:
#   ./czkawka_to_table.sh duplicates.json /home/user/Documents report.csv
#   ./czkawka_to_table.sh  # Interactive mode - will prompt for all parameters
#
# OUTPUT FORMAT:
#   CSV with columns: OriginalFolder, OriginalFile, DuplicateFolder, DuplicateFile, Size, Hash
#   Each duplicate pair creates only ONE row (no A=B and B=A duplicates)
#
# REQUIREMENTS:
#   - jq (JSON processor): sudo apt install jq
#   - Czkawka JSON output file from duplicate scan
#
# Author: claude.ai on 23/07/2025
# Modified: 06/08/2025 - Fixed duplicate pair prevention
# ================================================================

# --- Parameter Collection ---
JSON="${1:-}"
MAIN="${2:-}"
OUTPUT="${3:-}"

# Interactive prompts for missing parameters
if [ -z "$JSON" ]; then
  read -rp "Enter path to duplicates.json: " JSON
fi

if [ -z "$MAIN" ]; then
  read -rp "Enter main folder (files from here in first column): " MAIN
fi

if [ -z "$OUTPUT" ]; then
  read -rp "Enter output CSV filename: " OUTPUT
fi

# --- Validation and Prerequisites ---
echo "Validating requirements..."

# Check if jq is installed
if ! command -v jq &>/dev/null; then
  echo "❌ Error: jq is not installed."
  echo "   Install with: sudo apt install jq"
  exit 1
fi

# Check if JSON file exists
if [ ! -f "$JSON" ]; then
  echo "❌ Error: JSON file '$JSON' not found."
  exit 1
fi

# Validate JSON format
if ! jq empty "$JSON" 2>/dev/null; then
  echo "❌ Error: Invalid JSON format in '$JSON'"
  exit 1
fi

# Ensure main folder path doesn't end with slash for consistent processing
MAIN="${MAIN%/}"

# --- CSV Generation ---
echo "Processing Czkawka duplicates from: $JSON"
echo "Focusing on files in: $MAIN"

# Create CSV header with separated folder and filename columns - one record per duplicate pair
echo '"OriginalFolder","OriginalFile","DuplicateFolder","DuplicateFile","Size","Hash"' > "$OUTPUT"

# Process the nested JSON structure from Czkawka with duplicate pair prevention
jq -r --arg MAIN "$MAIN" '
  # Iterate through each file size category (keys like "8192", "10000", etc.)
  to_entries[] |
  
  # Each size category contains an array of duplicate groups
  .value[] |
  
  # Store current duplicate group for reference
  . as $duplicate_group |
  
  # Get all files in the current duplicate group
  $duplicate_group as $all_files |
  
  # Create all possible pairs within this group (avoiding duplicates)
  [
    # Generate all unique pairs from the duplicate group
    range(0; length) as $i |
    range($i + 1; length) as $j |
    {
      file1: $all_files[$i],
      file2: $all_files[$j]
    }
  ] |
  
  # Process each unique pair
  .[] |
  
  # Determine which file should be "original" and which should be "duplicate"
  # Priority: files from MAIN folder go in original column
  if (.file1.path | startswith($MAIN)) and (.file2.path | startswith($MAIN) | not) then
    # file1 is in MAIN, file2 is not - file1 becomes original
    {
      original: .file1,
      duplicate: .file2
    }
  elif (.file2.path | startswith($MAIN)) and (.file1.path | startswith($MAIN) | not) then
    # file2 is in MAIN, file1 is not - file2 becomes original
    {
      original: .file2,
      duplicate: .file1
    }
  elif (.file1.path | startswith($MAIN)) and (.file2.path | startswith($MAIN)) then
    # Both files are in MAIN - use lexicographic order to ensure consistency
    if .file1.path < .file2.path then
      {
        original: .file1,
        duplicate: .file2
      }
    else
      {
        original: .file2,
        duplicate: .file1
      }
    end
  elif (.file1.path | startswith($MAIN) | not) and (.file2.path | startswith($MAIN) | not) then
    # Neither file is in MAIN - skip this pair (not relevant to main folder focus)
    empty
  else
    empty
  end |
  
  # Split paths into folder and filename components
  (.original.path | split("/") | .[:-1] | join("/")) as $orig_folder |
  (.original.path | split("/") | .[-1]) as $orig_filename |
  (.duplicate.path | split("/") | .[:-1] | join("/")) as $dup_folder |
  (.duplicate.path | split("/") | .[-1]) as $dup_filename |
  
  # Generate CSV row: OrigFolder, OrigFile, DupFolder, DupFile, Size, Hash
  [
    $orig_folder,
    $orig_filename,
    $dup_folder,
    $dup_filename,
    .original.size,
    .original.hash
  ] | @csv
' "$JSON" >> "$OUTPUT"

# --- Results Summary ---
if [ $? -eq 0 ]; then
  ROWS=$(tail -n +2 "$OUTPUT" | wc -l)
  UNIQUE_FILES=$(tail -n +2 "$OUTPUT" | cut -d',' -f1,2 | sort -u | wc -l)
  echo "✅ Success! Created: $OUTPUT"
  echo "📊 Found $UNIQUE_FILES unique files in '$MAIN' with $ROWS total duplicate relationships"
  
  # Show preview if results exist
  if [ $ROWS -gt 0 ]; then
    echo
    echo "🔍 Preview of results:"
    echo "Format: OrigFolder | OrigFile | DupFolder | DupFile | Size | Hash"
    head -3 "$OUTPUT" | tail -2 | column -t -s',' | sed 's/"//g'
    
    if [ $ROWS -gt 2 ]; then
      echo "... and $((ROWS - 2)) more rows"
    fi
    
    echo
    echo "ℹ️  Each row represents one unique duplicate relationship"
    echo "   No reversed pairs (A=B and B=A) - only one record per pair"
    echo "   Files from '$MAIN' are prioritized in the Original columns"
  else
    echo "ℹ️  No duplicate files found in the specified main folder"
  fi
else
  echo "❌ Error processing JSON file"
  exit 1
fi

echo
echo "📄 Open '$OUTPUT' in LibreOffice Calc or Excel to view the full results"
echo "🔧 For LibreOffice integration, use the provided macro for file management"
