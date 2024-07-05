{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = {nixpkgs, ...}: let
    forAllSystems = f:
      nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (
        system:
          f (let
            pkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = false;
                permittedInsecurePackages = [
                  # TODO: Debug which package depends on this.
                  "openssl-1.1.1w"
                ];
              };
            };
          in {
            inherit pkgs;
          })
      );
  in {
    devShells = forAllSystems (
      {
        pkgs,
        ...
      }: {
        default = with pkgs;
          mkShell {
            packages = [
              just
              podman
            ];
          };
      }
    );
  };
}
