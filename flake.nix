{
  description = "";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    resumed = {
      type = "github";
      owner = "rbardini";
      repo = "resumed";
      ref = "v3.0.1";
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
      stdenvFor = pkgs: pkgs.stdenvAdapters.useMoldLinker pkgs.llvmPackages_latest.stdenv;
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
      packages =
        std.mapAttrs (system: pkgs: let
          std = pkgs.lib;
          stdenv = stdenvFor pkgs;
        in {
          resumed = pkgs.buildNpmPackage {
            pname = "resumed";
            version = "3.0.1";
            nodejs = pkgs.nodejs_18;
            npmBuildScript = "build";
          };
          "ashwalker-resume" = pkgs.buildNpmPackage {
            pname = "ashwalker-resume";
            version = "1.0.0";
            src = ./.;
            nodejs = pkgs.nodejs_18;
            npmDepsHash = "sha256-JA1be9oUDTNdgNpBC+WpDJefXiXeLmZV1EE9gCCe4Nc=";
            npmBuildScript = "resumed";
            npmBuildFlags = ["render" "$src/resume.json" "-o" "$out/resume.html"];
            makeCacheWritable = true;
            env = {
              PUPPETEER_SKIP_DOWNLOAD = toString 1;
            };
            nativeBuildInputs = with pkgs; [
            ];
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
