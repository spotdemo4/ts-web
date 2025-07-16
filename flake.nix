{
  description = "Trevstack Web Client";

  nixConfig = {
    extra-substituters = [
      "https://trevnur.cachix.org"
    ];
    extra-trusted-public-keys = [
      "trevnur.cachix.org-1:hBd15IdszwT52aOxdKs5vNTbq36emvEeGqpb25Bkq6o="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    semgrep-rules = {
      url = "github:semgrep/semgrep-rules";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    nur,
    semgrep-rules,
    ...
  }: let
    build-systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forSystem = f:
      nixpkgs.lib.genAttrs build-systems (
        system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              overlays = [nur.overlays.default];
            };
          }
      );

    ts-web = forSystem ({pkgs, ...}:
      pkgs.buildNpmPackage (finalAttrs: {
        pname = "ts-web";
        version = "0.0.8";
        src = ./.;
        npmDepsHash = "sha256-zHGLRiYzCQdROtXphQExXpnV5GBNLo8baNlTyIlJQLY=";

        installPhase = ''
          cp -r build "$out"
        '';

        meta = {
          description = "A simple GO CRUD app - web client";
          homepage = "https://github.com/spotdemo4/ts-web";
          changelog = "https://github.com/spotdemo4/ts-web/releases/tag/v${finalAttrs.version}";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.all;
        };
      }));
  in rec {
    devShells = forSystem ({pkgs, ...}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          git
          renovate

          # Nix
          nix-update
          alejandra

          # Protobuf
          buf
          protoc-gen-es
          pkgs.nur.repos.trev.protoc-gen-connect-openapi

          # Svelte
          nodejs_22
        ];
      };
    });

    checks = forSystem ({
      pkgs,
      system,
      ...
    }:
      pkgs.nur.repos.trev.lib.mkChecks {
        lint = {
          src = ./.;
          nativeBuildInputs = with pkgs; [
            alejandra
          ];
          checkPhase = ''
            alejandra -c .
          '';
        };

        scan = {
          src = ./.;
          nativeBuildInputs = [
            pkgs.nur.repos.trev.opengrep
          ];
          checkPhase = ''
            mkdir -p "$TMP/scan"
            HOME="$TMP/scan"
            opengrep scan --quiet --error --config="${semgrep-rules}/typescript"
            opengrep scan --quiet --error --config="${semgrep-rules}/javascript"
          '';
        };
      }
      // {
        build = ts-web."${system}".overrideAttrs {
          doCheck = true;
          checkPhase = ''
            npx prettier --check .
            npx eslint .
            npx svelte-kit sync && npx svelte-check
          '';
          installPhase = ''
            touch $out
          '';
        };

        shell = devShells."${system}".default;
      });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);

    packages = forSystem (
      {system, ...}: {
        default = ts-web."${system}";
      }
    );
  };
}
