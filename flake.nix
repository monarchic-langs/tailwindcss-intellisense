{
  description = "Nix package for Tailwind CSS language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;
    packages.${system}.default = pkgs.tailwindcss-language-server;
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.tailwindcss-language-server pkgs.pnpm];
    };
  };
}
