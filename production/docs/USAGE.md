# Usage Guide - Daily Workflow

Complete reference for the duplicate file management workflow using all pipeline components.

## **Phase 1: Duplicate Detection**

### **Scan for Duplicates**
```bash
# Interactive mode (recommended for beginners)
./production/scripts/czkawkaDupFind.sh

# Direct command with parameters
./production/scripts/czkawkaDupFind.sh /path/to/scan output_name

# Format options:
# -p (default): JSON format for pipeline processing
# -f: Human-readable text format

```

**Example:**

```bash
./production/scripts/czkawkaDupFind.sh /home/user/Documents docs_scan
# Creates: docs_scan.json

```

### **Convert to Analysis Format**

```bash
# Interactive mode
./production/scripts/czkawka_to_table.sh

# Direct command  
./production/scripts/czkawka_to_table.sh scan.json /main/folder output.csv

```

**Example:**

```bash
./production/scripts/czkawka_to_table.sh docs_scan.json /home/user/Documents docs_analysis.csv
# Creates CSV with files from Documents folder prioritized

```

## **Phase 2: Analysis & Decision Making**

### **LibreOffice Workflow**

#### **Data Import**

1.  Open `production/LO-calc/duplicates.ods`
2.  **Import CSV at cell B3** (critical - not A1!)
3.  Sort by Size column (F) to prioritize large duplicates
4.  Verify named range covers all data

#### **File Comparison**

|Action| Result |
|--|--|
| **F3** (Nemo) |Open both file locations in tabs  |
|**Alt+F3** (Krusader)|Open both files in dual-pane view|

#### **Decision Making**
|Shortcut  | Action |Color Code|Use Case|
|--|--|--|--|
|**Ctrl+3**  |Keep Original  |🟢 Green = Keep, 🔴 Red = Delete|Original is better quality/location |
|**Ctrl+4**|Keep Duplicate|🔴 Red = Delete, 🟢 Green = Keep|Duplicate is better quality/location|
|**Ctrl+6**|Review Later|🟡 Yellow = Review|Need more analysis|
|**Alt+3**|Soft Link Duplicate→Original|🟢 Green = Keep, 🔵 Blue = Link|Preserve paths, save space|
|**Alt+4**|Soft Link Original→Duplicate|🔵 Blue = Link, 🟢 Green = Keep|Preserve paths, save space|
|**Ctrl+Alt+3**|Hard Link Duplicate→Original|🟢 Green = Keep, 🔷 Teal = Hard Link|Same filesystem, save space|
|**Ctrl+Alt+4**|Hard Link Original→Duplicate|🔷 Teal = Hard Link, 🟢 Green = Keep|Same filesystem, save space|

#### **Progress Management**
| Shortcut | Function |Usage|
|--|--|--|
|**Ctrl+7**|Show Statistics|Check progress: processed/total, completion %|
|**Ctrl+9**|Filter by Cell|Click any cell, filter by its content|
|**Ctrl+0**|Clear Filters|Show all rows again|
|**Ctrl+8**|Clear Decisions|Reset selected rows (undo mistakes)|

#### **Export Decisions**

1.  Filter by Action column to review cleanup plan
2.  Address any "REVIEW_NEEDED" items
3.  Export to CSV: **File → Save As → CSV**
4.  Save as `decisions.csv` for execution phase

## **Phase 3: Automated Execution**

### **Python Script Execution**

#### **Dry Run (Always Test First)**

```bash
python3 production/scripts/python/duplicate_executor.py decisions.csv --dry-run --verbose

```

-   Shows exactly what will happen
-   No files are modified
-   Detailed operation preview

#### **Execute Real Operations**

```bash
python3 production/scripts/python/duplicate_executor.py decisions.csv --verbose

```

#### **Bash Script Alternative**

```bash
# Equivalent bash implementation
./production/scripts/execute_duplicate_actions.sh decisions.csv --dry-run
./production/scripts/execute_duplicate_actions.sh decisions.csv --verbose

```

### **Operation Types**
| CSV Action |Script Behavior  |Safety|
|--|--|--|
|`DELETE_ORIGINAL`|Delete original, keep duplicate|✅ Backup created|
|`DELETE_DUPLICATE`|Delete duplicate, keep original|✅ Backup created|
|`DELETE_BOTH`|Delete both files|⚠️ Backup both files|
|`SOFTLINK_ORIGINAL`|Keep duplicate, soft link original→duplicate|✅ Backup original|
|`SOFTLINK_DUPLICATE`|Keep original, soft link duplicate→original|✅ Backup duplicate|
|`HARDLINK_ORIGINAL`|Keep duplicate, hard link original→duplicate|✅ Backup original|
|`HARDLINK_DUPLICATE`|Keep original, hard link duplicate→original|✅ Backup duplicate|


### **Execution Monitoring**

-   **Live Progress:** Row-by-row processing with status
-   **Statistics:** Counts for each operation type
-   **Error Handling:** Failed operations logged, execution continues
-   **Backup Location:** `~/tmp/2delete/duplicatesHandling/duplicate_backups/[TIMESTAMP]/`

## **Phase 4: Rollback & Safety**

### **Automatic Rollback Data**

Every execution creates rollback data:

-   **Location:** `~/tmp/2delete/duplicatesHandling/duplicate_rollback.json`
-   **Contains:** All operation details + backup file locations
-   **Format:** Machine-readable JSON with timestamps

### **Rollback Operations**

#### **Full Rollback**

```bash
python3 production/scripts/python/rollback_duplicates.py ~/tmp/2delete/duplicatesHandling/duplicate_rollback.json --dry-run
python3 production/scripts/python/rollback_duplicates.py ~/tmp/2delete/duplicatesHandling/duplicate_rollback.json

```

#### **Selective Rollback**

```bash
# Only rollback delete operations
python3 production/scripts/python/rollback_duplicates.py rollback.json --operation-type delete

# Only rollback operations after specific time
python3 production/scripts/python/rollback_duplicates.py rollback.json --after 2025-08-15T14:00:00

# Only rollback specific operation types
python3 production/scripts/python/rollback_duplicates.py rollback.json --operation-type softlink --operation-type hardlink

```

### **Manual Rollback (Bash)**

For bash script operations, rollback commands are in: `~/tmp/2delete/duplicatesHandling/duplicate_rollback.log`

## **Advanced Workflows**

### **Large Dataset Processing**

1.  **Sort by size** (column F) - process largest duplicates first
2.  **Filter by path** (Ctrl+9) - handle one folder at a time
3.  **Partial execution** - export subsets, execute in batches
4.  **Statistics monitoring** (Ctrl+7) - track progress regularly

### **Cross-Device File Management**

-   Hard links automatically detect filesystem boundaries
-   Cross-device hard links skipped with warning
-   Soft links work across any filesystem
-   Delete operations work universally

### **Batch Processing Example**

```bash
# Process multiple scan results
for scan in *.json; do
    ./production/scripts/czkawka_to_table.sh "$scan" /main/folder "${scan%.*}.csv"
done

# Execute all decision files
for decisions in *_decisions.csv; do
    python3 production/scripts/python/duplicate_executor.py "$decisions" --verbose
done

```

## **Troubleshooting**

### **LibreOffice Issues**

-   **Macro not working:** Check macro security settings, verify named range exists
-   **Shortcuts not working:** Re-assign in Tools → Customize → Keyboard
-   **File managers won't open:** Install nemo/krusader, check paths in macro

### **Execution Issues**

-   **Permission denied:** Check file/directory write permissions
-   **Cross-device hard link:** Use soft link instead, or copy + delete
-   **File not found:** Verify CSV paths are absolute and current

### **Rollback Issues**

-   **Backup not found:** Check if backups were created (dry-run mode doesn't create backups)
-   **Cannot restore:** Verify target directory permissions and free space

## **Best Practices**

1.  **Always test with --dry-run first**
2.  **Process large files first** (sort by size)
3.  **Review statistics regularly** (Ctrl+7)
4.  **Keep rollback data** until satisfied with results
5.  **Filter by criteria** to focus on specific areas
6.  **Export filtered decisions** for targeted cleanup
7.  **Monitor disk space** during operations

This completes your daily workflow reference. The pipeline provides comprehensive safety and flexibility for any duplicate file management scenario.

