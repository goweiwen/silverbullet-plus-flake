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
| `sources.x86_64-linux` | `https://releases.silverbullet.plus/releases/$V/SilverBullet_x86_64.AppImage` |
| `sources.aarch64-linux` | `https://releases.silverbullet.plus/releases/$V/SilverBullet_aarch64.AppImage` |
| `sbSources.x86_64-linux` | `https://github.com/silverbulletmd/silverbullet/releases/download/$V/sb-linux-x86_64.zip` |
| `sbSources.aarch64-linux` | `https://github.com/silverbulletmd/silverbullet/releases/download/$V/sb-linux-aarch64.zip` |

The desktop app is unfree and closed source. The `sb` CLI comes from the
open-source repository. The two projects share one version tag.

## Steps

1. Get the four hashes. Replace `$V` with the new version.

   ```bash
   V=2.11.0
   for u in \
     "https://releases.silverbullet.plus/releases/$V/SilverBullet_x86_64.AppImage" \
     "https://releases.silverbullet.plus/releases/$V/SilverBullet_aarch64.AppImage" \
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
   line must read `Exec=silverbullet-plus`.

## Failure modes

- **`substituteInPlace` fails with `--replace-fail`.** Upstream changed the
  `.desktop` file. Read `${contents}/usr/share/applications/SilverBullet.desktop`
  in the extracted AppImage and correct the match string.
- **The icon path does not exist.** Upstream changed the icon size. List
  `${contents}/usr/share/icons/hicolor/` and correct the path.
- **The app starts and shows a blank window.** A runtime library is absent. Add
  it to `extraPkgs`. The app is a WebKitGTK shell.

`flake.lock` pins nixpkgs only. A version bump does not need `nix flake update`.
