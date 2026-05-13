rec {
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

    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://fym998-nur.cachix.org"
      "https://pre-commit-hooks.cachix.org"
      "https://cache.nixos.org/"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "fym998-nur.cachix.org-1:lWwztkEXGJsiJHh/5FbA2u95AxJu8/k4udgGqdFLhOU="
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
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
      homeConfigRoot = "${homeDirectory}/repos/home-config";
    in
    rec {
      inherit
        pkgs
        self
        inputs
        mkLib
        ;

      packages.${system} = {
        codex-config-sync = pkgs.callPackage ./pkgs/codex-config-sync { };
      };

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
            home.stateVersion = "26.05"; # Do not change!

            programs.home-manager.enable = true;
            manual = {
              html.enable = true;
              json.enable = true;
              manpages.enable = true;
            };
          }

          {
            nix =
              let
                flakes = {
                  home-config = self;
                }
                // builtins.removeAttrs inputs [ "self" ];
              in
              {
                registry = builtins.mapAttrs (_: flake: { inherit flake; }) flakes;
                channels = flakes;
                package = pkgs.nix;
                settings = nixConfig;
              };
          }
        ];
      };
    };
}
