{
  description = "wcarlsen's iac flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
      };
    in {
      devShells = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            sops
            opentofu
            gh
          ];
        };
      };
    });
}
