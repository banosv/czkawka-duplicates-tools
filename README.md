# Czkawka Duplicates Tools

Complete automation pipeline for efficient duplicate file management using Czkawka, LibreOffice Calc, and Python/Bash scripts.

## 🎯 What It Does

Transform chaotic duplicate detection into organized, automated cleanup:
- **Detect** → Czkawka scans and identifies duplicate files
- **Analyze** → LibreOffice Calc with enhanced macros for decision making
- **Execute** → Python/Bash scripts automate file operations with full rollback capability
- **Verify** → Comprehensive logging and safety backups throughout

## ⚡ Quick Start

```bash
# 1. Find duplicates
./production/scripts/czkawkaDupFind.sh /path/to/scan duplicates_scan

# 2. Convert to table format
./production/scripts/czkawka_to_table.sh duplicates_scan.json /main/folder duplicates.csv

# 3. Analyze in LibreOffice (import CSV at B3, use macro shortcuts)

# 4. Execute decisions
python production/scripts/python/duplicate_executor.py decisions.csv --dry-run
python production/scripts/python/duplicate_executor.py decisions.csv
```

## 🗂️ Repository Structure

```
├── production/
│   ├── LO-calc/                    # LibreOffice Calc components
│   │   ├── duplicates.ods          # Main spreadsheet template
│   │   ├── duplicates.ods.macros.txt # Enhanced macro system
│   │   └── LO-help.md             # Complete macro documentation
│   ├── scripts/                    # Automation scripts
│   │   ├── czkawkaDupFind.sh      # Czkawka wrapper
│   │   ├── czkawka_to_table.sh    # JSON to CSV converter
│   │   ├── execute_duplicate_actions.sh # Bash executor
│   │   ├── launch_krusader.sh     # File manager integration
│   │   └── python/
│   │       ├── duplicate_executor.py    # Python executor
│   │       └── rollback_duplicates.py   # Recovery system
│   └── docs/
│       ├── SETUP.md               # Installation guide
│       └── USAGE.md               # Daily workflow
└── README.md                      # This file
```

## 🚀 Key Features

- **Dual execution engines** - Python (cross-platform) or Bash (Linux performance)
- **Smart file manager integration** - Nemo and Krusader support with fallbacks
- **Advanced LibreOffice macros** - 12 keyboard shortcuts for rapid decision making
- **Complete safety system** - Dry-run, automatic backups, selective rollback
- **Multiple action types** - Delete, soft link, hard link, or review options
- **Cross-device support** - Automatic filesystem compatibility checks

## 📋 Supported Actions

- `DELETE_ORIGINAL` / `DELETE_DUPLICATE` - Remove unwanted copies
- `SOFTLINK_ORIGINAL` / `SOFTLINK_DUPLICATE` - Create symbolic links
- `HARDLINK_ORIGINAL` / `HARDLINK_DUPLICATE` - Create hard links (same filesystem)
- `REVIEW_NEEDED` - Mark for manual review

## 🛠️ System Requirements

- **OS**: Mint [Ubuntu]/Linux (Bash engine) or any OS with Python 3.6+ (Python engine)
- **Applications**: LibreOffice Calc, Czkawka
- **File Managers**: Nemo (primary), Krusader (optional)
- **Dependencies**: `jq`, standard Unix utilities

## 📖 Documentation

- **[Setup Guide](production/docs/SETUP.md)** - Complete installation and configuration
- **[Usage Guide](production/docs/USAGE.md)** - Daily workflow reference
- **[LibreOffice Help](production/LO-calc/LO-help.md)** - Detailed macro documentation

## 🛡️ Safety First

All operations include comprehensive backups, logging, and rollback capabilities:
- **Dry-run mode** - Test before executing real changes
- **Automatic backups** - Timestamped copies before destructive operations
- **Full rollback** - Selective or complete operation reversal
- **Cross-device detection** - Prevents impossible hard link operations

---

**Complete Pipeline**: Detect → Analyze → Execute → Verify  
**Safety Focus**: Multiple validation layers with full recovery options

