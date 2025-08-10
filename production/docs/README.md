# Czkawka Duplicate File Management Tools

A collection of bash scripts to streamline duplicate file detection and analysis using Czkawka CLI, with enhanced CSV reporting capabilities and LibreOffice integration.

## Overview

This project provides three complementary tools:

1. **`czkawkaDupFind.sh`** - A user-friendly wrapper for linux_czkawka_cli duplicate scanning
2. **`czkawka_to_table.sh`** - Converts Czkawka JSON results into organized CSV tables (one row per duplicate)
3. **`duplicates.ods`** - Pre-formatted LibreOffice Calc spreadsheet with file manager integration, e.g. Nemo or Krusader

## Prerequisites

### Required Software
- **linux_czkawka_cli** - The core duplicate file finder
- **jq** - JSON processor for table conversion
- **bash** - Shell environment (standard on Linux)
- **LibreOffice Calc** - For spreadsheet analysis (optional but recommended)
- **File manager** - Nemo or Krusader for direct file access from spreadsheet (optional)

### Installation Commands
```bash
# Install linux_czkawka_cli (choose one method):
snap install czkawka                    # Via Snap
# OR download from: https://github.com/qarmin/czkawka/releases

# Install jq
sudo apt install jq                     # Ubuntu/Debian
sudo yum install jq                     # CentOS/RHEL
sudo pacman -S jq                       # Arch Linux

# Install LibreOffice (usually pre-installed on Linux)
sudo apt install libreoffice-calc      # Ubuntu/Debian

# Install file managers (optional but recommended)
sudo apt install nemo krusader         # Ubuntu/Debian
```

## Project Structure

```
czkawka-tools/
├── czkawkaDupFind.sh       # Czkawka scanner wrapper
├── czkawka_to_table.sh     # JSON to CSV converter (one row per duplicate)
├── README.md               # This documentation
├── use-help.txt            # Quick reference guide
├── launch_krusader.sh      # Krusader launcher script (needed for the macro)
├── data/                   # Resulting files after scanning and converting
│   ├── duplicates.json     # The output file of czkawkaDupFind.sh
│   ├── duplicates.csv      # The output file of czkawka_to_table.sh
│   ├── duplicates.ods      # Pre-formatted spreadsheet with macro
│   └── ... other files     # Any other text or other output files
└── archived/               # Previous versions or archived results
    └── ...                 # Old scan results, deprecated scripts, etc.
```

## Quick Start Guide

### Step 1: Make Scripts Executable
```bash
chmod +x czkawkaDupFind.sh czkawka_to_table.sh
```

### Step 2: Scan for Duplicates

```bash
# Interactive mode (recommended for beginners)
./czkawkaDupFind.sh

# Command line mode
./czkawkaDupFind.sh /path/to/scan duplicates_output

# Force text format instead of JSON
./czkawkaDupFind.sh /path/to/scan duplicates_output -f
```

### Step 3: Convert to Table (JSON output only)

```bash
# Interactive mode
./czkawka_to_table.sh

# Command line mode
./czkawka_to_table.sh duplicates_output.json /main/folder report.csv
```

### Step 4: Analyze in Spreadsheet

```bash
# Open the pre-formatted spreadsheet
libreoffice --calc duplicates.ods
# Then paste CSV data directly into the 'duplicates' sheet
```

## Detailed Usage

### czkawkaDupFind.sh - Duplicate Scanner

**Purpose:** Provides a user-friendly interface to linux_czkawka_cli with automatic file extension handling.

**Syntax:**

```
./czkawkaDupFind.sh [directory] [output_name] [format_option]
```

**Parameters:**
- `directory` - Directory to scan (optional, will prompt if missing)
- `output_name` - Output filename without extension (optional, will prompt if missing)
- `format_option`:
  - `-p` (default) - JSON format (.json extension) - for machine processing
  - `-f` - Text format (.txt extension) - for human reading

**Examples:**

```bash
# Scan Documents folder, save as JSON
./czkawkaDupFind.sh ~/Documents my_scan

# Scan with text output
./czkawkaDupFind.sh ~/Pictures photo_dups -f

# Interactive mode
./czkawkaDupFind.sh
```

**Features:**
- Automatic file extension handling
- Input validation and error checking
- Progress feedback and timing
- Overwrite protection
- Next-step suggestions
- Proper handling of Czkawka exit codes (0=no duplicates, 11=duplicates found, 1=error)

## Why Two Steps? (JSON → CSV)

**Q: Why not direct CSV output from Czkawka?**
**A:** linux_czkawka_cli only supports two output formats:
- `-f` (text) - Human readable but unstructured
- `-p` (JSON) - Structured data that enables advanced processing

The JSON format allows our converter to:
- Create one row per duplicate relationship
- Separate folder paths from filenames
- Focus analysis on specific directories
- Provide proper CSV structure for spreadsheet analysis

Direct CSV output would lose this analytical capability.

### czkawka_to_table.sh - Table Converter

**Purpose:** Converts Czkawka JSON duplicate results into organized CSV tables with separate rows for each duplicate relationship (and separate folder/filename columns).

**Syntax:**

```
./czkawka_to_table.sh [json_file] [main_folder] [output_csv]
```

**Parameters:**
- `json_file` - Path to Czkawka JSON results (optional, will prompt if missing)
- `main_folder` - Focus directory - files from here appear in the first columns (optional, will prompt if missing)
- `output_csv` - Output CSV filename (optional, will prompt if missing)

**Output Format:**

| Column | Description |
|--------|-------------|
| OriginalFolder | Directory path of the main folder file |
| OriginalFile | Filename of the main folder file |
| DuplicateFolder | Directory path of one duplicate file |
| DuplicateFile | Filename of one duplicate file |
| Size | File size in bytes |
| Hash | File hash for verification |

**Key Feature - One Row Per Duplicate:**
Unlike traditional duplicate reports that list all duplicates in one row, this script creates a separate row for each duplicate relationship. For example, if `report.pdf` exists in Documents and has duplicates in both Downloads and Backup folders, you'll get two rows:
- Row 1: Documents/report.pdf → Downloads/report.pdf
- Row 2: Documents/report.pdf → Backup/report_backup.pdf

**Examples:**

```bash
# Convert scan results focusing on MEGAsync folder
./czkawka_to_table.sh duplicates.json ~/MEGAsync/Documents duplicates_report.csv

# Interactive mode
./czkawka_to_table.sh
```

**Features:**
- Focuses on files from a specific main directory (first columns A and B)
- Separates folder path and filename for both original and duplicate files
- Creates individual rows for each duplicate relationship
- Lists duplicate locations and filenames in separate columns
- Includes file size and hash for verification
- CSV format optimized for spreadsheet analysis and filtering

### duplicates.ods - Enhanced Spreadsheet Analysis

**Purpose:** Pre-formatted LibreOffice Calc spreadsheet with advanced filtering and file management capabilities.

**Structure:**
- **duplicates sheet:** Main analysis area where you paste CSV data and work with results
- **help sheet:** Contains usage instructions and macro documentation

**Key Features:**
- **Direct CSV Import:** Paste CSV data directly into the duplicates sheet
- **Advanced Filtering:** Pre-configured filters for easy data sorting and analysis
- **File Manager Integration:** Built-in macro for opening files directly in file managers like Nemo or Krusader (F3 runs macro 'OpenInFileManagerFromActiveCell')
- **Decision Marking System:** Color-coded decision tracking with keyboard shortcuts
- **Statistical Analysis:** Progress tracking and decision summaries
- **One-Row-Per-Duplicate Format:** Optimized for the new CSV format with individual duplicate relationships

#### Enhanced Macro Features

**Decision Marking Shortcuts:**
- **Ctrl+3:** MarkKeepOriginal - Keep original file, mark duplicate for deletion (green/red color coding)
- **Ctrl+4:** MarkKeepDuplicate - Keep duplicate file, mark original for deletion (red/green color coding)
- **Ctrl+6:** MarkNeedsReview - Mark both files for later review (yellow color coding)
- **Ctrl+7:** ShowStatistics - Display decision progress and summary statistics
- **Ctrl+8:** ClearDecisions - Reset decision markings for selected rows
- **Ctrl+9:** FilterByAction - Apply AutoFilter for decision analysis

**Color Coding System:**
- **Green cells:** Files marked to keep
- **Red cells:** Files marked for deletion
- **Yellow cells:** Files needing review
- **No color:** Unprocessed files

**Decision Columns (automatically added):**
- **Column G:** Keep_Original (YES/NO/REVIEW)
- **Column H:** Keep_Duplicate (YES/NO/REVIEW)
- **Column I:** Action (DELETE_ORIGINAL/DELETE_DUPLICATE/DELETE_BOTH/REVIEW_NEEDED)

#### Using the Spreadsheet

1. **Import Data:**
   - Open `duplicates.ods` in LibreOffice Calc
   - Copy all content from CSV file (Ctrl+A, then Ctrl+C in a text editor or spreadsheet app)
   - Paste directly into the 'duplicates' sheet starting at cell A1 (Ctrl+V)
   - The data will automatically align with the pre-formatted columns

2. **File Manager Integration:**
   - **Setup:** F3 assigned as a keyboard shortcut to the macro 'OpenInFileManagerFromActiveCell' via Tools → Customize → Keyboard
   - **Usage:** Click on any cell containing a folder path or filename, then press F3
   - **Supported Columns:** The macro works with the standard column layout:
     - Columns A & B: A = original folder path, B = original filename
     - Columns C & D: C = duplicate folder path, D = duplicate filename
   - **Result:** File manager opens the folder and displays the specified file

3. **Decision Making Workflow:**
   - Sort by file size (Column E) to prioritize large duplicates
   - For each row: Press F3 to view files → Compare visually → Press Ctrl+3 or Ctrl+4 to mark decision
   - Cursor automatically advances to next row for efficient processing
   - Use Ctrl+7 to check progress statistics
   - Use Ctrl+9 to filter by decision types for review

4. **Data Analysis:**
   - Use built-in filters to sort by file size, folder location, or specific filenames
   - Click column headers to sort data
   - Use AutoFilter to focus on specific folders or file types
   - Each row represents one duplicate relationship, making it easy to analyze patterns

**Macro Requirements:**
- Enable macros in LibreOffice: Tools → Options → LibreOffice → Security → Macro Security (set to Medium or Low / or set the file path as trusted)
- File manager (Nemo or Krusader) must be installed and accessible via command line

## Complete Workflow Example

### Analytical Scenario: Home Directory Duplicate Analysis

**Problem Statement:** Over time, your home directory (~) accumulates duplicate files across various subfolders. Files may exist in multiple locations such as:
- Downloads folder containing files later organized into Documents, Pictures, or Projects
- Backup folders with copies of important files
- Cloud sync folders (Dropbox, MEGAsync, OneDrive) with duplicates of local files
- Archive folders with old versions of current files

**Goal:** Identify all duplicate files across your entire home directory, then focus analysis on a specific subfolder (e.g., your Documents folder) to see which files have duplicates elsewhere in your system. This helps you:
1. Clean up redundant files safely
2. Understand your file organization patterns
3. Identify which "important" folders contain files that exist elsewhere
4. Make informed decisions about which copies to keep or delete

### Step-by-Step Workflow

#### Step 1: Comprehensive Home Directory Scan

```bash
# Scan entire home directory for all duplicates (this may take a while)
./czkawkaDupFind.sh ~ home_duplicates_scan

# Alternative: Scan with text format for quick overview first
./czkawkaDupFind.sh ~ home_overview -f
```

**What this does:** Creates a complete inventory of all duplicate files across your entire home directory, including all subfolders, hidden directories, and nested structures.

#### Step 2: Focus Analysis on Specific Subfolder

```bash
# Convert results focusing on your Documents folder
./czkawka_to_table.sh home_duplicates_scan.json ~/Documents documents_analysis.csv

# Alternative analysis focusing on different subfolders:
./czkawka_to_table.sh home_duplicates_scan.json ~/Pictures pictures_analysis.csv
./czkawka_to_table.sh home_duplicates_scan.json ~/MEGAsync cloud_sync_analysis.csv
./czkawka_to_table.sh home_duplicates_scan.json ~/Downloads downloads_analysis.csv
```

**What this does:** From the complete home directory scan, extracts only the files that:
- Exist in your specified subfolder (e.g., ~/Documents)
- Have duplicate copies somewhere else in your home directory
- Creates a focused report with one row for each duplicate relationship

#### Step 3: Analyze Results in Enhanced Spreadsheet

```bash
# Open the pre-formatted spreadsheet
libreoffice --calc duplicates.ods
```

Then:
1. Copy the entire contents of your CSV file (e.g., `documents_analysis.csv`)
2. Paste directly into the 'duplicates' sheet starting at cell A1
3. Use the built-in filters and sorting to analyze the data
4. Use the file manager integration macro to directly access files for review or deletion
5. Use decision marking shortcuts to efficiently process duplicates

## Understanding the Results

### The JSON Output Structure (from linux_czkawka_cli)

```json
{
  "8192": [
    [
      {"path": "/path/file1", "size": 8192, "hash": "abc123..."},
      {"path": "/path/file2", "size": 8192, "hash": "abc123..."}
    ]
  ]
}
```

- Keys represent file sizes
- Each size contains arrays of duplicate groups
- Each group contains files with identical content

### The CSV Output Structure (New Format)

The CSV output provides structured analysis with one row per duplicate relationship:

| Column | Purpose | Example |
|--------|---------|---------|
| **OriginalFolder** | Location of file in your focus folder | `/home/user/Documents/Projects` |
| **OriginalFile** | The actual filename | `important_report.pdf` |
| **DuplicateFolder** | Where one duplicate is found | `/home/user/Downloads` |
| **DuplicateFile** | Name of the duplicate file | `important_report.pdf` |
| **Size** | File size (helps prioritize cleanup) | `2048576` (2MB) |
| **Hash** | Verification that files are identical | `abc123def456...` |

**Example Output:**
```csv
"OriginalFolder","OriginalFile","DuplicateFolder","DuplicateFile","Size","Hash"
"/home/user/Documents","report.pdf","/home/user/Downloads","report.pdf","2048","abc123"
"/home/user/Documents","report.pdf","/home/user/Backup","report_backup.pdf","2048","abc123"
"/home/user/Documents","photo.jpg","/home/user/Pictures","photo.jpg","512000","def456"
```

This format makes it easy to:
- Filter by specific duplicate locations
- Sort by original or duplicate folders
- Count how many duplicates each file has
- Analyze duplicate patterns across your system

### Real-World Analysis Examples

**Example 1: Documents Folder Analysis**

```bash
./czkawka_to_table.sh home_duplicates_scan.json ~/Documents docs_cleanup.csv
```

Results might show:
- PDFs in Documents that also exist in Downloads (separate row for each duplicate location)
- Spreadsheets in Documents with copies in Archive folders
- Images in Documents that are duplicated in Pictures folder

**Example 2: Cloud Sync Folder Analysis**

```bash
./czkawka_to_table.sh home_duplicates_scan.json ~/MEGAsync cloud_redundancy.csv
```

Results might reveal:
- Files being synced to cloud that already exist locally elsewhere
- Cloud folder containing backups of files in your working directories
- Unnecessary cloud storage usage from duplicate files

**Example 3: Downloads Cleanup Analysis**

```bash
./czkawka_to_table.sh home_duplicates_scan.json ~/Downloads download_cleanup.csv
```

Identifies:
- Downloaded files that were later moved/copied to proper locations
- Multiple downloads of the same file
- Downloads that exist in organized folder structures

### Complete Workflow Example

```bash
# 1. Comprehensive scan of entire home directory
./czkawkaDupFind.sh ~ complete_home_scan

# 2. Generate focused analyses for different purposes
./czkawka_to_table.sh complete_home_scan.json ~/Documents documents_duplicates.csv
./czkawka_to_table.sh complete_home_scan.json ~/Pictures photos_duplicates.csv
./czkawka_to_table.sh complete_home_scan.json ~/Downloads downloads_duplicates.csv

# 3. Analyze results in the enhanced spreadsheet
libreoffice --calc duplicates.ods
# Paste each CSV directly into the duplicates sheet for analysis
```

### Practical Cleanup Strategy

1. **Start with Downloads folder analysis** - Usually contains the most obvious duplicates
2. **Review Documents folder analysis** - Identify important files with backup copies
3. **Check cloud sync folders** - Eliminate redundant cloud storage usage
4. **Use the spreadsheet's file manager integration** - Directly access files for review
5. **Use decision marking shortcuts** - Efficiently mark files for keep/delete decisions
6. **Use file sizes to prioritize** - Focus on large duplicate files first
7. **Verify with hash values** - Ensure files are truly identical before deletion
8. **Filter by duplicate locations** - Target specific cleanup areas (e.g., all Downloads duplicates)
9. **Use statistics tracking** - Monitor cleanup progress with Ctrl+7

## Troubleshooting

### Common Issues

**"linux_czkawka_cli not found"**

```bash
# Check if installed
which linux_czkawka_cli

# Install via snap if missing
sudo snap install czkawka
```

**"jq not found"**

```bash
# Install jq
sudo apt install jq
```

**"Permission denied" errors**

```bash
# Make scripts executable
chmod +x *.sh

# Check directory permissions
ls -la /path/to/scan
```

**"Exit code 11" message**

```bash
# This is actually SUCCESS when duplicates are found!
# Czkawka exit codes:
# 0 = Success, no duplicates found
# 11 = Success, duplicates found
# 1 = Error occurred
```

**Macro not working in LibreOffice**
- Enable macros: Tools → Options → LibreOffice → Security → Macro Security (Medium or Low)
- Ensure file manager is installed: `sudo apt install nemo` or `sudo apt install krusader`
- Check keyboard shortcut assignment: Tools → Customize → Keyboard

**Large scan taking too long**
- Use text format (-f) for faster processing on large datasets
- Consider scanning subdirectories separately
- Check available disk space for output files

### Performance Tips

1. **For large directories:** Use JSON format for detailed analysis, text format for quick overview
2. **Memory usage:** Czkawka loads file metadata into memory; ensure sufficient RAM for large scans
3. **Storage space:** JSON output can be large; ensure adequate disk space
4. **Spreadsheet performance:** The one-row-per-duplicate format may create larger datasets, but offers better analysis capabilities

## Contributing

Feel free to submit issues, suggestions, or improvements:

1. Test the scripts with your specific use cases
2. Report any bugs or edge cases
3. Suggest feature enhancements
4. Share workflow improvements
5. Contribute macro enhancements for the spreadsheet

## License

These scripts are provided as-is for educational and practical use. Feel free to modify and distribute according to your needs.

## Related Resources

- [Czkawka GitHub Repository](https://github.com/qarmin/czkawka)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Bash Scripting Guide](https://tldp.org/LDP/abs/html/)
- [LibreOffice Calc Documentation](https://help.libreoffice.org/latest/en-US/text/scalc/main0000.html)

---

**Created:** July 23, 2025  
**Updated:** August 1, 2025  
**Author:** claude.ai  
**Version:** 1.2
