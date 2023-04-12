{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    flake-compat,
  }:
    flake-utils.lib.eachSystem [flake-utils.lib.system.x86_64-linux] (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        node2nix = import ./node2nix.nix {inherit pkgs;};

        override = old: {
          preInstallPhases = "skipChromiumDownload";
          skipChromiumDownload = ''
            export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
          '';
          PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium.outPath}/bin/chromium";
        };

        fontsConf = pkgs.makeFontsConf {
          fontDirectories = [];
        };
      in rec {
        formatter = pkgs.alejandra;
        packages = flake-utils.lib.flattenTree {
          puppeteer-example = pkgs.stdenv.mkDerivation {
            name = "puppeteer-example";

            buildInputs = [pkgs.makeWrapper];

            src = node2nix.package.override override;

            installPhase = ''
              mkdir -p $out/bin
              ln -s $src/bin/puppeteer-example $out/bin/puppeteer-example
              wrapProgram $out/bin/puppeteer-example \
                --set FONTCONFIG_FILE "${fontsConf}" \
                --set PUPPETEER_EXECUTABLE_PATH "${pkgs.chromium.outPath}/bin/chromium";
            '';
          };
          docker = pkgs.dockerTools.buildImage {
            name = "puppeteer-example";

            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [
              pkgs.dockerTools.caCertificates
              (pkgs.writeTextDir "etc/nsswitch.conf" "hosts: files dns")
              packages.puppeteer-example
              #pkgs.dockerTools.usrBinEnv
              #pkgs.dockerTools.binSh
              #pkgs.coreutils-full
            ];
            pathsToLink = ["/bin" "/etc"];
          };

            runAsRoot = ''
              #! ${pkgs.runtimeShell}
              ${pkgs.dockerTools.shadowSetup}
              groupadd -r pptruser
              useradd -r -g pptruser pptruser
              ${pkgs.coreutils}/bin/mkdir -p /tmp
              ${pkgs.coreutils}/bin/chmod 0777 /tmp
              ${pkgs.coreutils}/bin/mkdir -p /data
              ${pkgs.coreutils}/bin/chown pptruser /data
              ${pkgs.coreutils}/bin/chmod 0777 /data
            '';

            config = {
              User = "pptruser";
              WorkDir = "/data";
              Volumes = {
                "/data" = {};
              };

              Cmd = ["${packages.puppeteer-example}/bin/puppeteer-example"];
            };
          };
        };

        defaultPackage = packages.puppeteer-example;
        apps.puppeteer-example = flake-utils.lib.mkApp {drv = packages.puppeteer-example;};
        defaultApp = apps.puppeteer-example;

        devShell = (node2nix.shell.override override).override (old: {
          buildInputs =
            old.buildInputs
            ++ [
              pkgs.node2nix
              (pkgs.writeShellScriptBin "updateNode2Nix" ''
                ${pkgs.node2nix}/bin/node2nix -18 -c node2nix.nix
              '')
            ];
        });
      }
    );
}
