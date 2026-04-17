{
  description = "Home Manager configuration of fym";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fym998-nur = {
      url = "github:fym998/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      # global
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkLib = import ./lib;

      # user
      username = "fym";
      homeDirectory = "/home/${username}";
      homeConfigRoot = "${homeDirectory}/.config/home-manager";
    in
    rec {
      inherit
        pkgs
        self
        inputs
        mkLib
        ;

      localLib = mkLib rec {
        inherit pkgs;

        inherit (pkgs) lib;

        hmLib = import "${inputs.home-manager}/modules/lib" { inherit lib; };

        sourceRoot = {
          source = homeConfigRoot;
          inStore = ./.;
        };
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit self inputs localLib;
          pkgsFrom = builtins.mapAttrs (_: f: (f.packages or { }).${system} or { }) inputs;
        };

        modules = [
          ./config
          ./modules

          {
            home = { inherit username homeDirectory; };
          }
        ];
      };
    };
}
