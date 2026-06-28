{
  config,
  pkgs,
  ...
}:
let
  configHome = config.xdg.configHome;
  gtkSyncMode = pkgs.writeShellApplication {
    name = "gui-gtk-sync-mode";
    runtimeInputs = [
      pkgs.dconf
      pkgs.glib
      pkgs.gnugrep
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: gui-gtk-sync-mode dark|light" >&2
        exit 64
      fi

      mode=$1
      case "$mode" in
        dark|light)
          ;;
        *)
          echo "gui-gtk-sync-mode: invalid mode: $mode" >&2
          echo "Expected: dark or light" >&2
          exit 64
          ;;
      esac

      theme=adw-gtk3
      if [ "$mode" = dark ]; then
        theme=adw-gtk3-dark
      fi

      theme_exists() {
        for base in "$HOME/.themes" "$HOME/.local/share/themes" /usr/share/themes /usr/local/share/themes; do
          if [ -d "$base/$theme" ]; then
            return 0
          fi
        done

        IFS=: read -r -a xdg_data_dirs <<< "''${XDG_DATA_DIRS:-}"
        for data_dir in "''${xdg_data_dirs[@]}"; do
          if [ -n "$data_dir" ] && [ -d "$data_dir/themes/$theme" ]; then
            return 0
          fi
        done

        return 1
      }

      if command -v gsettings >/dev/null 2>&1; then
        schemas=$(gsettings list-schemas 2>/dev/null || true)
        if printf '%s\n' "$schemas" | grep -qx 'org.gnome.desktop.interface'; then
          gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
          if theme_exists; then
            gsettings set org.gnome.desktop.interface gtk-theme "$theme"
          fi
          exit 0
        fi
      fi

      if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'"
        if theme_exists; then
          dconf write /org/gnome/desktop/interface/gtk-theme "'$theme'"
        fi
      fi
    '';
  };
in
{
  home.packages = [ gtkSyncMode ];

  gtk = {
    enable = true;
    gtk3.extraCss = ''
      @import url("file://${configHome}/gtk-3.0/matugen.css");
    '';
    gtk4.extraCss = ''
      @import url("file://${configHome}/gtk-4.0/matugen.css");
    '';
  };

  local.gui.theme.templates = {
    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk3.css
    gtk3 = {
      inputPath = ./gtk3.css;
      outputPath = "${configHome}/gtk-3.0/matugen.css";
    };

    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/gtk4.css
    gtk4 = {
      inputPath = ./gtk4.css;
      outputPath = "${configHome}/gtk-4.0/matugen.css";
      postHook = "${gtkSyncMode}/bin/gui-gtk-sync-mode {{mode}}";
    };
  };
}
