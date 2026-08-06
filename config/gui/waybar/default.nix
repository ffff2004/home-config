{
  config,
  lib,
  localLib,
  pkgs,
  pkgsFrom,
  ...
}:
let
  configHome = config.xdg.configHome;
  lockSession = config.local.gui.lockSession.command;
  niri = lib.getExe config.programs.niri.package;
  audioControl = lib.getExe pkgs.pwvucontrol;
  niriTaskbar = pkgsFrom.self.waybar-niri-taskbar-focused;
  niriTaskbarModule = "${niriTaskbar}/lib/waybar/libniri_taskbar.so";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  swayncClient = lib.getExe' config.services.swaync.package "swaync-client";
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
      height = 28;
      spacing = 0;
      fixed-center = true;
      reload_style_on_change = true;

      modules-left = [
        "custom/power"
        "idle_inhibitor"
        "cpu"
        "memory"
        "temperature"
        "mpris"
      ];

      modules-center = [
        "cffi/niri-taskbar"
        "niri/window"
      ];

      modules-right = [
        "tray"
        "wireplumber"
        "wireplumber#source"
        "clock"
        "battery"
        "backlight"
        "custom/notification"
      ];

      "custom/power" = {
        format = "󰐥";
        tooltip = true;
        tooltip-format = "Power / Session";
        menu = "on-click";
        menu-file = "${configHome}/waybar/power-menu.xml";
        menu-actions = {
          lock = lockSession;
          suspend = "systemctl suspend";
          logout = "${niri} msg action quit";
          soft-reboot = "systemctl soft-reboot";
          reboot = "systemctl reboot";
          shutdown = "systemctl poweroff";
        };
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
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
        format = "{icon} {temperatureC}°";
        format-critical = " {temperatureC}°";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
        critical-threshold = 85;
        tooltip-format = "Temperature: {temperatureC}°C";
        thermal-zone = 9;
      };

      mpris = {
        format = "{status_icon} {dynamic}";
        format-paused = "{status_icon} {dynamic}";
        format-stopped = "";
        status-icons = {
          playing = "";
          paused = "";
          stopped = "";
        };
        dynamic-len = 20;
        tooltip-format = "{player}: {artist} - {title}";
      };

      "cffi/niri-taskbar" = {
        module_path = niriTaskbarModule;
        show_all_outputs = false;
      };

      "niri/window" = {
        format = "{title}";
        icon = true;
        icon-size = 18;
        max-length = 42;
        separate-outputs = true;
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };

      wireplumber = {
        format = "{icon} {volume}%";
        format-muted = "󰖁 muted";
        format-icons = [
          ""
          ""
          ""
        ];
        tooltip-format = "{node_name}";
        scroll-step = 2;
        on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = audioControl;
      };

      "wireplumber#source" = {
        node-type = "Audio/Source";
        format = " {volume}%";
        format-muted = " muted";
        tooltip-format = "{node_name}";
        scroll-step = 2;
        on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        on-click-right = audioControl;
      };

      clock = {
        interval = 60;
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "{calendar}";
        calendar = {
          mode = "month";
          weeks-pos = "right";
          format = {
            today = "<b><u>{}</u></b>";
          };
        };
      };

      battery = {
        interval = 30;
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰂄 {capacity}%";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
        states = {
          warning = 30;
          critical = 15;
        };
      };

      backlight = {
        format = "{icon} {percent}%";
        format-icons = [
          "󰃞"
          "󰃟"
          "󰃠"
        ];
        scroll-step = 2;
      };

      "custom/notification" = {
        tooltip = true;
        format = "{icon} {0}";
        format-icons = {
          notification = "󱅫";
          none = "󰂜";
          dnd-notification = "󰂠";
          dnd-none = "󰪓";
          inhibited-notification = "󰂛";
          inhibited-none = "󰪑";
          dnd-inhibited-notification = "󰂛";
          dnd-inhibited-none = "󰪑";
        };
        return-type = "json";
        exec-if = "test -x ${swayncClient}";
        exec = "${swayncClient} --subscribe-waybar";
        on-click = "${swayncClient} --toggle-panel --skip-wait";
        on-click-right = "${swayncClient} --toggle-dnd --skip-wait";
        escape = true;
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
