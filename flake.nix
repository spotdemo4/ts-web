{
  description = "Trevstack Web";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    pname = "trevstack-web";
    version = "0.0.1";

    build-systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forSystem = f:
      nixpkgs.lib.genAttrs build-systems (
        system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
            };
          }
      );
  in {
    devShells = forSystem ({pkgs, ...}: let
      protoc-gen-connect-openapi = pkgs.buildGoModule {
        name = "protoc-gen-connect-openapi";
        src = pkgs.fetchFromGitHub {
          owner = "sudorandom";
          repo = "protoc-gen-connect-openapi";
          rev = "v0.17.0";
          sha256 = "sha256-ek9yYvTBrZZUtQAHdTW6dNO72jInWlYi7WvZKVjjxQo=";
        };
        vendorHash = "sha256-9v3TESnFQA/KzkVHDPui7eh5tn1AGI/ZOi6Qd35lRew=";
      };
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          git

          # Nix
          nix-update
          alejandra

          # Protobuf
          buf
          protoc-gen-go
          protoc-gen-connect-go
          protoc-gen-es
          protoc-gen-connect-openapi

          # Svelte
          nodejs_22
        ];
      };
    });

    checks = forSystem ({pkgs, ...}: {
      nix = with pkgs;
        runCommandLocal "check-nix" {
          nativeBuildInputs = with pkgs; [
            alejandra
          ];
        } ''
          cd ${./.}
          alejandra -c .
          touch $out
        '';

      lint = with pkgs;
        buildNpmPackage {
          pname = "check-client";
          inherit version;
          src = ./.;
          npmDepsHash = "";
          dontNpmInstall = true;

          buildPhase = ''
            npx prettier --check .
            npx eslint .
            npx svelte-kit sync && npx svelte-check
            touch $out
          '';
        };
    });

    apps = forSystem ({pkgs, ...}: {
      update = {
        type = "app";
        program = pkgs.lib.getExe (pkgs.writeShellApplication {
          name = "update";
          runtimeInputs = with pkgs; [
            git
            nix
            nix-update
            nodejs_22
          ];
          text = builtins.readFile ./.scripts/update;
        });
      };

      bump = {
        type = "app";
        program = pkgs.lib.getExe (pkgs.writeShellApplication {
          name = "bump";
          runtimeInputs = with pkgs; [
            git
            nix-update
            nodejs_22
          ];
          text = builtins.readFile ./.scripts/bump;
        });
      };
    });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);

    packages = forSystem (
      {pkgs, ...}: let
        web = pkgs.buildNpmPackage {
          inherit pname version;
          src = ./.;
          npmDepsHash = "sha256-m0tMCJevjnfi2D+bBm0Beai9Mne543tpVVJ7wo+Afo4=";

          installPhase = ''
            cp -r build "$out"
          '';
        };
      in {
        default = web;
      }
    );
  };
}
