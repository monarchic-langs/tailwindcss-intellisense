{
  description = "Nix package for Tailwind CSS language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
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
      };
    };
    devShells = {
      ${system}.default = pkgs.mkShell {
        packages = [pkgs.tailwindcss-language-server pkgs.pnpm];
      };
    };
  };
}
