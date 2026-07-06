#!/bin/bash
# server-stats.sh — analyse basic server performance stats on any Linux server.
# Usage: ./server-stats.sh
# Project: https://roadmap.sh/projects/server-stats

set -u

header() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

# ---------- System info (stretch goal) ----------
header "SYSTEM"
echo "Hostname:        $(hostname)"
if [ -r /etc/os-release ]; then
    echo "OS:              $(. /etc/os-release && echo "$PRETTY_NAME")"
fi
echo "Kernel:          $(uname -r)"
echo "Uptime:          $(uptime -p 2>/dev/null || uptime 2>/dev/null || echo n/a)"
if [ -r /proc/loadavg ]; then
    echo "Load average:    $(cut -d' ' -f1-3 /proc/loadavg)  (1m 5m 15m)"
fi
echo "Users logged in: $(who 2>/dev/null | wc -l)"

# ---------- Total CPU usage ----------
header "CPU"
if [ -r /proc/stat ]; then
    # Two samples 1s apart: usage = 1 - (delta idle / delta total)
    read -r _ u1 n1 s1 i1 w1 x1 y1 z1 _ < /proc/stat
    sleep 1
    read -r _ u2 n2 s2 i2 w2 x2 y2 z2 _ < /proc/stat
    idle=$(( (i2 + w2) - (i1 + w1) ))
    total=$(( (u2+n2+s2+i2+w2+x2+y2+z2) - (u1+n1+s1+i1+w1+x1+y1+z1) ))
    if [ "$total" -gt 0 ]; then
        awk -v t="$total" -v i="$idle" \
            'BEGIN { printf "Total CPU usage: %.1f%%  (idle: %.1f%%)\n", (t-i)*100/t, i*100/t }'
    else
        echo "Total CPU usage: n/a (no tick delta)"
    fi
else
    echo "Total CPU usage: n/a (/proc/stat not readable)"
fi

# ---------- Memory usage ----------
header "MEMORY"
if command -v free >/dev/null; then
    free -m | awk '/^Mem:/ {
        used_pct = $3 * 100 / $2
        printf "Total: %d MB\nUsed:  %d MB (%.1f%%)\nFree:  %d MB (%.1f%%, available)\n",
               $2, $3, used_pct, $7, 100 - used_pct
    }'
else
    echo "n/a (free not found)"
fi

# ---------- Disk usage ----------
header "DISK (local filesystems)"
if df -h --total -x tmpfs -x devtmpfs -x squashfs -x overlay >/dev/null 2>&1; then
    df -h --total -x tmpfs -x devtmpfs -x squashfs -x overlay | awk 'NR == 1 || /^total/'
else
    df -h   # fallback for non-GNU df
fi

# ---------- Top 5 processes by CPU ----------
header "TOP 5 PROCESSES BY CPU"
if ps axo pid,user,%cpu,%mem,comm --sort=-%cpu >/dev/null 2>&1; then
    ps axo pid,user,%cpu,%mem,comm --sort=-%cpu | head -6
else
    echo "n/a (ps does not support --sort on this system)"
fi

# ---------- Top 5 processes by memory ----------
header "TOP 5 PROCESSES BY MEMORY"
if ps axo pid,user,%cpu,%mem,comm --sort=-%mem >/dev/null 2>&1; then
    ps axo pid,user,%cpu,%mem,comm --sort=-%mem | head -6
else
    echo "n/a (ps does not support --sort on this system)"
fi

# ---------- Failed login attempts (stretch goal) ----------
header "SECURITY"
if command -v lastb >/dev/null && [ -r /var/log/btmp ]; then
    fails=$(lastb 2>/dev/null | awk 'NF && $1 != "btmp" { c++ } END { print c + 0 }')
    echo "Failed login attempts: $fails"
else
    echo "Failed login attempts: n/a (needs root: sudo lastb | wc -l)"
fi

echo
