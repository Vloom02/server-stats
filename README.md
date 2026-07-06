# server-stats

A single Bash script that analyses basic performance stats on any Linux server.

Solution for the [Server Performance Stats](https://roadmap.sh/projects/server-stats) project from [roadmap.sh](https://roadmap.sh).

## What it reports

- **Total CPU usage** — sampled from `/proc/stat` over 1 second (no dependency on `top` output format)
- **Memory usage** — total / used / available with percentages (`free`)
- **Disk usage** — local filesystems total, used vs free with percentage (`df`)
- **Top 5 processes by CPU** and **by memory** (`ps --sort`)
- Stretch goals: OS version, kernel, hostname, uptime, load average, logged-in users, failed login attempts

## How to run

```bash
git clone https://github.com/Vloom02/server-stats.git
cd server-stats
chmod +x server-stats.sh
./server-stats.sh
```

No arguments, no dependencies beyond standard Linux tools (`procps`, `coreutils`).

## Sample output

```
== CPU ==
Total CPU usage: 12.3%  (idle: 87.7%)

== MEMORY ==
Total: 7936 MB
Used:  3210 MB (40.4%)
Free:  4726 MB (59.6%, available)

== TOP 5 PROCESSES BY CPU ==
  PID USER     %CPU %MEM COMMAND
 1234 www-data 12.0  2.1 nginx
 ...
```

## Notes

- Failed login attempts read `/var/log/btmp`, which requires root; the script says so instead of failing.
- Every section degrades gracefully if a tool is missing, so it also partially runs on macOS / Git Bash.
