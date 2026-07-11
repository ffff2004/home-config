{ config, lib, ... }:
let
  inherit (lib) mkDefault;
  playerctl = lib.getExe config.services.playerctld.package;

  mediaBind =
    command:
    mkDefault {
      action = {
        spawn = [
          playerctl
          command
        ];
      };
      allow-when-locked = true;
      repeat = false;
    };
in
{
  services.playerctld.enable = true;

  programs.niri.settings.binds = {
    "XF86AudioPlay" = mediaBind "play-pause";
    "XF86AudioStop" = mediaBind "pause";
    "XF86AudioNext" = mediaBind "next";
    "XF86AudioPrev" = mediaBind "previous";
  };
}
