{
  description = "wcarlsen's blog flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
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
            mkdocs
            python312Packages.mkdocs-material
            python312Packages.cachecontrol
            python312Packages.cachecontrol.optional-dependencies.filecache
            python312Packages.mkdocs-rss-plugin
          ];
        };
      };
    });
}
