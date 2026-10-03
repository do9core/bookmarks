# Bookmarks Bucket

A small set of applications not in scoop official buckets.

## How do I install these manifests?

After manifests have been committed and pushed, run the following:

```pwsh
scoop bucket add <bucketname> https://github.com/do9core/bookmarks
scoop install <bucketname>/<manifestname>
```

## Manifest source from other buckets

| Manifest          | Bucket                                                             |
| ----------------- | ------------------------------------------------------------------ |
| vLabeler          | [scoop-musician](https://github.com/oxygen-dioxide/scoop-musician) |
| vLabeler Beta     | [scoop-musician](https://github.com/oxygen-dioxide/scoop-musician) |

## OpenUtau variants and shared data

Install `scoop install <bucketname>/openutau-beta` for the Beta channel. It has a
separate `openutau-beta` command and an **OpenUtau Beta** shortcut.

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
