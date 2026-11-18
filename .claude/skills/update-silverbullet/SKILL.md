---
name: update-silverbullet
description: Bump this flake to a new SilverBullet+ release. Use when the user asks to update, upgrade, or bump the flake to a version number.
---

# Update SilverBullet+ flake

The flake pins one `version` and four binary hashes. A release bump changes only
those five values. Do not change the derivation logic.

## Sources

Each release has four artifacts. The version string is the same in all URLs.

| Attribute | URL template |
| --- | --- |
| `sources.x86_64-linux` | `https://release.silverbullet.md/electron/artifacts/$V/linux/x64/SilverBullet-$V-linux-x86_64.AppImage` |
| `sources.aarch64-linux` | `https://release.silverbullet.md/electron/artifacts/$V/linux/arm64/SilverBullet-$V-linux-arm64.AppImage` |
| `sbSources.x86_64-linux` | `https://github.com/silverbulletmd/silverbullet/releases/download/$V/sb-linux-x86_64.zip` |
| `sbSources.aarch64-linux` | `https://github.com/silverbulletmd/silverbullet/releases/download/$V/sb-linux-aarch64.zip` |

The desktop app is an unfree Electron app. The `sb` CLI comes from the
open-source repository. The two projects share one version tag.

Before 2.12.1, the desktop app was a WebKitGTK shell on
`releases.silverbullet.plus`. From 2.12.1, upstream publishes it on
`release.silverbullet.md`.

## Steps

1. Get the four hashes. Replace `$V` with the new version.

   ```bash
   V=2.12.1
   for u in \
     "https://release.silverbullet.md/electron/artifacts/$V/linux/x64/SilverBullet-$V-linux-x86_64.AppImage" \
     "https://release.silverbullet.md/electron/artifacts/$V/linux/arm64/SilverBullet-$V-linux-arm64.AppImage" \
     "https://github.com/silverbulletmd/silverbullet/releases/download/$V/sb-linux-x86_64.zip" \
     "https://github.com/silverbulletmd/silverbullet/releases/download/$V/sb-linux-aarch64.zip" ; do
     echo "== $u"
     nix store prefetch-file --json --hash-type sha256 "$u"
   done
   ```

   A 404 means upstream did not publish that architecture. Stop and tell the user.

2. Edit `flake.nix`. Set `version` and the four `hash` values. Keep each hash
   with its own URL. A swapped hash builds, then fails at run time.

3. Build both packages. The desktop app is unfree, so set the variable.

   ```bash
   NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#silverbullet-plus .#sb \
     --no-link --print-out-paths
   ```

4. Verify the CLI reports the new version.

   ```bash
   <sb-store-path>/bin/sb --version
   ```

5. Verify the desktop entry. Print
   `<app-store-path>/share/applications/silverbullet-plus.desktop`. The `Exec`
   line must read `Exec=silverbullet-plus %U`.

## Failure modes

- **`substituteInPlace` fails with `--replace-fail`.** Upstream changed the
  `.desktop` file. Read `${contents}/silverbullet.desktop` in the extracted
  AppImage and correct the match string.
- **The icon directory does not exist.** Upstream moved the icons. Find them in
  the extracted AppImage and correct the `cp` source path.
- **The app does not start or shows a blank window.** A runtime library is
  absent. Add it to `extraPkgs`.

`flake.lock` pins nixpkgs only. A version bump does not need `nix flake update`.
