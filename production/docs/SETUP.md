
# Setup Guide - Czkawka Duplicates Tools

Complete installation and configuration for the duplicate file management pipeline.

## 🖥️ System Requirements

### Operating System
- **Primary**: Linux Mint (tested - full functionality)
- **Alternative**: Any OS with Python 3.6+ (Python engine only)

### Core Dependencies
```bash
# Essential packages
sudo apt update
sudo apt install -y libreoffice-calc nemo python3 python3-pip jq

# Optional dual-pane file manager
sudo apt install -y krusader

# Verify Python version (3.6+ required)
python3 --version
```

### Czkawka Installation
#### Method 1: Direct Download
Download one of the precompiled binaries from https://github.com/qarmin/czkawka/releases make it executable, move it to the working dir or to /usr/local/bin/ or to ~/.local/bin/ and use it.
```bash
# Make executable and move to /usr/local/bin/
chmod +x linux_czkawka_cli
sudo mv linux_czkawka_cli /usr/local/bin/
```
**Or:**
#### Method 2: Build from Source
Follow instructions under 'Usage, installation, compilation, requirements, license' in the  `README.md` file. 

### Verification
```bash
# Test Czkawka installation
linux_czkawka_cli --version

# Test file managers
nemo --version
krusader --version  # Optional
```

## 📁 Repository Setup

### Clone and Configure
```bash
git clone https://github.com/banosv/czkawka-duplicates-tools.git
cd czkawka-duplicates-tools

# Make scripts executable
chmod +x production/scripts/*.sh
chmod +x production/scripts/python/*.py
```

### Directory Structure Verification
```bash
# Verify complete structure
tree production/
# Should show:
# ├── LO-calc/
# │   ├── duplicates.ods
# │   └── duplicates.ods.macros.txt
# ├── scripts/
# │   ├── czkawkaDupFind.sh
# │   ├── czkawka_to_table.sh
# │   ├── execute_duplicate_actions.sh
# │   ├── launch_krusader.sh
# │   └── python/
# │       ├── duplicate_executor.py
# │       └── rollback_duplicates.py
# └── docs/
#     ├── SETUP.md
#     └── USAGE.md
```

## 🧮 LibreOffice Configuration

### Enable Macro Security
1. Open LibreOffice
2. Navigate: **Tools → Options → LibreOffice → Security → Macro Security**
3. Two options: 
	- A. Add the macro location to the Trusted Sources (the subfolder containing `duplicates.ods` or one of the parent folders) 
	or  
	- B. Set security level to **Medium** or **Low**
4.  Click **OK** and restart LibreOffice

### Import Macro System
1. Open `production/LO-calc/duplicates.ods`
2. Navigate: **Tools → Macros → Organize Macros → Basic**
3. Click **My Macros → Organizer → Modules → Import**
4. Import: `production/LO-calc/duplicates.ods.macros.txt`
5. Save and close macro editor

### Create Named Range (CRITICAL)
1. In LibreOffice Calc: **Sheet → Named Ranges and Expressions → Define**
2. Create named range **"fullData"**:
   - **Name**: `fullData`
   - **Range**: `$duplicates.$A$2:$K$100000`
   - Click **OK**

### Configure Keyboard Shortcuts
Navigate: **Tools → Customize → Keyboard**

**File Manager Integration:**
- **F3** → `OpenInNemoFromActiveCell`
- **Alt+F3** → `OpenInKrusaderFromActiveCell`

**Basic Decision Marking:**
- **Ctrl+3** → `MarkKeepOriginal`
- **Ctrl+4** → `MarkKeepDuplicate`
- **Ctrl+6** → `MarkNeedsReview`

**Advanced Linking Options:**
- **Alt+3** → `MarkSoftLinkOriginal`
- **Alt+4** → `MarkSoftLinkDuplicate`
- **Ctrl+Alt+3** → `MarkHardLinkOriginal`
- **Ctrl+Alt+4** → `MarkHardLinkDuplicate`

**Utility Functions:**
- **Ctrl+7** → `ShowStatistics`
- **Ctrl+8** → `ClearDecisions`
- **Ctrl+9** → `ToggleFilterByActiveCell`
- **Ctrl+0** → `ClearFilterState`

### Optional: External Krusader Script Configuration
If using enhanced Krusader integration:

1. Edit the macro file or directly in LibreOffice:
2. Find the `LaunchKrusader` function
3. Update `scriptPath` variable:
   ```vb
   scriptPath = "/full/path/to/czkawka-duplicates-tools/production/scripts/launch_krusader.sh"
   ```

## 🗂️ Working Directory Structure

The system automatically creates this structure:

```bash
~/tmp/2delete/duplicatesHandling/
├── duplicate_backups/          # Timestamped backup folders
│   └── 20250816_143022/       # Automatic backups by session
├── duplicate_actions.log       # Detailed operation log
└── duplicate_rollback.json     # Python rollback data
└── duplicate_rollback.log      # Bash rollback commands
```

## ✅ Installation Verification

### Test Complete Pipeline
```bash
# 1. Test duplicate detection
./production/scripts/czkawkaDupFind.sh /home/$USER/test_folder test_scan

# 2. Test CSV conversion (replace /home/$USER/test_folder with your path)
./production/scripts/czkawka_to_table.sh test_scan.json /home/$USER/test_folder test.csv

# 3. Test LibreOffice integration
# - Open duplicates.ods
# - Import test.csv at cell B3
# - Test keyboard shortcuts on a data row (F3, Ctrl+3, etc.)

# 4. Test Python execution (dry run)
python3 production/scripts/python/duplicate_executor.py test.csv --dry-run --verbose

# 5. Test Bash execution (dry run)
./production/scripts/execute_duplicate_actions.sh test.csv --dry-run --verbose

# 6. Test rollback capability
python3 production/scripts/python/rollback_duplicates.py ~/tmp/2delete/duplicatesHandling/duplicate_rollback.json --dry-run
```

### Verify File Manager Integration
```bash
# Test file managers can be launched
nemo /home/$USER &
krusader &  # If installed

# Kill test processes
pkill nemo
pkill krusader
```

## 🔧 Troubleshooting

### Common Issues

#### Macro Problems
- **Macros not executing**: Check macro security settings (Medium/Low required)
- **Named range missing**: Verify "fullData" range exists and spans A2:K100000
- **Keyboard shortcuts not working**: Re-assign in Tools → Customize → Keyboard

#### Script Permission Issues
```bash
# Fix if scripts won't execute
chmod +x production/scripts/*.sh
chmod +x production/scripts/python/*.py

# Check script syntax
bash -n production/scripts/czkawkaDupFind.sh
```

#### File Manager Issues
```bash
# Install missing file managers
sudo apt install nemo krusader

# Test manual launch
nemo /tmp
krusader --left=/tmp --right=/home
```

#### Python Environment Issues
```bash
# Verify Python version
python3 --version  # Should be 3.6+

# Scripts use only standard library - no pip packages needed
# If issues persist, try:
python3 -c "import csv, json, logging, pathlib; print('Python environment OK')"
```

#### Czkawka Issues
```bash
# Verify Czkawka installation
which linux_czkawka_cli
linux_czkawka_cli --help

# If snap installation has issues:
sudo snap refresh czkawka
```

### Performance Optimization

#### Large Dataset Handling
- **Memory**: Ensure adequate RAM for LibreOffice with large CSVs
- **Disk Space**: Backup directory needs space equal to largest files
- **Processing**: Use filtering to work with data subsets

#### LibreOffice Optimization
```bash
# Increase LibreOffice memory allocation
# Edit: ~/.config/libreoffice/4/user/registrymodifications.xcu
# Add: <item oor:path="/org.openoffice.Office.Common/Cache">
#        <prop oor:name="GraphicManager" oor:type="xs:int"><value>128</value></prop>
#      </item>
```

## 🚀 Ready to Use

Once setup is complete:

1. **Verify all components** using the test pipeline above
2. **Create your first scan** with `czkawkaDupFind.sh`
3. **Process in LibreOffice** using the macro shortcuts
4. **Execute decisions** with either Python or Bash engine
5. **Monitor backups** and rollback capabilities

For daily workflow procedures, see: [USAGE.md](USAGE.md)

For detailed LibreOffice macro documentation, see: [LO-help.md](../LO-calc/LO-help.md)

---

**Next Steps**: After successful setup, proceed to the [Usage Guide](USAGE.md) for daily workflow procedures.

