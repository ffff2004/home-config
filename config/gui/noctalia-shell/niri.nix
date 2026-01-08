{ lib, config, ... }:

{
  programs.niri.settings = lib.mkIf config.programs.noctalia-shell.enable {
    binds = with config.lib.niri.actions; {
      # Core Noctalia
      "Mod+S" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "controlCenter" "toggle";
        hotkey-overlay.title = "Noctalia ControlCenter";
      };
      "Mod+Comma" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "settings" "toggle";
        hotkey-overlay.title = "Noctalia Settings";
      };

      # Audio
      "XF86AudioRaiseVolume" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "increase";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "decrease";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "muteOutput";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "volume" "muteInput";
        allow-when-locked = true;
      };

      # Media
      "XF86AudioPlay" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "media" "playPause";
        allow-when-locked = true;
      };
      "XF86AudioStop" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "media" "pause";
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "media" "next";
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "media" "previous";
        allow-when-locked = true;
      };

      # # Brightness
      # "XF86MonBrightnessUp" =  {
      #   action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "brightness" "increase";
      #   allow-when-locked = true;
      # };
      # "XF86MonBrightnessDown" =  {
      #   action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "brightness" "decrease";
      #   allow-when-locked = true;
      # };

      # Utilities
      "Mod+V" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "clipboard";
        hotkey-overlay.title = "Noctalia Clipboard History";
      };
      "XF86Calculator".action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "calculator";
      # "Super+L" = {
      #   action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "lockScreen" "lock";
      #   hotkey-overlay.title = "Lock the Screen";
      # };
      "Mod+Space" = {
        action = spawn "qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "toggle";
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
