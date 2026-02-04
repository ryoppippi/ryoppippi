{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      config = builtins.fromJSON (builtins.readFile ./config.json);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          opener =
            if pkgs.stdenv.isDarwin then
              "/usr/bin/open"
            else
              "${pkgs.lib.getExe' pkgs.xdg-utils "xdg-open"}";
        in
        {
          default = pkgs.writeShellScriptBin config.name ''
            ${opener} "${config.url}"
          '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.nodejs_24
              pkgs.pnpm
            ];
          };
        }
      );
    };
}
