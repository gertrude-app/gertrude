# Analyzing iOS Block Rules

Workflow for investigating which domains iOS apps are requesting, to refine the built-in
block rules in `iosapp.block_rules`, or to create new block groups. This workflow does not
require using the Console.app, and allows for collaboration with an agent reviewing log
files.

For prior findings (what's been tried, what worked, what didn't), see
[`ios-block-findings.md`](./ios-block-findings.md).

## Prerequisites

- `idevicesyslog` from libimobiledevice

## Device Setup

List devices and identify the target:

```bash
idevice_id -l        # USB devices
idevice_id -l -n     # network devices
ideviceinfo -u <UDID> -k DeviceName
ideviceinfo -u <UDID> -k ProductType
```

## Capturing Logs

Stream Gertrude filter logs to a file while browsing the target app:

```bash
# USB
idevicesyslog -u <UDID> -q -m "•]" -o ./logs/capture.log

# network
idevicesyslog -u <UDID> -n -q -m "•]" -o ./logs/capture.log
```

The `•]` match string captures both normal `[G•]` and debug `[D•]` log lines from the
Gertrude filter proxy. The `-q` flag suppresses noisy system processes.

Network mode (`-n`) has gone silent after short bursts of activity in practice — prefer USB.

To also watch in real time, use a second terminal without `-o`, or use `tee`:

```bash
idevicesyslog -u <UDID> -q -m "•]" | tee ./logs/capture.log
```

Ctrl+C to stop when done browsing.

## Analyzing Captures

Key things to look for in the log file:

- `flow verdict: ALLOW` — domains getting through (potential gaps in coverage)
- `flow verdict: DROP` — domains being blocked (confirming rules work)
- `handle new SOCKET flow` — debug detail showing bundle ID, hostname, remote IP

Quick extraction:

```bash
grep "ALLOW" ./logs/capture.log | sort -u   # unique allowed domains
grep "DROP" ./logs/capture.log | sort -u     # unique dropped domains
```

## Current Block Rules

Spotify block rules (and others) live in the `iosapp.block_rules` table, organized by
`iosapp.block_groups`. Rules are JSONB using types like `bundleIdContains`,
`targetContains`, `hostnameEquals`, combined with `both` and `unless`.

Query current rules for a group:

```sql
SELECT rule::text FROM iosapp.block_rules
WHERE group_id = '<group-uuid>' ORDER BY created_at;
```

## Known Limitations

- the filter only sees new connection establishments, not individual requests within a
  persistent HTTP/2 connection
