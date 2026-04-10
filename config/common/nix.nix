{
  inputs,
  self,
  pkgs,
  ...
}:
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
      settings = {
        substituters = [
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://nix-community.cachix.org"
          "https://fym998-nur.cachix.org"
          "https://pre-commit-hooks.cachix.org"
          "https://cache.nixos.org/"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "fym998-nur.cachix.org-1:lWwztkEXGJsiJHh/5FbA2u95AxJu8/k4udgGqdFLhOU="
          "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
        ];
      };
    };
}
