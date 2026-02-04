{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      git-hooks,
      treefmt-nix,
      ...
    }:
    let
      config = builtins.fromJSON (builtins.readFile ./config.json);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
            settings.formatter.oxfmt = {
              command = "${pkgs.oxfmt}/bin/oxfmt";
              options = [ "--no-error-on-unmatched-pattern" ];
              includes = [ "*" ];
            };
          };

          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              treefmt = {
                enable = true;
                package = treefmtEval.config.build.wrapper;
              };
            };
          };

          opener =
            if pkgs.stdenv.isDarwin then "/usr/bin/open" else "${pkgs.lib.getExe' pkgs.xdg-utils "xdg-open"}";
        in
        {
          packages.default = pkgs.writeShellScriptBin config.name ''
            ${opener} "${config.url}"
          '';

          formatter = treefmtEval.config.build.wrapper;

          devShells.default = pkgs.mkShellNoCC {
            packages = [
              pkgs.nodejs_24
              pkgs.pnpm
            ];
            shellHook = ''
              ${pre-commit-check.shellHook}
            '';
          };
        };
    };
}
