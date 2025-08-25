# Daily Workflow - Czkawka Duplicates Tools

Complete reference for the duplicate file management workflow using all pipeline components.

## 🔄 Complete Workflow Overview

```
Phase 1: Detection → Phase 2: Analysis → Phase 3: Execution → Phase 4: Verification
```

## Phase 1: Duplicate Detection

### Scan for Duplicates
```bash
# Interactive mode (recommended for beginners)
./production/scripts/czkawkaDupFind.sh

# Direct command with parameters
./production/scripts/czkawkaDupFind.sh /path/to/scan output_name

# Format options: -p (JSON, default) or -f (human-readable text)
```

**Example:**
```bash
./production/scripts/czkawkaDupFind.sh /home/user/Documents docs_scan
# Creates: docs_scan.json
```

### Convert to Analysis Format
```bash
# Interactive mode
./production/scripts/czkawka_to_table.sh

# Direct command  
./production/scripts/czkawka_to_table.sh scan.json /main/folder output.csv
```

**Example:**
```bash
./production/scripts/czkawka_to_table.sh docs_scan.json /home/user/Documents docs_analysis.csv
# Creates CSV with Documents folder files prioritized
```

## Phase 2: Analysis & Decision Making

### LibreOffice Workflow

#### Data Import Process
1. Open `production/LO-calc/duplicates.ods`
2. **Import CSV at cell B3** (preserves headers in Row 2)
3. (optional) Sort by Size column (F) to prioritize large duplicates or sort by other column or criteria
4. Verify data spans the predefined named range

#### File Comparison & Decision Making
[In the spreadsheet structure left is considered as original - right as duplicates]
| Action | Shortcut | Result | Use Case |
|--------|----------|--------|----------|
| **View Files** | F3 / Alt+F3 | Open both locations in file manager | Compare file quality/location |
| **Keep Original** | Ctrl+3 | 🟢 Green = Keep, 🔴 Red = Delete | Original is better |
| **Keep Duplicate** | Ctrl+4 | 🔴 Red = Delete, 🟢 Green = Keep | Duplicate is better |
| **Soft Link** | Alt+3 / Alt+4 | 🟢 Keep, 🔵 Blue = Link | Save space, preserve paths |
| **Hard Link** | Ctrl+Alt+3/4 | 🟢 Keep, 🔷 Teal = Hard Link | Same filesystem only |
| **Review Later** | Ctrl+6 | 🟡 Yellow = Review | Need more analysis |

*Full macro documentation: [LO-help.md](../LO-calc/LO-help.md)*

#### Progress Management
| Shortcut | Function | Purpose |
|----------|----------|---------|
| **Ctrl+7** | Show Statistics | Check completion percentage |
| **Ctrl+9** | Toggle Filter by Active Cell | Focus on specific criteria |
| **Ctrl+0** | Clear Filters | Show all data again |
| **Ctrl+8** | Clear Decisions | Reset selected rows |

#### Export Decisions
1. Filter by Action column to review cleanup plan
2. Resolve any "REVIEW_NEEDED" items and finalize decisions
4. Export to CSV: **File → Save As → CSV**
5. Save as `decisions.csv` for execution phase

## Phase 3: Automated Execution

### Choose Your Execution Engine

#### Python Engine (Recommended - Cross-Platform)
```bash
# Always test first
python3 production/scripts/python/duplicate_executor.py decisions.csv --dry-run --verbose

# Execute real operations
python3 production/scripts/python/duplicate_executor.py decisions.csv --verbose
```

#### Bash Engine (Linux Performance)
```bash
# Always test first
./production/scripts/execute_duplicate_actions.sh decisions.csv --dry-run --verbose

# Execute real operations
./production/scripts/execute_duplicate_actions.sh decisions.csv --verbose
```

### Operation Types & Safety
| CSV Action | Script Behavior | Safety Features |
|------------|-----------------|-----------------|
| `DELETE_ORIGINAL` | Delete original, keep duplicate | ✅ Backup created |
| `DELETE_DUPLICATE` | Delete duplicate, keep original | ✅ Backup created |
| `SOFTLINK_*` | Create symbolic link | ✅ Backup original file |
| `HARDLINK_*` | Create hard link (same filesystem) | ✅ Backup + filesystem check |

### Execution Monitoring
- **Live Progress**: Row-by-row processing with status
- **Statistics**: Counts for each operation type  
- **Error Handling**: Failed operations logged, execution continues
- **Backup Location**: `~/tmp/2delete/duplicatesHandling/duplicate_backups/[TIMESTAMP]/`

## Phase 4: Rollback & Recovery

### Python Rollback System
```bash
# Full rollback
python3 production/scripts/python/rollback_duplicates.py ~/tmp/2delete/duplicatesHandling/duplicate_rollback.json --dry-run

# Selective rollback by operation type
python3 production/scripts/python/rollback_duplicates.py rollback.json --operation-type delete

# Rollback operations after specific time
python3 production/scripts/python/rollback_duplicates.py rollback.json --after 2025-08-15T14:00:00
```

### Bash Rollback System
```bash
# Direct execution of rollback commands
bash ~/tmp/2delete/duplicatesHandling/duplicate_rollback.log
```

## 🎯 Best Practices

### Workflow Optimization
1. **Sort by file size** (column F) - process largest duplicates first
2. **Filter by path** (Ctrl+9) - handle one folder at a time  
3. **Use statistics** (Ctrl+7) - track progress regularly
4. **Always dry-run first** - test before real execution
5. **Keep rollback data** - until satisfied with results

### Large Dataset Processing
- **Partial execution**: Export filtered subsets, execute in batches
- **Progress monitoring**: Statistics show completion percentage
- **Memory management**: Process in chunks for very large datasets

### Cross-Device Considerations
- **Hard links**: Automatically detect filesystem boundaries
- **Soft links**: Work across any filesystem
- **Delete operations**: Work universally

## 🚨 Troubleshooting

### LibreOffice Issues
- **Macros not working**: Check security settings, verify named range exists
- **File managers won't open**: Install nemo/krusader, check macro paths
- **CSV import problems**: Import at B3, not A1 or B1

### Execution Issues  
- **Permission denied**: Check file/directory write permissions
- **Cross-device hard link**: Script will skip with warning, use soft link instead
- **File not found**: Verify CSV paths are absolute and files exist

### Recovery Issues
- **Backup not found**: Verify backups were created (dry-run doesn't create backups)
- **Cannot restore**: Check target directory permissions and available disk space

---

**Pipeline Summary**: Detection → Analysis → Execution → Verification  
**Safety First**: Always use `--dry-run` before real operations


