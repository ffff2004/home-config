{ config, pkgs, ... }:
let
  configHome = config.xdg.configHome;
  fontFamily = builtins.head config.fonts.fontconfig.defaultFonts.sansSerif;
  qtFont = ''"${fontFamily},12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'';
  mkQtctSettings =
    qtct:
    {
      Appearance = {
        color_scheme_path = "${configHome}/${qtct}/colors/matugen.conf";
        custom_palette = true;
        icon_theme = "breeze";
        standard_dialogs = "default";
        style = "Fusion";
      };

      Fonts = {
        fixed = qtFont;
        general = qtFont;
      };

      Interface = {
        activate_item_on_single_click = 1;
        buttonbox_layout = 0;
        cursor_flash_time = 1000;
        dialog_buttons_have_icons = 1;
        double_click_interval = 400;
        gui_effects = "General";
        keyboard_scheme = 2;
        menus_have_icons = true;
        show_shortcuts_in_context_menus = true;
        stylesheets = "@Invalid()";
        toolbutton_style = 4;
        underline_shortcut = 1;
        wheel_scroll_lines = 3;
      };

      Troubleshooting.force_raster_widgets = 1;
    };
in
{
  home = {
    packages = [ pkgs.qt6Packages.qt6ct ];
    sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  qt = {
    enable = true;
    qt5ctSettings = mkQtctSettings "qt5ct";
    qt6ctSettings = mkQtctSettings "qt6ct";
  };

  local.gui.theme.templates = {
    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/qtct.conf
    qt5ct = {
      inputPath = ./qtct.conf;
      outputPath = "${configHome}/qt5ct/colors/matugen.conf";
    };

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/qtct.conf
    qt6ct = {
      inputPath = ./qtct.conf;
      outputPath = "${configHome}/qt6ct/colors/matugen.conf";
    };
  };
}
