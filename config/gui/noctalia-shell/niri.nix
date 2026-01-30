{ lib, config, ... }:

lib.mkIf config.programs.noctalia-shell.enable {
  systemd.user.services.noctalia-shell = {
    Service.Environment = lib.pipe config.programs.niri.settings.environment [
      lib.attrsToList
      (map (a: "${a.name}=${a.value}"))
    ];
  };
  programs.niri.settings = {
    binds =
      let
        noctalia =
          cmd:
          [
            (lib.getExe config.programs.noctalia-shell.package)
            "ipc"
            "call"
          ]
          ++ lib.splitString " " cmd;
      in
      {
        # Core Noctalia
        "Mod+S" = {
          action.spawn = noctalia "controlCenter toggle";
          hotkey-overlay.title = "Noctalia ControlCenter";
        };
        "Mod+Comma" = {
          action.spawn = noctalia "settings toggle";
          hotkey-overlay.title = "Noctalia Settings";
        };

        # Audio
        "XF86AudioRaiseVolume" = {
          action.spawn = noctalia "volume increase";
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action.spawn = noctalia "volume decrease";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action.spawn = noctalia "volume muteOutput";
          allow-when-locked = true;
        };
        "XF86AudioMicMute" = {
          action.spawn = noctalia "volume muteInput";
          allow-when-locked = true;
        };

        # Media
        "XF86AudioPlay" = {
          action.spawn = noctalia "media playPause";
          allow-when-locked = true;
        };
        "XF86AudioStop" = {
          action.spawn = noctalia "media pause";
          allow-when-locked = true;
        };
        "XF86AudioNext" = {
          action.spawn = noctalia "media next";
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action.spawn = noctalia "media previous";
          allow-when-locked = true;
        };

        # # Brightness
        # "XF86MonBrightnessUp" =  {
        #   action.spawn = noctalia "brightness increase";
        #   allow-when-locked = true;
        # };
        # "XF86MonBrightnessDown" =  {
        #   action.spawn = noctalia "brightness decrease";
        #   allow-when-locked = true;
        # };

        # Utilities
        "Mod+V" = {
          action.spawn = noctalia "launcher clipboard";
          hotkey-overlay.title = "Noctalia Clipboard History";
        };
        "XF86Calculator".action.spawn = noctalia "launcher calculator";
        # "Super+L" = {
        #   action.spawn = noctalia "lockScreen lock";
        #   hotkey-overlay.title = "Lock the Screen";
        # };
        "Mod+Space" = {
          action.spawn = noctalia "launcher toggle";
          hotkey-overlay.title = "Noctalia Launcher";
        };
      };

    window-rules = [
      # Example: enable rounded corners for all windows
      {
        # geometry-corner-radius = {
        #   top-left = 12.0;
        #   top-right = 12.0;
        #   bottom-left = 12.0;
        #   bottom-right = 12.0;
        # };
        # clip-to-geometry = true;
      }
    ];

    debug = {
      honor-xdg-activation-with-invalid-serial = [ ];
    };

    layer-rules = [
      {
        matches = [
          {
            namespace = "^noctalia-wallpaper*";
          }
        ];
        place-within-backdrop = true;
      }
    ];

    overview.workspace-shadow.enable = false;
  };
}
