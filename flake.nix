{
  description = "Nix package for Tailwind CSS language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pname = "tailwindcss-intellisense-source";
    version = "0.0.0";
    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit pname version;
      src = ./.;
      fetcherVersion = 4;
      hash = "sha256-7O80o9gLozHNOiRk3lws82WIE54P9VWww6wt9JoaGOY=";
    };
    fixtureRoots = [
      "v1"
      "v2"
      "v2-jit"
      "v4/basic"
      "v4/css-loading-js"
      "v4/dependencies"
      "v4/invalid-import-order"
      "v4/missing-files"
      "v4/multi-config"
      "v4/path-mappings"
      "v4/with-prefix"
      "v4/workspaces"
    ];
    fixtureNodeModules =
      builtins.listToAttrs
      (map (fixtureRoot: {
          name = fixtureRoot;
          value = pkgs.importNpmLock.buildNodeModules {
            npmRoot = ./packages/tailwindcss-language-server/tests/fixtures/${fixtureRoot};
            nodejs = pkgs.nodejs_24;
            derivationArgs = {
              pname = "tailwindcss-intellisense-fixture-${builtins.replaceStrings ["/"] ["-"] fixtureRoot}-node-modules";
              inherit version;
            };
          };
        })
        fixtureRoots);
    debugNodeModules = {
      tailwindcss-3-4-18 = pkgs.importNpmLock.buildNodeModules {
        npmRoot = ./nix/test-node-modules/tailwindcss-3.4.18;
        nodejs = pkgs.nodejs_24;
        derivationArgs = {
          pname = "tailwindcss-intellisense-test-tailwindcss-3-4-18-node-modules";
          inherit version;
        };
      };
      tailwindcss-4-1-0-oxide = pkgs.importNpmLock.buildNodeModules {
        npmRoot = ./nix/test-node-modules/tailwindcss-4.1.0-oxide;
        nodejs = pkgs.nodejs_24;
        derivationArgs = {
          pname = "tailwindcss-intellisense-test-tailwindcss-4-1-0-oxide-node-modules";
          inherit version;
        };
      };
      tailwindcss-4-1-0 = pkgs.importNpmLock.buildNodeModules {
        npmRoot = ./nix/test-node-modules/tailwindcss-4.1.0;
        nodejs = pkgs.nodejs_24;
        derivationArgs = {
          pname = "tailwindcss-intellisense-test-tailwindcss-4-1-0-node-modules";
          inherit version;
        };
      };
      tailwindcss-4-1-18 = fixtureNodeModules."v4/basic";
      tailwindcss-4-3-3 = pkgs.importNpmLock.buildNodeModules {
        npmRoot = ./nix/test-node-modules/tailwindcss-4.3.3;
        nodejs = pkgs.nodejs_24;
        derivationArgs = {
          pname = "tailwindcss-intellisense-test-tailwindcss-4-3-3-node-modules";
          inherit version;
        };
      };
    };
    installFixtureNodeModules =
      pkgs.lib.concatMapStringsSep "\n" (fixtureRoot: ''
        cp -R ${fixtureNodeModules.${fixtureRoot}}/node_modules packages/tailwindcss-language-server/tests/fixtures/${fixtureRoot}/node_modules
        chmod -R u+w packages/tailwindcss-language-server/tests/fixtures/${fixtureRoot}/node_modules
      '')
      fixtureRoots;
    sourceCheck = name: command:
      pkgs.stdenv.mkDerivation {
        inherit pname version pnpmDeps;
        name = "tailwindcss-intellisense-${name}";
        src = ./.;
        nativeBuildInputs = [
          pkgs.nodejs_24
          pkgs.pnpm_10
          pkgs.pnpmConfigHook
        ];
        env.CI = "true";
        env.TAILWINDCSS_INTELLISENSE_NIX_TW_3_4_18_NODE_MODULES = "${debugNodeModules."tailwindcss-3-4-18"}/node_modules";
        env.TAILWINDCSS_INTELLISENSE_NIX_TW_4_1_0_NODE_MODULES = "${debugNodeModules."tailwindcss-4-1-0"}/node_modules";
        env.TAILWINDCSS_INTELLISENSE_NIX_TW_4_1_0_OXIDE_NODE_MODULES = "${debugNodeModules."tailwindcss-4-1-0-oxide"}/node_modules";
        env.TAILWINDCSS_INTELLISENSE_NIX_TW_4_1_18_NODE_MODULES = "${debugNodeModules."tailwindcss-4-1-18"}/node_modules";
        env.TAILWINDCSS_INTELLISENSE_NIX_TW_4_3_3_NODE_MODULES = "${debugNodeModules."tailwindcss-4-3-3"}/node_modules";
        env.TAILWINDCSS_INTELLISENSE_SKIP_FIXTURE_INSTALL = "1";
        buildPhase = ''
          runHook preBuild
          ${installFixtureNodeModules}
          mkdir -p packages/tailwindcss-language-server/tests/fixtures/v4/workspaces/node_modules/@private
          ln -s ../../packages/admin packages/tailwindcss-language-server/tests/fixtures/v4/workspaces/node_modules/@private/admin
          ln -s ../../packages/shared packages/tailwindcss-language-server/tests/fixtures/v4/workspaces/node_modules/@private/shared
          ln -s ../../packages/style-export packages/tailwindcss-language-server/tests/fixtures/v4/workspaces/node_modules/@private/style-export
          ln -s ../../packages/style-main-field packages/tailwindcss-language-server/tests/fixtures/v4/workspaces/node_modules/@private/style-main-field
          ln -s ../../packages/web packages/tailwindcss-language-server/tests/fixtures/v4/workspaces/node_modules/@private/web
          ${command}
          runHook postBuild
        '';
        installPhase = ''
          touch "$out"
        '';
      };
  in {
    formatter = {
      ${system} = pkgs.alejandra;
    };
    packages = {
      ${system}.default = pkgs.tailwindcss-language-server;
    };
    checks = {
      ${system} = {
        default = pkgs.tailwindcss-language-server;

        flake-format =
          pkgs.runCommand "tailwindcss-language-server-flake-format-check"
          {nativeBuildInputs = [pkgs.alejandra];}
          ''
            alejandra --check ${./flake.nix}
            touch $out
          '';

        package-metadata =
          pkgs.runCommand "tailwindcss-language-server-package-metadata-check"
          {}
          ''
            test "${pkgs.lib.getName pkgs.tailwindcss-language-server}" = "tailwindcss-language-server"
            touch $out
          '';

        source-tests = sourceCheck "source-tests" ''
          cd packages/tailwindcss-language-syntax
          pnpm run build
          pnpm run test

          cd ../tailwindcss-language-service
          pnpm run build
          pnpm run test

          cd ../tailwindcss-language-server
          pnpm run build
          pnpm run test
        '';
      };
    };
    devShells = {
      ${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nodejs_24
          pkgs.pnpm_10
          pkgs.tailwindcss-language-server
        ];
      };
    };
  };
}
