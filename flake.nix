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

    fym998-nur = {
      url = "github:fym998/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };

    andrej-karpathy-skills = {
      url = "github:multica-ai/andrej-karpathy-skills";
      flake = false;
    };

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
      "https://fym998-nur.cachix.org"
      "https://pre-commit-hooks.cachix.org"
      "https://cache.nixos.org/"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "fym998-nur.cachix.org-1:lWwztkEXGJsiJHh/5FbA2u95AxJu8/k4udgGqdFLhOU="
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
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
      localLib = mkLib rec {
        inherit pkgs;

        inherit (pkgs) lib;

        hmLib = import "${inputs.home-manager}/modules/lib" { inherit lib; };

        sourceRoot = {
          source = homeConfigRoot;
          inStore = ./.;
        };
      };

      sharedModules = [
        ./config/common
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

      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit
              self
              inputs
              homeConfigRoot
              localLib
              ;
            pkgsFrom = builtins.mapAttrs (_: f: (f.packages or { }).${system} or { }) inputs;
          };

          modules = sharedModules ++ modules;
        };
    in
    rec {
      inherit
        pkgs
        self
        inputs
        mkLib
        localLib
        ;

      packages.${system} = import ./pkgs { inherit pkgs; };

      homeConfigurations = {
        ${username} = mkHome [ ./config/gui ];

        "${username}-tty" = mkHome [ ];
      };
    };
}
