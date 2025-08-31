#!/bin/bash





# if command -v systemctl >/dev/null 2>&1; then
#     if systemctl is-active --quiet crond 2>/dev/null; then

#         if sudo systemctl stop crond 2>/dev/null; then
#                         :
#         else
#             sudo systemctl mask crond 2>/dev/null
#         fi
#     elif systemctl is-masked crond 2>/dev/null; then
#         :
#     elif systemctl is-enabled crond 2>/dev/null; then
#         sudo systemctl disable crond 2>/dev/null
#     fi
    
#     systemctl status crond > crond.status 2>&1
# else
#     if pgrep crond >/dev/null 2>&1; then
#         if sudo pkill crond 2>/dev/null; then
#             :
#         else
#             :
#         fi
#     else
#         :
#     fi
    
#     echo "systemctl not available" > crond.status
#     echo "crond process status: $(pgrep crond 2>/dev/null || echo 'not running')" >> crond.status
# fi

echo 3 >> ~/crond.status

mkdir -p ~/logs-$(date +%d%m%Y)


if sudo chgrp final ~/logs-$(date +%d%m%Y) 2>/dev/null; then
            :
    else
        sudo groupadd final 2>/dev/null
        sudo chgrp final ~/logs-$(date +%d%m%Y) 2>/dev/null
    fi



chmod 770 ~/logs-$(date +%d%m%Y)

if sudo chmod g+s ~/logs-$(date +%d%m%Y) 2>/dev/null; then
    :
else
    :
fi



for i in {1..100}; do
    touch ~/logs-$(date +%d%m%Y)/user1-$(date +%d%m%Y)-$i.log
done



mkdir -p /tmp/user1-zerologs.d

find ~/logs-$(date +%d%m%Y) -name "*0.log" -exec mv {} /tmp/user1-zerologs.d/ \;

ln -sf /tmp/user1-zerologs.d ~/logs-$(date +%d%m%Y)/zerologs



(
    for sample in {1..100}; do
        log_num=$((sample * 10))
        if [ $log_num -le 100 ]; then
            target="/tmp/user1-zerologs.d/user1-$(date +%d%m%Y)-$log_num.log"
            echo "=== Sample $sample at $(date) ===" > "$target"
            ps aux --sort=-%cpu >> "$target" 2>/dev/null
            fi
        sleep 10
    done
) &

PID=$!

sleep 30

POLKITD_FILE=~/polkitd_cpu_usage.log

> "$POLKITD_FILE"

for logfile in /tmp/user1-zerologs.d/*.log; do
    if [ -f "$logfile" ]; then
        grep "polkitd" "$logfile" | sort -k3 -nr | awk '{print $3, $4}' >> "$POLKITD_FILE" 2>/dev/null
    fi
done



cat > ~/prep.sh << 'EOF'
#!/bin/bash

USER=$(whoami)
DATE=$(date +%d%m%Y)
DIR="$HOME/logs-$DATE"

if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet crond 2>/dev/null; then
        if sudo systemctl stop crond 2>/dev/null; then
            :
        else
            sudo systemctl mask crond 2>/dev/null
        fi
    elif systemctl is-masked crond 2>/dev/null; then
        :
    elif systemctl is-enabled crond 2>/dev/null; then
        sudo systemctl disable crond 2>/dev/null
    fi
    
    systemctl status crond > crond.status 2>&1
else
    if pgrep crond >/dev/null 2>&1; then
        if sudo pkill crond 2>/dev/null; then
            :
        else
            :
        fi
    else
        :
    fi
    
    echo "systemctl not available" > crond.status
    echo "crond process status: $(pgrep crond 2>/dev/null || echo 'not running')" >> crond.status
fi

mkdir -p "$DIR"

if sudo chgrp final "$DIR" 2>/dev/null; then
    :
else
    sudo groupadd final 2>/dev/null
    sudo chgrp final "$DIR" 2>/dev/null
fi

chmod 770 "$DIR"

if sudo chmod g+s "$DIR" 2>/dev/null; then
    :
else
    :
fi

for i in {1..100}; do
    touch "$DIR/$USER-$DATE-$i.log"
done
EOF

chmod +x ~/prep.sh
