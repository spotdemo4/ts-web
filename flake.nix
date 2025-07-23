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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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

      ts-web = pkgs.buildNpmPackage (finalAttrs: {
        pname = "ts-web";
        version = "0.0.9";
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
    in rec {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          pkgs.nur.repos.trev.bumper

          # Nix
          nix-update
          alejandra

          # Protobuf
          buf
          protoc-gen-es
          pkgs.nur.repos.trev.protoc-gen-connect-openapi

          # Svelte
          nodejs_22

          # Actions
          action-validator
          renovate
          pkgs.nur.repos.trev.opengrep
        ];
        shellHook = pkgs.nur.repos.trev.shellhook.ref;
      };

      checks =
        pkgs.nur.repos.trev.lib.mkChecks {
          lint = {
            src = ./.;
            deps = with pkgs; [
              alejandra
              renovate
              action-validator
            ];
            script = ''
              alejandra -c .
              renovate-config-validator
              renovate-config-validator .gitea/renovate-global.json
              action-validator .gitea/workflows/*
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
          build = ts-web.overrideAttrs {
            doCheck = true;
            checkPhase = ''
              npx prettier --check .
              npx eslint .
              npx svelte-kit sync && npx svelte-check
            '';
          };
          shell = devShells.default;
        };

      packages.default = ts-web;

      formatter = pkgs.alejandra;
    });
}
