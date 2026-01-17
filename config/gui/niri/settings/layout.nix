{
  programs.niri.settings.layout = {
    background-color = "transparent";

    gaps = 0;
    struts = rec {
      left = 0;
      right = left;
      top = 0;
      bottom = 0;
    };

    center-focused-column = "never";
    always-center-single-column = true;

    preset-column-widths = [
      { proportion = 0.33333; }
      { proportion = 0.5; }
      { proportion = 0.66667; }
      # { fixed = 1920; }
    ];

    # preset-window-heights = [ ];

    default-column-width = {
      proportion = 0.5;
    };
    # default-column-width = {};

    focus-ring = {
      enable = false;
      width = 2;
      active = {
        color = "#7fc8ff";
      };
      inactive = {
        color = "#505050";
      };
      # active.gradient = {
      #   from = "#80c8ff";
      #   to = "#c7ff7f";
      #   angle = 45;
      # };
      # inactive.gradient = {
      #   from = "#505050";
      #   to = "#808080";
      #   angle = 45;
      #   relative-to = "workspace-view";
      # };
    };

    border = {
      enable = false;
      width = .666;
      active = {
        color = "white";
      };
      inactive = {
        color = "#505050";
      };
      urgent = {
        color = "#bb0000";
      };
      # active.gradient = {
      #   from = "#e5989b";
      #   to = "#ffb4a2";
      #   angle = 45;
      #   relative-to = "workspace-view";
      #   in' = "oklch longer hue";
      # };
      # inactive.gradient = {
      #   from = "#505050";
      #   to = "#808080";
      #   angle = 45;
      #   relative-to = "workspace-view";
      # };
    };

    shadow = {
      enable = true;
      draw-behind-window = true;
      softness = 30;
      spread = 5;
      offset = {
        x = 0;
        y = 5;
      };
      color = "#0007";
    };
  };
}
