#!/bin/bash

echo "================================================"
echo "Linux Final Exam Script"
echo "Date: $(date)"
echo "================================================"

echo "Step 1: crond service..."
echo "checking crond..."

if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet crond 2>/dev/null; then
        echo "crond is running, attempting to stop..."
        echo "Note: You will be prompted for your password to stop crond service"
        if sudo systemctl stop crond 2>/dev/null; then
            echo "crond stopped successfully!"
        else
            echo "Warning: Could not stop crond (may be masked or protected)"
            echo "Attempting to mask crond service..."
            sudo systemctl mask crond 2>/dev/null
            echo "crond masked"
        fi
    elif systemctl is-masked crond 2>/dev/null; then
        echo "crond is already masked"
    elif systemctl is-enabled crond 2>/dev/null; then
        echo "crond is enabled but not running"
        echo "Note: You will be prompted for your password to disable crond service"
        sudo systemctl disable crond 2>/dev/null
        echo "crond disabled"
    else
        echo "crond service not found or not available"
    fi
    
    echo "saving crond status to ~/crond.status"
    systemctl status crond > ~/crond.status 2>&1
    echo "status saved!"
else
    echo "systemctl not available, checking crond process..."
    if pgrep crond >/dev/null 2>&1; then
        echo "crond process found, attempting to stop..."
        echo "Note: You will be prompted for your password to stop crond process"
        if sudo pkill crond 2>/dev/null; then
            echo "crond process stopped!"
        else
            echo "Warning: Could not stop crond process"
        fi
    else
        echo "crond process not running"
    fi
    
    echo "saving crond status to ~/crond.status"
    echo "systemctl not available" > ~/crond.status
    echo "crond process status: $(pgrep crond 2>/dev/null || echo 'not running')" >> ~/crond.status
    echo "status saved!"
fi

echo "Step 1 done!"
echo "----------------------------------------"

echo "Step 2: creating logs directory..."
echo "making folder logs-$(date +%d%m%Y)..."

mkdir -p ~/logs-$(date +%d%m%Y)

echo "changing group to final..."
echo "Note: You will be prompted for your password to change group ownership"
if sudo chgrp final ~/logs-$(date +%d%m%Y) 2>/dev/null; then
    echo "group changed to final successfully"
else
    echo "Warning: Could not change group to 'final'"
    echo "Attempting to create 'final' group if it doesn't exist..."
    sudo groupadd final 2>/dev/null
    sudo chgrp final ~/logs-$(date +%d%m%Y) 2>/dev/null
    echo "group set to final"
fi

echo "dir created: ~/logs-$(date +%d%m%Y)"
echo "group set to final"
echo "Step 2 done!"
echo "----------------------------------------"

echo "Step 3: setting permissions..."
echo "setting 770 permissions..."

chmod 770 ~/logs-$(date +%d%m%Y)

echo "setting setgid bit..."
echo "Note: You will be prompted for your password to set setgid bit"
if sudo chmod g+s ~/logs-$(date +%d%m%Y) 2>/dev/null; then
    echo "setgid bit set successfully"
else
    echo "Warning: Could not set setgid bit"
    echo "permissions set to 770 without setgid"
fi

echo "permissions set!"
echo "Step 3 done!"
echo "----------------------------------------"

echo "Step 4: creating 100 log files..."
echo "making files user1-$(date +%d%m%Y)-1.log to user1-$(date +%d%m%Y)-100.log"

for i in {1..100}; do
    touch ~/logs-$(date +%d%m%Y)/user1-$(date +%d%m%Y)-$i.log
done

echo "100 files created!"
echo "Step 4 done!"
echo "----------------------------------------"

echo "================================================"
echo "MAINTENANCE"
echo "================================================"

echo "Step 5: processing 0.log files..."

echo "making dir /tmp/user1-zerologs.d"
mkdir -p /tmp/user1-zerologs.d

echo "moving 0.log files..."
find ~/logs-$(date +%d%m%Y) -name "*0.log" -exec mv {} /tmp/user1-zerologs.d/ \;

echo "making symlink..."
ln -sf /tmp/user1-zerologs.d ~/logs-$(date +%d%m%Y)/zerologs

echo "symlink made: ~/logs-$(date +%d%m%Y)/zerologs -> /tmp/user1-zerologs.d"
echo "Step 5 done!"
echo "----------------------------------------"

echo "Step 6: starting process sampling..."
echo "sampling every 10 seconds"
echo "saving to log files"

(
    for sample in {1..100}; do
        log_num=$((sample * 10))
        if [ $log_num -le 100 ]; then
            target="/tmp/user1-zerologs.d/user1-$(date +%d%m%Y)-$log_num.log"
            echo "=== Sample $sample at $(date) ===" > "$target"
            ps aux --sort=-%cpu >> "$target" 2>/dev/null
            echo "sample $sample saved to $target"
        fi
        sleep 10
    done
) &

PID=$!
echo "sampling started PID: $PID"
echo "stop with: kill $PID"
echo "Step 6 done!"
echo "----------------------------------------"

echo "Step 7: getting polkitd info..."
echo "waiting for samples..."

sleep 30

echo "processing polkitd..."

POLKITD_FILE=~/polkitd_cpu_usage.log

> "$POLKITD_FILE"

for logfile in /tmp/user1-zerologs.d/*.log; do
    if [ -f "$logfile" ]; then
        echo "processing: $(basename "$logfile")"
        grep "polkitd" "$logfile" | sort -k3 -nr | awk '{print $3, $4}' >> "$POLKITD_FILE" 2>/dev/null
    fi
done

echo "polkitd data saved to ~/polkitd_cpu_usage.log"
echo "Step 7 done!"
echo "----------------------------------------"

echo "================================================"
echo "AUTOMATION"
echo "================================================"

echo "Step 8: making prep.sh script..."

cat > ~/prep.sh << 'EOF'
#!/bin/bash

echo "Prep Script"
echo "==========="

USER=$(whoami)
DATE=$(date +%d%m%Y)
DIR="$HOME/logs-$DATE"

echo "User: $USER"
echo "Date: $DATE"

echo "Step 1: crond..."
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet crond 2>/dev/null; then
        echo "stopping crond..."
        echo "Note: You will be prompted for your password to stop crond service"
        if sudo systemctl stop crond 2>/dev/null; then
            echo "crond stopped successfully!"
        else
            echo "Warning: Could not stop crond (may be masked or protected)"
            echo "Attempting to mask crond service..."
            sudo systemctl mask crond 2>/dev/null
            echo "crond masked"
        fi
    elif systemctl is-masked crond 2>/dev/null; then
        echo "crond is already masked"
    elif systemctl is-enabled crond 2>/dev/null; then
        echo "crond is enabled but not running"
        echo "Note: You will be prompted for your password to disable crond service"
        sudo systemctl disable crond 2>/dev/null
            echo "crond disabled"
    else
        echo "crond service not found or not available"
    fi
    
    echo "saving crond status..."
    systemctl status crond > ~/crond.status 2>&1
else
    echo "systemctl not available, checking crond process..."
    if pgrep crond >/dev/null 2>&1; then
        echo "stopping crond process..."
        echo "Note: You will be prompted for your password to stop crond process"
        if sudo pkill crond 2>/dev/null; then
            echo "crond process stopped!"
        else
            echo "Warning: Could not stop crond process"
        fi
    else
        echo "crond process not running"
    fi
    
    echo "saving crond status..."
    echo "systemctl not available" > ~/crond.status
    echo "crond process status: $(pgrep crond 2>/dev/null || echo 'not running')" >> ~/crond.status
fi

echo "Step 2: making dir..."
mkdir -p "$DIR"
echo "Note: You will be prompted for your password to change group ownership"
if sudo chgrp final "$DIR" 2>/dev/null; then
    echo "group changed to final successfully"
else
    echo "Warning: Could not change group to 'final'"
    echo "Attempting to create 'final' group if it doesn't exist..."
    sudo groupadd final 2>/dev/null
    sudo chgrp final "$DIR" 2>/dev/null
    echo "group set to final"
fi
echo "dir made: $DIR group final"

echo "Step 3: permissions..."
chmod 770 "$DIR"
echo "Note: You will be prompted for your password to set setgid bit"
if sudo chmod g+s "$DIR" 2>/dev/null; then
    echo "setgid bit set successfully"
else
    echo "Warning: Could not set setgid bit"
    echo "permissions set to 770 without setgid"
fi
echo "permissions 770 + setgid"

echo "Step 4: making files..."
for i in {1..100}; do
    touch "$DIR/$USER-$DATE-$i.log"
done
echo "100 files made in $DIR"

echo "prep done!"
EOF

chmod +x ~/prep.sh
echo "prep.sh made at ~/prep.sh"
echo "script ready!"
echo "Step 8 done!"
echo "----------------------------------------"

echo "================================================"
echo "DONE!"
echo "================================================"
echo "all requirements completed!"
echo ""
echo "created:"
echo "- logs dir: ~/logs-$(date +%d%m%Y)"
echo "- zerologs: /tmp/user1-zerologs.d"
echo "- symlink: ~/logs-$(date +%d%m%Y)/zerologs"
echo "- crond status: ~/crond.status"
echo "- polkitd file: ~/polkitd_cpu_usage.log"
echo "- prep script: ~/prep.sh"
echo ""
echo "sampling running PID: $PID"
echo "stop: kill $PID"
echo ""
echo "script done!"
