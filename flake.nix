{
  description = "SilverBullet+ — native desktop app, packaged from the official AppImage";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      version = "2.9.0";

      # Upstream ships per-arch AppImages from releases.silverbullet.plus.
      sources = {
        x86_64-linux = {
          url = "https://releases.silverbullet.plus/releases/${version}/SilverBullet_x86_64.AppImage";
          hash = "sha256-GtiLG6cnZIwwMGjINYEzboCTi+0weUX7zvrtmgA7y4c=";
        };
        aarch64-linux = {
          url = "https://releases.silverbullet.plus/releases/${version}/SilverBullet_aarch64.AppImage";
          hash = "sha256-5zdFo4QYVdEbXtqe71fkiIbU7ZRiXpC4sHb3ubpg1h8=";
        };
      };

      systems = builtins.attrNames sources;
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      mkPackage =
        pkgs:
        let
          inherit (pkgs) lib appimageTools;
          pname = "silverbullet-plus";
          src = pkgs.fetchurl sources.${pkgs.stdenv.hostPlatform.system};
          contents = appimageTools.extractType2 { inherit pname version src; };
        in
        appimageTools.wrapType2 {
          inherit pname version src;

          # The AppImage is a WebKitGTK shell; the base appimage runtime libs
          # don't include webkit2gtk 4.1 or a TLS backend, so add them here.
          extraPkgs = p: [
            p.webkitgtk_4_1
            p.glib-networking
            p.libsoup_3
          ];

          extraInstallCommands = ''
            install -Dm444 ${contents}/usr/share/applications/SilverBullet.desktop \
              $out/share/applications/${pname}.desktop
            substituteInPlace $out/share/applications/${pname}.desktop \
              --replace-fail 'Exec=silverbullet-app' 'Exec=${pname}'
            install -Dm444 ${contents}/usr/share/icons/hicolor/1024x1024/apps/silverbullet-app.png \
              $out/share/icons/hicolor/1024x1024/apps/silverbullet-app.png
          '';

          meta = {
            description = "SilverBullet+ native desktop app";
            homepage = "https://silverbullet.plus";
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            license = lib.licenses.unfree;
            mainProgram = pname;
            platforms = systems;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        silverbullet-plus = mkPackage pkgs;
        default = silverbullet-plus;
      });

      apps = forAllSystems (pkgs: rec {
        silverbullet-plus = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.silverbullet-plus}/bin/silverbullet-plus";
        };
        default = silverbullet-plus;
      });

      overlays.default = final: _prev: {
        silverbullet-plus = mkPackage final;
      };
    };
}
