# Setup Guide - Czkawka Duplicates Tools

Complete installation and configuration for the duplicate file management pipeline.

## **System Requirements**

### **Core Dependencies**
```bash
# Essential packages
sudo apt update
sudo apt install -y libreoffice-calc nemo python3 python3-pip jq

# Optional dual-pane file manager
sudo apt install -y krusader

# Czkawka installation (choose one method)
# Method 1: Snap package
sudo snap install czkawka

# Method 2: Direct download from GitHub releases
# See: https://github.com/qarmin/czkawka/releases

```

### **Python Environment**

```bash
# Verify Python 3.6+ 
python3 --version

# Scripts use standard library only - no additional pip packages needed

```

## **Repository Setup**

### **1. Clone and Configure**

```bash
git clone https://github.com/banosv/czkawka-duplicates-tools.git
cd czkawka-duplicates-tools

# Make scripts executable
chmod +x production/scripts/*.sh
chmod +x production/scripts/python/*.py

```

### **2. LibreOffice Configuration**

#### **Enable Macros**

1.  Open LibreOffice
2.  Go to: **Tools → Options → LibreOffice → Security → Macro Security**
3.  Set security level to **Medium** or **Low**
4.  Restart LibreOffice

#### **Create Named Range (CRITICAL)**

1.  Open `production/LO-calc/duplicates.ods`
2.  Go to: **Sheet → Named Ranges and Expressions → Define**
3.  Create named range **"fullData"**:
    -   **Name:** `fullData`
    -   **Range:** `$duplicates.$A$2:$K$100000`
    -   Click **OK**

#### **Import Macro v0.5**

1.  In LibreOffice Calc: **Tools → Macros → Organize Macros → Basic**
2.  Click **My Macros → Organizer → Modules → Import**
3.  Import: `production/LO-calc/duplicates.ods.macros.txt`
4.  Save and close

#### **Keyboard Shortcuts Setup**

Go to: **Tools → Customize → Keyboard** and assign:   

|Shortcut|Function  |Action|
|--|--|--|
|F3|OpenInNemoFromActiveCell|Open files in Nemo|
|Alt+F3|OpenInKrusaderFromActiveCell|Open files in Krusader|
|Ctrl+3|MarkKeepOriginal|Keep original, delete duplicate|
|Ctrl+4|MarkKeepDuplicate|Keep duplicate, delete original|
|Ctrl+6|MarkNeedsReview|Mark for review|
|Alt+3|MarkSoftLinkOriginal|Soft link duplicate→original|
|Alt+4|MarkSoftLinkDuplicate|Soft link original→duplicate|
|Ctrl+Alt+3|MarkHardLinkOriginal|Hard link duplicate→original|
|Ctrl+Alt+4|MarkHardLinkDuplicate|Hard link original→duplicate|
|Ctrl+7|ShowStatistics|Show progress statistics|
|Ctrl+8|ClearDecisions|Clear marked decisions|
|Ctrl+9|ToggleFilterByActiveCell|Filter by cell content|
|Ctrl+0|ClearFilterState|Clear all filters|

## **Script Configuration**

### **Krusader Integration (Optional)**

If using the external Krusader script, verify the path in the macro:

1.  Edit macro function `LaunchKrusader`
2.  Update `scriptPath` variable to match your installation:
    
    ```vb
    scriptPath = "~/opt/czkawka-cli/production/scripts/launch_krusader.sh"
    
    ```
    

### **Working Directory Structure**

The Python scripts create this structure automatically:

```
~/tmp/2delete/duplicatesHandling/
├── duplicate_backups/          # Timestamped backup folders
│   └── 20250815_143022/       # Automatic backups by session
├── duplicate_actions.log       # Detailed operation log
└── duplicate_rollback.json     # Rollback data

```

## **Verification**

### **Test Complete Pipeline**

```bash
# 1. Test duplicate detection
./production/scripts/czkawkaDupFind.sh /home/user/test_folder test_scan

# 2. Test CSV conversion  
./production/scripts/czkawka_to_table.sh test_scan.json /home/user/test_folder test.csv

# 3. Test LibreOffice integration
# - Open duplicates.ods
# - Import test.csv at cell B3
# - Test keyboard shortcuts on a data row

# 4. Test Python execution (dry run)
python3 production/scripts/python/duplicate_executor.py test.csv --dry-run --verbose

# 5. Test rollback capability
python3 production/scripts/python/rollback_duplicates.py ~/tmp/2delete/duplicatesHandling/duplicate_rollback.json --dry-run

```

### **Troubleshooting**

**Macro Issues:**

-   Ensure named range "fullData" exists and spans A2:K100000
-   Check macro security settings allow execution
-   Verify keyboard shortcuts are properly assigned

**File Manager Issues:**

-   Install nemo: `sudo apt install nemo`
-   Test manual launch: `nemo /home/user`
-   For Krusader: `sudo apt install krusader`

**Script Permissions:**

```bash
# Fix if scripts won't execute
chmod +x production/scripts/*.sh
chmod +x production/scripts/python/*.py

```

**Python Issues:**

-   Verify Python 3.6+: `python3 --version`
-   Scripts use only standard library - no additional packages needed

## **Ready to Use**

Once setup is complete, proceed to the Usage Guide for daily workflow procedures.

