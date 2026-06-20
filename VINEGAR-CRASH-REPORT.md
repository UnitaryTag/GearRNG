# Vinegar 1.9.3 + Roblox Studio — Mimalloc Page Fault Crash

## Environment
- **OS**: CachyOS (Arch-based) Linux, kernel 7.0.12
- **GPU**: NVIDIA RTX 5070 Ti, driver 610.43.02
- **Flatpak**: Vinegar 1.9.3 (from Flathub), Sober 1.7.0 (works fine)
- **Wine**: kombucha stable+20260614215204 (downloaded by Vinegar)
- **Roblox Studio**: version-09611cc13f8a4114 / version-3da9d00a092c4d59

## The Crash

```
Unhandled exception: page fault on read access to 0x000000000000f1e0 in 64-bit code (0x006fffff1b3150)

Backtrace:
=>0 0x006fffff1b3150 in mimalloc (+0x3150) (0x006fffffa40298)
  1 0x000001406903db in robloxstudiobeta (+0x6903db)
  2 0x006fffff9db46a in ucrtbase (+0x2b46a)
  3 0x000001473ea05c in robloxstudiobeta (+0x73ea05c)
  4 0x006fffffec1549 in kernel32 (+0x11549)
  5 0x006ffffff4108b in ntdll (+0x1108b)

0x006fffff1b3150 mimalloc+0x3150: movq (%rdx, %r8, 8), %r9
```

Null pointer dereference in mimalloc's internal segment table. rdx=0, r8=0x1e3c.

Full backtraces saved in: `/home/willi/Documents/GearRNG/backtrace.txt` and `backtrace2.txt`

## Pattern Discovered

1. **Fresh install / full reset** → Studio launches perfectly
2. **Second launch** (same Wine prefix) → mimalloc page fault crash
3. Rojo `.rbxm` plugin was initially suspected but is NOT the cause — crash happens with or without plugins

## What Works (Temporarily)

Full nuke before every launch:
```bash
flatpak kill org.vinegarhq.Vinegar
pkill -9 -f "wineserver|RobloxStudio|bwrap.*vinegar"
rm -rf ~/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/
rm -rf ~/.var/app/org.vinegarhq.Vinegar/data/vinegar/settings.reg
flatpak run org.vinegarhq.Vinegar
```
This works but means re-downloading DXVK + WebView + Studio on every launch (~15 min).

## What Does NOT Work

- Nuking only `prefixes/studio/drive_c/users/willi/AppData/Local/Roblox/` + `settings.reg` — still crashes
- Setting `WINEDLLOVERRIDES="mimalloc-redirect=b"` + `MIMALLOC_DISABLE_REDIRECT=1` — prevents page fault but Studio exits with code 53
- Changing renderer (DXVK, OpenGL, Vulkan, D3D11) — no effect
- Removing plugins (Rojo, StudioMCP) — no effect
- Updating NVIDIA Flatpak GL runtime — no effect

## Working Vinegar Config

```toml
debug = true

[studio]
[studio.env]
PROTON_ENABLE_NGX = "1"
VK_DRIVER_FILES = "/usr/share/vulkan/icd.d/nvidia_icd.json"
__GLX_VENDOR_LIBRARY_NAME = "nvidia"
__NV_PRIME_RENDER_OFFLOAD = "1"
[studio.fflags]
DFIntTaskSchedulerTargetFps = "144"
```

## Key Files & Paths

- Vinegar config: `~/.var/app/org.vinegarhq.Vinegar/config/vinegar/config.toml`
- Wine prefix: `~/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/`
- Settings (corrupts between sessions): `~/.var/app/org.vinegarhq.Vinegar/data/vinegar/settings.reg`
- Studio plugins dir: `~/.var/app/org.vinegarhq.Vinegar/data/vinegar/prefixes/studio/drive_c/users/willi/AppData/Local/Roblox/Plugins/`
- Vinegar logs: `~/.var/app/org.vinegarhq.Vinegar/cache/vinegar/logs/`
- Crash logs: `/home/willi/Documents/GearRNG/backtrace.txt`, `backtrace2.txt`

## What Needs Fixing

The kombucha Wine build (`stable+20260614215204`) has a mimalloc compatibility bug with Roblox Studio. After the first session, something in the Wine prefix state (likely a registry key or DXVK state cache) triggers a null pointer dereference in mimalloc during Studio startup.

**Ideal fix**: Either:
1. Pin Vinegar to an older kombucha version that doesn't have this bug
2. Find which specific file in the Wine prefix triggers the crash (bisect: which file can be deleted without full nuke)
3. Configure Wine to avoid mimalloc completely without causing exit code 53

**Sober 1.7.0 (also Flatpak) works fine** — confirming the host GPU/drivers are not the issue.
