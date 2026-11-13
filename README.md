# Bookmarks Bucket

A small set of applications not in scoop official buckets.

## How do I install these manifests?

After manifests have been committed and pushed, run the following:

```pwsh
scoop bucket add <bucketname> https://github.com/do9core/bookmarks
scoop install <bucketname>/<manifestname>
```

## Open Design

Open Design uses the upstream Windows x64 release. Scoop extracts both payloads
without running the installer, and manages the command and Start Menu shortcut.

```pwsh
scoop install <bucketname>/open-design
scoop update open-design
scoop uninstall open-design         # Keep user data
scoop uninstall open-design --purge # Delete local application data and projects
```

Close Open Design before updating or uninstalling, and use Scoop for updates
instead of the in-app updater. Uninstall removes the `opendesign://` handler
when it points into this Scoop installation. Purging also deletes
`%APPDATA%\Open Design`, including local projects, credentials, settings,
downloaded runtimes and caches. This directory is shared with standalone
installations and other channels; back it up first. Custom `OD_DATA_DIR`
locations and files outside this directory are kept. Remove Scoop's download
cache separately with `scoop cache rm open-design`.

## OpenIDEA

OpenIDEA supports x64 and ARM64 Windows. Scoop extracts the application without
running the upstream installer or registering a system uninstaller. Microsoft
Edge WebView2 Runtime must be available (it is included with Windows 11).

```pwsh
scoop install <bucketname>/openidea
scoop update openidea
scoop uninstall openidea         # Keep user settings and caches
scoop uninstall openidea --purge # Also delete this user's application data
```

Use Scoop to update instead of the in-app updater. Close OpenIDEA before
uninstalling. Purging deletes `%APPDATA%\ai.l0ng.openidea` and
`%LOCALAPPDATA%\ai.l0ng.openidea`, including settings, plugins, saved credentials,
downloaded tools and caches. These directories are shared with standalone
OpenIDEA installations; back them up if needed. Project files, including
project-local `.openidea` directories, are kept. Scoop's download cache can be
removed separately with `scoop cache rm openidea`.

## Manifest source from other buckets

| Manifest          | Bucket                                                             |
| ----------------- | ------------------------------------------------------------------ |
| vLabeler          | [scoop-musician](https://github.com/oxygen-dioxide/scoop-musician) |
| vLabeler Beta     | [scoop-musician](https://github.com/oxygen-dioxide/scoop-musician) |

## OpenUtau variants and shared data

Install `scoop install <bucketname>/openutau-beta` for the Beta channel. It has a
separate `openutau-beta` command and an **OpenUtau Beta** shortcut.

`utau-v` uses the official DirectML build, which supports AMD, Intel, and NVIDIA
GPUs without installing CUDA. Upstream's newer releases use `0.0.x` version
numbers after the older `1.2.x` series. Reinstall `utau-v` to switch from an
installed `1.2.x` version; normal uninstallation keeps its persistent data.

OpenUtau, OpenUtau Beta, OpenUtau LUNAI (`openutau-lunai`), and UtauV (`utau-v`)
share `Dictionaries`, `Resamplers`, `Singers`, `Templates`, and `Wavtools` under
Scoop's `persist/openutau` directory. `Backups`, `Cache`, and `Plugins` remain
private under each variant's own persist directory. UtauV's `Dependencies`,
`Logs`, `SingerThemes`, and `Themes` are also private. Any variant can be
installed first; all must use the same Scoop installation scope (user or global).

If an older variant installation has data in `persist/openutau-beta`,
`persist/openutau-lunai`, or `persist/utau-v`, close all applications and manually
merge only the shared folders into `persist/openutau` before using the updated
variant. Private folders continue to use that variant's own persist directory.
Manifest changes do not automatically move existing data.

Normal uninstallation preserves shared data. Purging `openutau-beta`,
`openutau-lunai`, or `utau-v` only removes that variant's private data, while
`scoop uninstall openutau --purge` removes the shared data used by all variants.
Back up shared data before switching variants, and avoid running multiple
variants at the same time.
