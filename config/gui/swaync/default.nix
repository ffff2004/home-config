{
  config,
  lib,
  localLib,
  ...
}:
let
  configHome = config.xdg.configHome;
  swayncClient = lib.getExe' config.services.swaync.package "swaync-client";
in
{
  services.swaync = {
    enable = true;

    settings = {
      ignore-gtk-theme = true;
      positionX = "right";
      positionY = "bottom";
      control-center-positionX = "right";
      control-center-positionY = "bottom";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      layer-shell-cover-screen = true;
      cssPriority = "user";

      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      control-center-margin-left = 8;
      control-center-width = 420;
      control-center-height = -1;
      notification-window-width = 420;

      notification-2fa-action = true;
      notification-inline-replies = true;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 8;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = false;
      relative-timestamps = true;
      keyboard-shortcuts = true;
      notification-grouping = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      text-empty = "No Notifications";
      script-fail-notify = true;

      widgets = [
        "title"
        "dnd"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };

        dnd = {
          text = "Do Not Disturb";
        };

        notifications = {
          vexpand = false;
        };
      };
    };
  };

  xdg.configFile."swaync/style.css".source = localLib.mkSymlinkToSource ./style.css;

  local.gui.theme.templates.swaync = {
    inputPath = ./matugen.css;
    outputPath = "${configHome}/swaync/themes/matugen.css";
    postHook = "${swayncClient} --reload-css --skip-wait";
  };
}
