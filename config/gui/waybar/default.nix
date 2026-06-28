{
  config,
  lib,
  localLib,
  pkgs,
  ...
}:
let
  configHome = config.xdg.configHome;
  lockSession = config.local.gui.lockSession.command;
  niri = lib.getExe config.programs.niri.package;
  audioControl = lib.getExe pkgs.pwvucontrol;
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
in
{
  home.packages = [
    pkgs.pwvucontrol
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "bottom";
      height = 32;
      spacing = 8;
      fixed-center = true;
      reload_style_on_change = true;

      modules-left = [
        "custom/power"
        "cpu"
        "memory"
        "temperature"
        "mpris"
      ];

      modules-center = [
        "niri/workspaces"
        "wlr/taskbar"
        "niri/window"
      ];

      modules-right = [
        "tray"
        "wireplumber"
        "wireplumber#source"
        "clock"
        "battery"
        "backlight"
      ];

      "custom/power" = {
        format = "Power";
        tooltip = false;
        menu = "on-click";
        menu-file = "${configHome}/waybar/power-menu.xml";
        menu-actions = {
          lock = lockSession;
          suspend = "systemctl suspend";
          logout = "${niri} msg action quit";
          reboot = "systemctl reboot";
          shutdown = "systemctl poweroff";
        };
      };

      cpu = {
        interval = 2;
        format = "CPU {usage}%";
        tooltip = true;
        tooltip-format = "Load {load}";
      };

      memory = {
        interval = 5;
        format = "RAM {percentage}%";
        tooltip = true;
        tooltip-format = "{used:0.1f}G / {total:0.1f}G";
      };

      temperature = {
        interval = 5;
        format = "TEMP {temperatureC}C";
        critical-threshold = 85;
      };

      mpris = {
        format = "{status} {dynamic}";
        format-paused = "Paused {dynamic}";
        format-stopped = "";
        dynamic-len = 48;
        tooltip-format = "{player}: {artist} - {title}";
      };

      "niri/workspaces" = {
        format = "{value}";
        all-outputs = false;
        hide-empty = false;
      };

      "wlr/taskbar" = {
        format = "{icon}";
        icon-size = 18;
        tooltip-format = "{title}";
        on-click = "activate";
        on-click-middle = "close";
        all-outputs = false;
      };

      "niri/window" = {
        format = "{title}";
        icon = true;
        icon-size = 18;
        max-length = 64;
        separate-outputs = true;
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };

      wireplumber = {
        format = "VOL {volume}%";
        format-muted = "VOL muted";
        tooltip-format = "{node_name}";
        scroll-step = 2;
        on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = audioControl;
      };

      "wireplumber#source" = {
        node-type = "Audio/Source";
        format = "MIC {volume}%";
        format-muted = "MIC muted";
        tooltip-format = "{node_name}";
        scroll-step = 2;
        on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        on-click-right = audioControl;
      };

      clock = {
        interval = 60;
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "month";
          weeks-pos = "right";
        };
      };

      battery = {
        interval = 30;
        format = "BAT {capacity}%";
        format-charging = "BAT {capacity}% charging";
        format-plugged = "BAT {capacity}% plugged";
        states = {
          warning = 30;
          critical = 15;
        };
      };

      backlight = {
        format = "BRI {percent}%";
        scroll-step = 2;
      };
    };
  };

  xdg.configFile = {
    "waybar/style.css".source = localLib.mkSymlinkToSource ./style.css;
    "waybar/power-menu.xml".source = localLib.mkSymlinkToSource ./power-menu.xml;
  };

  local.gui.theme.templates.waybar = {
    inputPath = ./matugen.css;
    outputPath = "${configHome}/waybar/themes/matugen.css";
  };
}
