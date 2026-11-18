{
  description = "SilverBullet+ — native desktop app, packaged from the official AppImage";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      version = "2.11.0";

      # Upstream ships per-arch AppImages from releases.silverbullet.plus.
      sources = {
        x86_64-linux = {
          url = "https://releases.silverbullet.plus/releases/${version}/SilverBullet_x86_64.AppImage";
          hash = "sha256-7YQ0GId03Qfzd6Au60jC3z3mm5NZi2bQTto7bL5PF58=";
        };
        aarch64-linux = {
          url = "https://releases.silverbullet.plus/releases/${version}/SilverBullet_aarch64.AppImage";
          hash = "sha256-Y2RMmXsHqDUv8E/5Cey2OkP3PwL/s0GO1xP6R9omnGs=";
        };
      };

      # The `sb` CLI (open-source companion client) ships as a static binary
      # zip alongside the matching version tag on the OSS GitHub releases.
      sbSources = {
        x86_64-linux = {
          url = "https://github.com/silverbulletmd/silverbullet/releases/download/${version}/sb-linux-x86_64.zip";
          hash = "sha256-tqtQkvtg5xK4os40+mCZHNjBGzUVltf9t9MOPAFl50U=";
        };
        aarch64-linux = {
          url = "https://github.com/silverbulletmd/silverbullet/releases/download/${version}/sb-linux-aarch64.zip";
          hash = "sha256-FfIzOfY7Ofg66snztWuIiJRzh2FQ6v13p3oqnmbIvXU=";
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
          contents = appimageTools.extract { inherit pname version src; };
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

      mkSbPackage =
        pkgs:
        let
          inherit (pkgs) lib;
          src = pkgs.fetchurl sbSources.${pkgs.stdenv.hostPlatform.system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "sb";
          inherit version src;

          nativeBuildInputs = [ pkgs.unzip ];
          sourceRoot = ".";
          unpackPhase = "unzip -q $src";

          installPhase = ''
            install -Dm755 sb $out/bin/sb
          '';

          meta = {
            description = "SilverBullet CLI — companion client for a running SilverBullet instance";
            homepage = "https://github.com/silverbulletmd/silverbullet";
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            license = lib.licenses.mit;
            mainProgram = "sb";
            platforms = builtins.attrNames sbSources;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        silverbullet-plus = mkPackage pkgs;
        sb = mkSbPackage pkgs;
        default = silverbullet-plus;
      });

      apps = forAllSystems (pkgs: rec {
        silverbullet-plus = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.silverbullet-plus}/bin/silverbullet-plus";
        };
        sb = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.sb}/bin/sb";
        };
        default = silverbullet-plus;
      });

      overlays.default = final: _prev: {
        silverbullet-plus = mkPackage final;
        sb = mkSbPackage final;
      };
    };
}
