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
    systems.url = "systems";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
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
    utils,
    nur,
    semgrep-rules,
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [nur.overlays.default];
      };
    in rec {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          pkgs.nur.repos.trev.bumper

          # Svelte
          nodejs_22

          # Protobuf
          buf
          protoc-gen-es
          pkgs.nur.repos.trev.protoc-gen-connect-openapi

          # Nix
          alejandra
          flake-checker

          # Actions
          action-validator
          pkgs.nur.repos.trev.renovate
          pkgs.nur.repos.trev.opengrep
        ];
        shellHook = pkgs.nur.repos.trev.shellhook.ref;
      };

      packages.default = pkgs.buildNpmPackage (finalAttrs: {
        pname = "ts-web";
        version = "0.0.12";
        src = ./.;
        nodejs = pkgs.nodejs_22;

        npmDeps = pkgs.importNpmLock {
          npmRoot = ./.;
        };

        npmConfigHook = pkgs.importNpmLock.npmConfigHook;

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
      });

      checks =
        pkgs.nur.repos.trev.lib.mkChecks {
          lint = {
            src = ./.;
            deps = with pkgs; [
              alejandra
              action-validator
              pkgs.nur.repos.trev.renovate
            ];
            script = ''
              alejandra -c .
              action-validator .github/workflows/*
              action-validator .gitea/workflows/*
              renovate-config-validator
              renovate-config-validator .github/renovate-global.json
              renovate-config-validator .gitea/renovate-global.json
            '';
          };

          scan = {
            src = ./.;
            deps = [
              pkgs.nur.repos.trev.opengrep
            ];
            script = ''
              opengrep scan --quiet --error --config="${semgrep-rules}/typescript"
              opengrep scan --quiet --error --config="${semgrep-rules}/javascript"
            '';
          };
        }
        // {
          build = packages.default.overrideAttrs {
            doCheck = true;
            checkPhase = ''
              npx prettier --check .
              npx eslint .
              npx svelte-kit sync && npx svelte-check
            '';
          };
          shell = devShells.default;
        };

      formatter = pkgs.alejandra;
    });
}
