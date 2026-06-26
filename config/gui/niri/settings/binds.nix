{
  config,
  lib,
  ...
}:

{
  programs.niri.settings.binds =
    with config.lib.niri.actions;
    let
      inherit (lib) mkDefault;
      spawnSplit = cmd: {
        spawn = lib.splitString " " cmd;
      };
      lockSession = config.local.gui.lockSession.command;
    in
    {
      # Hotkey overlay
      "Mod+Shift+Slash".action = mkDefault show-hotkey-overlay;

      # Program launchers
      "Mod+T" = mkDefault {
        action = spawn "xdg-terminal-exec";
        repeat = false;
        hotkey-overlay.title = "Open a Terminal";
      };
      "Mod+Space" = mkDefault {
        action = spawn "fuzzel";
        repeat = false;
        hotkey-overlay.title = "Run an Application: fuzzel";
      };

      "XF86Calculator" = {
        action = mkDefault (spawnSplit "xdg-terminal-exec python");
        repeat = false;
      };

      # Screen reader toggle
      # "Super+Alt+S" = mkDefault {
      #   action = spawn-sh "pkill orca || exec orca";
      #   allow-when-locked = true;
      #   hotkey-overlay.hidden = true;
      # };

      # Overview toggle
      "Mod+Tab" = mkDefault {
        action = toggle-overview;
        repeat = false;
      };

      # Window close
      "Alt+F4" = mkDefault {
        action = close-window;
        repeat = false;
      };
      "Mod+Q" = mkDefault {
        action = close-window;
        repeat = false;
      };

      # Focus navigation
      "Mod+Left".action = mkDefault focus-column-left;
      "Mod+Down".action = mkDefault focus-window-down;
      "Mod+Up".action = mkDefault focus-window-up;
      "Mod+Right".action = mkDefault focus-column-right;
      # "Alt+Tab".action = mkDefault focus-column-right;
      "Alt+Shift+Tab".action = mkDefault focus-column-left;

      # Move window/column
      "Mod+Ctrl+Left".action = mkDefault move-column-left;
      "Mod+Ctrl+Right".action = mkDefault move-column-right;
      # "Mod+Ctrl+Down".action = mkDefault move-window-down;
      # "Mod+Ctrl+Up".action = mkDefault move-window-up;
      # "Mod+Ctrl+Page_Down".action = mkDefault move-column-to-workspace-down;
      # "Mod+Ctrl+Page_Up".action = mkDefault move-column-to-workspace-up;
      "Mod+Ctrl+Down".action = mkDefault move-column-to-workspace-down;
      "Mod+Ctrl+Up".action = mkDefault move-column-to-workspace-up;
      "Mod+Ctrl+U".action = mkDefault move-column-to-workspace-down;
      "Mod+Ctrl+I".action = mkDefault move-column-to-workspace-up;

      # First/Last column
      "Mod+Home".action = mkDefault focus-column-first;
      "Mod+End".action = mkDefault focus-column-last;
      "Mod+Ctrl+Home".action = mkDefault move-column-to-first;
      "Mod+Ctrl+End".action = mkDefault move-column-to-last;

      # Monitor navigation
      "Mod+Shift+Left".action = mkDefault focus-monitor-left;
      "Mod+Shift+Down".action = mkDefault focus-monitor-down;
      "Mod+Shift+Up".action = mkDefault focus-monitor-up;
      "Mod+Shift+Right".action = mkDefault focus-monitor-right;

      # Move column to monitor
      "Mod+Shift+Ctrl+Left".action = mkDefault move-column-to-monitor-left;
      "Mod+Shift+Ctrl+Down".action = mkDefault move-column-to-monitor-down;
      "Mod+Shift+Ctrl+Up".action = mkDefault move-column-to-monitor-up;
      "Mod+Shift+Ctrl+Right".action = mkDefault move-column-to-monitor-right;

      # Workspace navigation
      "Mod+Page_Down".action = mkDefault focus-workspace-down;
      "Mod+Page_Up".action = mkDefault focus-workspace-up;
      "Mod+U".action = mkDefault focus-workspace-down;
      "Mod+I".action = mkDefault focus-workspace-up;

      # Move whole workspace
      "Mod+Shift+Page_Down".action = mkDefault move-workspace-down;
      "Mod+Shift+Page_Up".action = mkDefault move-workspace-up;
      "Mod+Shift+U".action = mkDefault move-workspace-down;
      "Mod+Shift+I".action = mkDefault move-workspace-up;

      # Mouse wheel workspace navigation
      "Mod+WheelScrollDown" = mkDefault {
        action = focus-workspace-down;
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = mkDefault {
        action = focus-workspace-up;
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollDown" = mkDefault {
        action = move-column-to-workspace-down;
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollUp" = mkDefault {
        action = move-column-to-workspace-up;
        cooldown-ms = 150;
      };

      # Mouse wheel column navigation
      "Mod+WheelScrollRight".action = mkDefault focus-column-right;
      "Mod+WheelScrollLeft".action = mkDefault focus-column-left;
      "Mod+Ctrl+WheelScrollRight".action = mkDefault move-column-right;
      "Mod+Ctrl+WheelScrollLeft".action = mkDefault move-column-left;

      # Shifted horizontal scroll
      "Mod+Shift+WheelScrollDown".action = mkDefault focus-column-right;
      "Mod+Shift+WheelScrollUp".action = mkDefault focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown".action = mkDefault move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp".action = mkDefault move-column-left;

      # Workspace index navigation
      "Mod+1".action = mkDefault (focus-workspace 1);
      "Mod+2".action = mkDefault (focus-workspace 2);
      "Mod+3".action = mkDefault (focus-workspace 3);
      "Mod+4".action = mkDefault (focus-workspace 4);
      "Mod+5".action = mkDefault (focus-workspace 5);
      "Mod+6".action = mkDefault (focus-workspace 6);
      "Mod+7".action = mkDefault (focus-workspace 7);
      "Mod+8".action = mkDefault (focus-workspace 8);
      "Mod+9".action = mkDefault (focus-workspace 9);
      # "Mod+Ctrl+1".action = mkDefault (move-column-to-workspace 1);
      # "Mod+Ctrl+2".action = mkDefault (move-column-to-workspace 2);
      # "Mod+Ctrl+3".action = mkDefault (move-column-to-workspace 3);
      # "Mod+Ctrl+4".action = mkDefault (move-column-to-workspace 4);
      # "Mod+Ctrl+5".action = mkDefault (move-column-to-workspace 5);
      # "Mod+Ctrl+6".action = mkDefault (move-column-to-workspace 6);
      # "Mod+Ctrl+7".action = mkDefault (move-column-to-workspace 7);
      # "Mod+Ctrl+8".action = mkDefault (move-column-to-workspace 8);
      # "Mod+Ctrl+9".action = mkDefault (move-column-to-workspace 9);

      # Consume/expel window
      "Mod+BracketLeft".action = mkDefault consume-or-expel-window-left;
      "Mod+BracketRight".action = mkDefault consume-or-expel-window-right;

      # Column/window sizing presets
      "Mod+R".action = mkDefault switch-preset-column-width;
      "Mod+Shift+R".action = mkDefault switch-preset-window-height;
      "Mod+Ctrl+R".action = mkDefault reset-window-height;
      "Mod+F".action = mkDefault maximize-column;
      "Mod+Shift+F".action = mkDefault fullscreen-window;
      "Mod+Ctrl+F".action = mkDefault expand-column-to-available-width;

      # Column width adjustment
      "Mod+Minus".action = mkDefault (set-column-width "-10%");
      "Mod+Equal".action = mkDefault (set-column-width "+10%");

      # Window height adjustment
      "Mod+Shift+Minus".action = mkDefault (set-window-height "-10%");
      "Mod+Shift+Equal".action = mkDefault (set-window-height "+10%");

      # Tabbed display toggle
      "Mod+W".action = mkDefault toggle-column-tabbed-display;

      # Floating toggle
      "Mod+Ctrl+Shift+F".action = mkDefault toggle-window-floating;

      # Screenshots
      "Print".action = mkDefault { screenshot = [ ]; };
      "Ctrl+Print".action = mkDefault { screenshot-window = [ ]; };
      "Alt+Print".action = mkDefault { screenshot-screen = [ ]; };
      ## Laptop
      "Super+Shift+S".action = mkDefault { screenshot = [ ]; };
      "Ctrl+Super+Shift+S".action = mkDefault { screenshot-window = [ ]; };
      "Alt+Super+Shift+S".action = mkDefault { screenshot-screen = [ ]; };

      # Inhibitor escape hatch
      "Mod+Escape" = mkDefault {
        action = toggle-keyboard-shortcuts-inhibit;
        allow-inhibiting = false;
      };

      # Quit
      "Mod+Shift+E".action = mkDefault quit;
      "Ctrl+Alt+Delete".action = mkDefault quit;

      # Power off monitors
      "Mod+Shift+P".action = mkDefault power-off-monitors;

      "Super+L" = mkDefault {
        action = spawn lockSession;
        repeat = false;
        hotkey-overlay.title = "Lock the Screen";
      };

      "XF86AudioRaiseVolume" = mkDefault {
        action = spawnSplit "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = mkDefault {
        action = spawnSplit "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-";
        allow-when-locked = true;
      };
      "XF86AudioMute" = mkDefault {
        action = spawnSplit "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        repeat = false;
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = mkDefault {
        action = spawnSplit "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        repeat = false;
        allow-when-locked = true;
      };

      "XF86MonBrightnessUp" = mkDefault {
        action = spawnSplit "brightnessctl --class=backlight set 2%+ -d intel_backlight";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = mkDefault {
        action = spawnSplit "brightnessctl --class=backlight set 2%- -d intel_backlight";
        allow-when-locked = true;
      };
    };
}
