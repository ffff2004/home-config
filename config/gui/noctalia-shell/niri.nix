{ lib, config, ... }:
{
  programs.niri.settings = {
    spawn-at-startup = [
      #{ command = [ (lib.getExe config.programs.noctalia-shell.package) ]; }
    ];
    binds =
      let
        noctalia = cmd: {
          spawn = [
            (lib.getExe config.programs.noctalia-shell.package)
            "ipc"
            "call"
          ]
          ++ lib.splitString " " cmd;
        };
      in
      {
        # Core Noctalia
        "Mod+S" = {
          action = noctalia "controlCenter toggle";
          hotkey-overlay.title = "Noctalia ControlCenter";
          repeat = false;
        };
        "Mod+Comma" = {
          action = noctalia "settings toggle";
          hotkey-overlay.title = "Noctalia Settings";
          repeat = false;
        };

        # Audio
        "XF86AudioRaiseVolume" = {
          action = noctalia "volume increase";
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action = noctalia "volume decrease";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action = noctalia "volume muteOutput";
          allow-when-locked = true;
          repeat = false;
        };
        "XF86AudioMicMute" = {
          action = noctalia "volume muteInput";
          allow-when-locked = true;
          repeat = false;
        };

        # Media
        "XF86AudioPlay" = {
          action = noctalia "media playPause";
          allow-when-locked = true;
          repeat = false;
        };
        "XF86AudioStop" = {
          action = noctalia "media pause";
          allow-when-locked = true;
          repeat = false;
        };
        "XF86AudioNext" = {
          action = noctalia "media next";
          allow-when-locked = true;
          repeat = false;
        };
        "XF86AudioPrev" = {
          action = noctalia "media previous";
          allow-when-locked = true;
          repeat = false;
        };

        # Brightness
        "XF86MonBrightnessUp" = {
          action = noctalia "brightness increase";
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = noctalia "brightness decrease";
          allow-when-locked = true;
        };

        # Utilities
        "Mod+V" = {
          action = noctalia "launcher clipboard";
          hotkey-overlay.title = "Noctalia Clipboard History";
          repeat = false;
        };
        # "Super+L" = {
        #   action = noctalia "lockScreen lock";
        #   hotkey-overlay.title = "Lock the Screen";
        #   repeat = false;
        # };
        "Mod+Space" = {
          action = noctalia "launcher toggle";
          hotkey-overlay.title = "Noctalia Launcher";
          repeat = false;
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
