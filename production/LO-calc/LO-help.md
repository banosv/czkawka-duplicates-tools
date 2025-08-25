# LibreOffice Calc - Duplicate Analysis Macros

Complete reference for the enhanced macro system in `duplicates.ods`.

## 📊 Spreadsheet Structure

### Column Layout
| Column | Name | Description | Features |
|--------|------|-------------|----------|
| **A** | Checkbox | Progress tracking | `[>0]"☑";[=0]"☐"` format |
| **B** | OriginalFolder | Path to original file | Conditional formatting |
| **C** | OriginalFile | Original filename | Conditional formatting |  
| **D** | DuplicateFolder | Path to duplicate file | Conditional formatting |
| **E** | DuplicateFile | Duplicate filename | Conditional formatting |
| **F** | Size | File size in bytes | Sorting/filtering optimized |
| **G** | Hash | File verification hash | Data integrity checking |
| **H** | KeepOrig | Keep original decision | Color coded decisions |
| **I** | KeepDup | Keep duplicate decision | Color coded decisions |
| **J** | Action | Generated action type | 7 specific action types |
| **K** | NOTES | User documentation | Free-form decision notes |

### Protected Rows System ⚠️
- **Row 1**: PROTECTED - Reserved for subtotals/summary formulas
- **Row 2**: PROTECTED - Reserved for column headers  
- **Row 3+**: Data rows where all operations are performed
- **A1 Cell**: Filter state indicator (shows "FILTERED: [value]")

### Data Import Process
1. Open `duplicates.ods`
2. **Import CSV starting at cell B3** (preserves Row 2 headers)
3. Column A available for manual checkbox progress tracking
4. Row 1 available for summary formulas (e.g., `=SUM(F3:F1000)`or `=SUBTOTAL(9; F3:F1000)`)

## ⌨️ Complete Keyboard Shortcuts

### File Manager Integration
| Shortcut | Function | Description |
|----------|----------|-------------|
| **F3** | OpenInNemoFromActiveCell | Nemo → Krusader → System fallback |
| **Alt+F3** | OpenInKrusaderFromActiveCell | Krusader → Nemo → System fallback |

### Basic Decision Marking
| Shortcut | Function | Colors | Action Generated |
|----------|----------|--------|------------------|
| **Ctrl+3** | MarkKeepOriginal | 🟢 Green / 🔴 Red | DELETE_DUPLICATE |
| **Ctrl+4** | MarkKeepDuplicate | 🔴 Red / 🟢 Green | DELETE_ORIGINAL |
| **Ctrl+6** | MarkNeedsReview | 🟡 Yellow | REVIEW_NEEDED |

### Advanced Linking Options
| Shortcut | Function | Colors | Action Generated |
|----------|----------|--------|------------------|
| **Alt+3** |MarkSoftLinkDuplicate  | 🟢 Green / 🔵 Blue | SOFTLINK_DUPLICATE |
| **Alt+4** | MarkSoftLinkOriginal | 🔵 Blue / 🟢 Green | SOFTLINK_ORIGINAL |
| **Ctrl+Alt+3** | MarkHardLinkDuplicate | 🟢 Green / 🔷 Teal | HARDLINK_DUPLICATE |
| **Ctrl+Alt+4** | MarkHardLinkOriginal | 🔷 Teal / 🟢 Green | HARDLINK_ORIGINAL |

### Utility Functions
| Shortcut | Function | Description |
|----------|----------|-------------|
| **Ctrl+7** | ShowStatistics | Progress tracking with completion % |
| **Ctrl+8** | ClearDecisions | Reset selected rows (skips protected rows) |
| **Ctrl+9** | ToggleFilterByActiveCell | Smart filter by cell content |
| **Ctrl+0** | ClearFilterState | Clear all active filters |

## 🎨 Complete Color Coding System

| Decision Type | Original (H) | Duplicate (I) | Generated Action | Purpose |
|---------------|--------------|---------------|------------------|---------|
| Keep Original | 🟢 Green | 🔴 Red | DELETE_DUPLICATE | Original is better |
| Keep Duplicate | 🔴 Red | 🟢 Green | DELETE_ORIGINAL | Duplicate is better |
| Needs Review | 🟡 Yellow | 🟡 Yellow | REVIEW_NEEDED | Complex case |
| Soft Link (Dup) | 🟢 Green | 🔵 Blue | SOFTLINK_DUPLICATE | Save space, preserve paths |
| Soft Link (Orig) | 🔵 Blue | 🟢 Green | SOFTLINK_ORIGINAL | Save space, preserve paths |
| Hard Link (Dup) | 🟢 Green | 🔷 Teal | HARDLINK_DUPLICATE | Save space, same filesystem |
| Hard Link (Orig) | 🔷 Teal | 🟢 Green | HARDLINK_ORIGINAL | Save space, same filesystem |

**RGB Values**: Green (144,238,144), Red (255,182,193), Yellow (255,255,180), Blue (173,216,230), Teal (176,224,230)

## 🔄 Workflow Process

### Efficient Processing Sequence
1. **Sort by file size** (Column F) to prioritize large duplicates
2. **For each duplicate pair**:
   - Press **F3** or **Alt+F3** to compare files
   - Make decision using appropriate shortcut
   - **Macro auto-advances** to next row
   - Optionally mark checkbox in Column A (any positive number → ☑)
   - Add notes in Column K if needed

### Advanced Analysis Features
- **Conditional Formatting**: Matching filenames/paths appear as hyperlinks
- **Smart Filtering**: Ctrl+9 filters any column by active cell content
- **Filter State Management**: A1 shows current filter status  
- **Progress Tracking**: Visual checkboxes and statistical analysis
- **Bulk Operations**: Select ranges for mass decision clearing

### Statistics Display (Ctrl+7)
- **Decision Counts**: DELETE/LINK operations by type
- **Progress Tracking**: Processed vs. unprocessed rows
- **Completion Percentage**: Visual progress indicator
- **Next Steps Guidance**: Workflow recommendations

### Filtering System (Ctrl+9)
- **Any Column**: Filter by active cell content using `=` equal operator (no RegEx used)
- **State Persistence**: Filter status saved in A1
- **Quick Toggle**: Same shortcut enables/disables filter
- **Visual Feedback**: Clear indication of active filters

## ⚙️ Setup Requirements

### LibreOffice Configuration
1. **Macro Security**: Two options: 
	- A. Add the macro location to the Trusted Sources (the subfolder containing `duplicates.ods` or one of the parent folders) 
	or  
	- B. Set security level to **Medium** or **Low** [Tools → Options → LibreOffice → Security → Macro Security (Medium/Low)]
2. **Named Range**: Create "fullData" range: `$duplicates.$A$2:$K$100000`
3. **Keyboard Shortcuts**: Tools → Customize → Keyboard
   - Assign all 12 shortcuts listed above
4. **Macro Import**: Tools → Macros → Organize Macros → Basic
   - Import `duplicates.ods.macros.txt`

### File Manager Integration
- **Primary**: `sudo apt install nemo` (tab support, file selection)
- **Optional**: `sudo apt install krusader` (dual-pane interface)
- **Script Path**: Configure in macro for enhanced Krusader integration

### External Script Configuration
Edit the `LaunchKrusader` function to match your installation:
```vb
scriptPath = "~/opt/czkawka-cli/production/scripts/launch_krusader.sh"
```

## 🛡️ Safety Features

### Protected Row System
- **Automatic Protection**: Macros refuse to operate on Rows 1-2
- **Clear Warnings**: User notification when attempting protected operations
- **Data Integrity**: Headers and subtotals cannot be accidentally modified

### Validation System
- **Data Completeness**: Checks for required path/filename data
- **File Existence**: Validates paths before file manager operations
- **Error Recovery**: Graceful handling of missing files or invalid operations

### Progress Management
- **Auto-Advancement**: Cursor moves to next row after decisions
- **Bulk Clearing**: Mass reset operations with protected row skipping
- **Visual Feedback**: Immediate color coding for all decisions

## 🚨 Troubleshooting

### Common Issues
- **Macros not working**: Check macro security settings (Medium/Low required)
- **Shortcuts not responding**: Re-assign in Tools → Customize → Keyboard
- **File managers won't open**: Install nemo/krusader, verify paths
- **Protected row errors**: Only operate on Row 3 and below

### Data Import Problems
- **Wrong starting cell**: Import CSV at B3, not A1 or B1
- **Named range missing**: Create "fullData" range covering A2:K100000
- **Headers overwritten**: Row 2 contains column headers, preserve them

### Performance Optimization
- **Large datasets**: Use filtering to process subsets
- **Memory usage**: Named range limits reduce calculation overhead
- **Visual updates**: Disable screen updating during bulk operations

---

**Essential Workflow**: Import → Sort → Compare → Decide → Export  
**Key Principle**: Protected rows ensure data integrity throughout analysis

