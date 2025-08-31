#!/bin/bash

echo "================================================"
echo "EXAM REQUIREMENTS VERIFICATION"
echo "================================================"

CURRENT_DATE=$(date +%d%m%Y)
USERNAME="user1"
LOGS_DIR="$HOME/logs-$CURRENT_DATE"
ZEROLOGS_DIR="/tmp/$USERNAME-zerologs.d"
CROND_STATUS_FILE="$HOME/crond.status"
POLKITD_FILE="$HOME/polkitd_cpu_usage.log"
PREP_SCRIPT="$HOME/prep.sh"

PASSED=0
FAILED=0
TOTAL=0

echo "Verifying requirements for user: $USERNAME"
echo "Current date: $CURRENT_DATE"
echo ""

check_requirement() {
    local description="$1"
    local condition="$2"
    local expected="$3"
    
    TOTAL=$((TOTAL + 1))
    
    if eval "$condition"; then
        echo "✅ PASS: $description"
        echo "   Expected: $expected"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL: $description"
        echo "   Expected: $expected"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

echo "=== PREP STAGE VERIFICATION (40%) ==="

check_requirement \
    "Crond status file exists" \
    "[ -f \"$CROND_STATUS_FILE\" ]" \
    "File $CROND_STATUS_FILE should exist"

check_requirement \
    "Logs directory exists" \
    "[ -d \"$LOGS_DIR\" ]" \
    "Directory $LOGS_DIR should exist"

check_requirement \
    "Logs directory group is 'final'" \
    "[ \"$(stat -c %G \"$LOGS_DIR\" 2>/dev/null || stat -f %Sg \"$LOGS_DIR\" 2>/dev/null)\" = \"final\" ]" \
    "Group ownership should be 'final'"

check_requirement \
    "Logs directory permissions are 770" \
    "[ \"$(stat -c %a \"$LOGS_DIR\" 2>/dev/null || stat -f %Lp \"$LOGS_DIR\" 2>/dev/null)\" = \"770\" ]" \
    "Permissions should be 770 (rwxrwx---)"

check_requirement \
    "Logs directory has setgid bit" \
    "[ \"$(stat -c %A \"$LOGS_DIR\" 2>/dev/null | grep -q 's' || stat -f %Sp \"$LOGS_DIR\" 2>/dev/null | grep -q 's')\" ]" \
    "Setgid bit should be set for group inheritance"

check_requirement \
    "100 log files exist" \
    "[ \$(find \"$LOGS_DIR\" -name \"*.log\" | wc -l) -eq 100 ]" \
    "Exactly 100 .log files should exist"

check_requirement \
    "Log files follow naming convention" \
    "[ \$(find \"$LOGS_DIR\" -name \"$USERNAME-$CURRENT_DATE-*.log\" | wc -l) -eq 100 ]" \
    "Files should be named: $USERNAME-$CURRENT_DATE-{1..100}.log"

echo "=== MAINTENANCE VERIFICATION (40%) ==="

check_requirement \
    "Zerologs directory exists" \
    "[ -d \"$ZEROLOGS_DIR\" ]" \
    "Directory $ZEROLOGS_DIR should exist"

check_requirement \
    "Symbolic link exists" \
    "[ -L \"$LOGS_DIR/zerologs\" ]" \
    "Symbolic link should exist at $LOGS_DIR/zerologs"

check_requirement \
    "Symbolic link points to correct location" \
    "[ \"$(readlink \"$LOGS_DIR/zerologs\")\" = \"$ZEROLOGS_DIR\" ]" \
    "Link should point to $ZEROLOGS_DIR"

check_requirement \
    "Process sampling files exist" \
    "[ \$(find \"$ZEROLOGS_DIR\" -name \"*.log\" | wc -l) -gt 0 ]" \
    "At least some process sampling files should exist"

check_requirement \
    "Polkitd CPU usage file exists" \
    "[ -f \"$POLKITD_FILE\" ]" \
    "File $POLKITD_FILE should exist"

echo "=== AUTOMATION VERIFICATION (20%) ==="

check_requirement \
    "Prep.sh script exists" \
    "[ -f \"$PREP_SCRIPT\" ]" \
    "File $PREP_SCRIPT should exist"

check_requirement \
    "Prep.sh script is executable" \
    "[ -x \"$PREP_SCRIPT\" ]" \
    "Script should be executable"

check_requirement \
    "Prep.sh script has correct shebang" \
    "head -1 \"$PREP_SCRIPT\" | grep -q '^#!/bin/bash'" \
    "Script should start with #!/bin/bash"

echo "=== DETAILED CHECKS ==="

echo "Checking file contents and structure..."
echo ""

if [ -f "$CROND_STATUS_FILE" ]; then
    echo "📄 Crond status file content (first 3 lines):"
    head -3 "$CROND_STATUS_FILE" | sed 's/^/   /'
    echo ""
fi

if [ -d "$LOGS_DIR" ]; then
    echo "📁 Logs directory contents (first 10 files):"
    ls -la "$LOGS_DIR" | head -11 | sed 's/^/   /'
    echo ""
fi

if [ -d "$ZEROLOGS_DIR" ]; then
    echo "📁 Zerologs directory contents (first 10 files):"
    ls -la "$ZEROLOGS_DIR" | head -11 | sed 's/^/   /'
    echo ""
fi

if [ -L "$LOGS_DIR/zerologs" ]; then
    echo "🔗 Symbolic link details:"
    echo "   Link: $LOGS_DIR/zerologs"
    echo "   Target: $(readlink "$LOGS_DIR/zerologs")"
    echo "   Permissions: $(ls -la "$LOGS_DIR/zerologs" | awk '{print $1, $3, $4}')"
    echo ""
fi

if [ -f "$POLKITD_FILE" ]; then
    echo "📊 Polkitd CPU usage file content (first 5 lines):"
    head -5 "$POLKITD_FILE" | sed 's/^/   /'
    echo ""
fi

if [ -f "$PREP_SCRIPT" ]; then
    echo "📜 Prep.sh script content (first 10 lines):"
    head -10 "$PREP_SCRIPT" | sed 's/^/   /'
    echo ""
fi

echo "=== VERIFICATION SUMMARY ==="
echo "Total Requirements: $TOTAL"
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo ""

if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((PASSED * 100 / TOTAL))
    echo "Success Rate: $PERCENTAGE%"
    
    if [ $PERCENTAGE -eq 100 ]; then
        echo "🎉 ALL REQUIREMENTS PASSED! Exam is complete."
    elif [ $PERCENTAGE -ge 80 ]; then
        echo "👍 Most requirements passed. Minor issues to fix."
    elif [ $PERCENTAGE -ge 60 ]; then
        echo "⚠️  Several requirements failed. Need to review."
    else
        echo "❌ Many requirements failed. Major issues to address."
    fi
else
    echo "No requirements were checked."
fi

echo ""
echo "================================================"
echo "Verification complete!"
echo "================================================"
