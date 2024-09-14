{
  description = "";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jsonresume-theme-stackoverflow = {
      url = "github:phoinixi/jsonresume-theme-stackoverflow";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      nixpkgsFor = std.genAttrs systems (system:
        import nixpkgs {
          localSystem = builtins.currentSystem or system;
          crossSystem = system;
          overlays = [];
        });
      stdenvFor = pkgs: pkgs.stdenv;
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
      packages =
        std.mapAttrs (system: pkgs: let
          std = pkgs.lib;
          stdenv = stdenvFor pkgs;
        in {
          # "jsonresume-theme-stackoverflow" = pkgs.buildNpmPackage {
          #   pname = "jsonresume-theme-stackoverflow";
          #   version = inputs.jsonresume-theme-stackoverflow.shortRev;
          #   src = inputs.jsonresume-theme-stackoverflow;
          #   npmDepsHash = "sha256-H3bVs5VmK5eEPvxF85E8v+vAkGQPDjWM+mEKOJ95RMw=";
          #   dontNpmBuild = true;
          # };
          "ashwalker-resume" = pkgs.buildNpmPackage {
            pname = "ashwalker-resume";
            version = "1.0.0";
            src = ./.;
            nativeBuildInputs =
              []
              ++ (with pkgs; [
                resumed
              ]);
            nodejs = pkgs.nodejs_22;
            npmDepsHash = "sha256-JA1be9oUDTNdgNpBC+WpDJefXiXeLmZV1EE9gCCe4Nc=";
            makeCacheWritable = true;
            env = {
              PUPPETEER_SKIP_DOWNLOAD = toString 1;
            };
            preBuild = ''
              resumed validate $src/resume.json
            '';
            buildPhase = ''
              runHook preBuild
              resumed render $src/resume.json -o $out
              runHook postBuild
            '';
            dontInstall = true;
          };
          default = self.packages.${system}."ashwalker-resume";
        })
        nixpkgsFor;
      devShells =
        std.mapAttrs (system: pkgs: let
          selfPkgs = self.packages.${system};
          stdenv = stdenvFor pkgs;
        in {
          default = (pkgs.mkShell.override {inherit stdenv;}) {
            stdenv = stdenvFor.${system};
            inputsFrom = [selfPkgs.default];
          };
        })
        nixpkgsFor;
    };
}
