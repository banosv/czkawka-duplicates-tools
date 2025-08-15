# Czkawka Duplicates Tools

Complete automation pipeline for efficient duplicate file management using Czkawka, LibreOffice Calc, and Python/Bash scripts.

## **What It Does**
Transform chaotic duplicate detection into organized, automated cleanup:  
- **Detect:** Czkawka scans and identifies duplicate files  
- **Analyze:** LibreOffice Calc with enhanced macro v0.5 for decision making  
- **Execute:** Python/Bash scripts automate file operations with full rollback capability  
- **Verify:** Comprehensive logging and safety backups throughout

## **Complete Pipeline**

```bash
\# 1. Find duplicates
./scripts/czkawkaDupFind.sh /path/to/scan duplicates_scan

# 2. Convert to table format  
./scripts/czkawka_to_table.sh duplicates_scan.json /main/folder duplicates.csv

# 3. Analyze in LibreOffice (import CSV at B3, use macro shortcuts)

# 4. Execute decisions
python scripts/python/duplicate_executor.py decisions.csv --dry-run
python scripts/python/duplicate_executor.py decisions.csv

# 5. Rollback if needed
python scripts/python/rollback_duplicates.py rollback.json
Key Features
    • Safe Operations: Dry-run mode, automatic backups, rollback capability 
    • Smart Decisions: Delete, soft link, hard link, or review options 
    • File Manager Integration: Krusader/Nemo dual-pane comparison 
    • Progress Tracking: Statistics, filtering, and visual progress indicators 
    • Cross-Device Support: Automatic filesystem compatibility checks 
System Requirements
    • Ubuntu/Linux environment 
    • LibreOffice Calc 
    • Python 3.6+ 
    • File managers: nemo (primary), krusader (optional) 
    • Dependencies: jq, standard Unix utilities 
Quick Start
    1. Setup: Complete installation guide 
    2. Usage: Daily workflow reference 
    3. Pipeline: Detect → Analyze → Execute → Verify 
Supported Actions
    • DELETE_ORIGINAL / DELETE_DUPLICATE - Remove unwanted copies 
    • SOFTLINK_ORIGINAL / SOFTLINK_DUPLICATE - Create symbolic links 
    • HARDLINK_ORIGINAL / HARDLINK_DUPLICATE - Create hard links 
    • REVIEW_NEEDED - Mark for manual review 
Safety First
All operations include comprehensive backups, logging, and rollback capabilities. Test with --dry-run before executing real changes.

---

