{
  description = "Trevstack Web";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    pname = "ts-web";
    version = "0.0.7";

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
          protoc-gen-es
          protoc-gen-connect-openapi

          # Svelte
          nodejs_22
        ];
      };

      ci = pkgs.mkShell {
        packages = with pkgs; [
          git
          renovate

          # Nix
          nix-update

          # Protobuf
          buf
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

      npm = with pkgs;
        buildNpmPackage {
          pname = "check-npm";
          inherit version;
          src = ./.;
          npmDepsHash = "sha256-5hC3nTqNYrmRMBlkdDOnqIRx0h4hriIU7Lq4+topGpk=";
          dontNpmInstall = true;

          buildPhase = ''
            npx prettier --check .
            npx eslint .
            npx svelte-kit sync && npx svelte-check
            touch $out
          '';
        };
    });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);

    packages = forSystem (
      {pkgs, ...}: let
        web = pkgs.buildNpmPackage {
          inherit pname version;
          src = ./.;
          npmDepsHash = "sha256-5hC3nTqNYrmRMBlkdDOnqIRx0h4hriIU7Lq4+topGpk=";

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
