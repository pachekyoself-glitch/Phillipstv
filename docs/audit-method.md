# Read-only audit method and limitations

Sources: Google's [ADB documentation](https://developer.android.com/tools/adb), [dumpsys documentation](https://developer.android.com/tools/dumpsys), and [Platform Tools distribution](https://developer.android.com/tools/releases/platform-tools). Reviewed 2026-11-04.

The command allowlist is enforced in both configuration and code. Queries are bounded by host process timeouts. Every device command uses the explicitly selected USB device or separately authorized LAN endpoint; the collector enables no debugging service and performs no package/settings mutation. Per-package names are validated before querying permission metadata. No account database, private app file, unrestricted logcat, broad `getprop`, screenshot, or filesystem backup is collected.

| Requirement | Read-only observation | Interpretation |
| --- | --- | --- |
| Manufacturer/build/API/security/architecture | Explicit `getprop` allowlist, `uname -r` | Report exact observed properties; model property may be a generic board name |
| Storage and memory | `df -k /data`, `/proc/meminfo` | Storage view and resource snapshot; not a total hardware capacity guarantee |
| Installed/system/user/disabled apps, sources | `pm list packages` variants with installer info for user 0 | Source metadata may be missing or name an intermediary installer |
| Permissions | `dumpsys package <validated package>` | Local-only package detail; inspect requested/granted permissions per user |
| Processes | `ps -A -o PID,PPID,USER,NAME` | No process arguments or unrestricted system logs |
| Launcher and alternatives | Resolve/query HOME activities | Enumeration, not a launcher change |
| Resolution, modes and HDR | `wm size`, density, `dumpsys display` | Advertised/selected modes; not physical panel proof |
| Codecs | `dumpsys media.codec` | Service state may omit codec inventory; mark capability unknown if absent |
| Thermal | `dumpsys thermalservice` | Sensor access and names vary; denied/empty means unavailable |
| Network/debug exposure | `ip -brief address`, `ss -lnt`, selected ADB properties | Local sensitive values; incomplete visibility cannot prove no exposure |
| Profiles/device management | `pm get-max-users`, feature list, device policy dump | Capability clues; do not enumerate personal user names or provision a DPC |
| Advertising/diagnostics | One known diagnostics key plus supported UI checklist | A `null` key is unavailable; never infer disabled collection |
| Updates | Exact model/vendor support and supported Settings updater screen | No updater broadcast, network-triggered update check, or install |

The process records exit codes, output and error text locally. Common permission/unsupported errors are recognized even when shell exit status is zero. Unknown vendor error formats still require human review. A nonempty dump only means the query responded, not that every capability is present. Partial audit files remain local after interruption.

The sanitized summary is built from aggregate fields rather than redacting a raw dump. It deliberately excludes device serial, USB path, model/build/fingerprint, network addresses, package names, and tool paths. It stays local until manually reviewed. Package inventory and technical files must never be committed.

The initial performance baseline consists of available storage, memory, uptime, processes, display and thermal snapshots. App launches, force-stop, reboot, playback, navigation, frame captures, and cold/warm timing are separate interactive tests; the audit does not run them.
