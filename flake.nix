{
  description = "SilverBullet+ — native desktop app, packaged from the official AppImage";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      version = "2.12.1";

      # Upstream ships per-arch Electron AppImages from release.silverbullet.md.
      sources = {
        x86_64-linux = {
          url = "https://release.silverbullet.md/electron/artifacts/${version}/linux/x64/SilverBullet-${version}-linux-x86_64.AppImage";
          hash = "sha256-cg6PDGRxi+NNGX4CJGnBX+/wuSXJ/8vP3wboWjONd28=";
        };
        aarch64-linux = {
          url = "https://release.silverbullet.md/electron/artifacts/${version}/linux/arm64/SilverBullet-${version}-linux-arm64.AppImage";
          hash = "sha256-dvjugSE7OGizCM7CmMIcHRPZ/RHJ1pMl+dPiO1V6V10=";
        };
      };

      # The `sb` CLI (open-source companion client) ships as a static binary
      # zip alongside the matching version tag on the OSS GitHub releases.
      sbSources = {
        x86_64-linux = {
          url = "https://github.com/silverbulletmd/silverbullet/releases/download/${version}/sb-linux-x86_64.zip";
          hash = "sha256-oEsyl6AJ1bLf2YUKS32RVhg2j5WXKK3LEjsElJwLBTM=";
        };
        aarch64-linux = {
          url = "https://github.com/silverbulletmd/silverbullet/releases/download/${version}/sb-linux-aarch64.zip";
          hash = "sha256-Qutgouq7U2dLCIoR7Y676eQxC2t6ufvm3dsoZye4uvM=";
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

          extraInstallCommands = ''
            install -Dm444 ${contents}/silverbullet.desktop \
              $out/share/applications/${pname}.desktop
            substituteInPlace $out/share/applications/${pname}.desktop \
              --replace-fail 'Exec=AppRun' 'Exec=${pname}'
            cp -r ${contents}/usr/share/icons $out/share/
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
