{
  config,
  lib,
  localLib,
  pkgs,
  ...
}:
let
  configHome = config.xdg.configHome;
  stylePath = "${configHome}/swayosd/style.css";
  swayosdClient = lib.getExe' config.services.swayosd.package "swayosd-client";

  osd = args: {
    action = {
      spawn = [ swayosdClient ] ++ args;
    };
    allow-when-locked = true;
  };

  mediaOsd =
    command:
    (osd [
      "--playerctl"
      command
    ])
    // {
      repeat = false;
    };
in
{
  services.swayosd = {
    enable = true;
    stylePath = stylePath;
    topMargin = 0.85;
  };

  xdg.configFile."swayosd/style.css".source = localLib.mkSymlinkToSource ./style.css;

  local.gui.theme.templates.swayosd = {
    inputPath = ./matugen.css;
    outputPath = "${configHome}/swayosd/themes/matugen.css";
    postHook = "${pkgs.systemd}/bin/systemctl --user try-restart swayosd.service || true";
  };

  programs.niri.settings.binds = {
    "XF86AudioRaiseVolume" = osd [
      "--output-volume"
      "+2"
    ];
    "XF86AudioLowerVolume" = osd [
      "--output-volume"
      "-2"
    ];
    "XF86AudioMute" =
      (osd [
        "--output-volume"
        "mute-toggle"
      ])
      // {
        repeat = false;
      };
    "XF86AudioMicMute" =
      (osd [
        "--input-volume"
        "mute-toggle"
      ])
      // {
        repeat = false;
      };

    "XF86MonBrightnessUp" = osd [
      "--device"
      "intel_backlight"
      "--brightness"
      "+2"
    ];
    "XF86MonBrightnessDown" = osd [
      "--device"
      "intel_backlight"
      "--brightness"
      "-2"
    ];

    "XF86AudioPlay" = mediaOsd "play-pause";
    "XF86AudioStop" = mediaOsd "stop";
    "XF86AudioNext" = mediaOsd "next";
    "XF86AudioPrev" = mediaOsd "prev";
  };
}
