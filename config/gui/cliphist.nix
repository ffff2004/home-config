{
  config,
  lib,
  pkgs,
  ...
}:
let
  cliphistPicker = pkgs.writeShellApplication {
    name = "gui-cliphist-picker";
    runtimeInputs = [
      config.services.cliphist.package
      config.services.cliphist.clipboardPackage
      config.programs.fuzzel.package
    ];
    text = ''
      selection="$(cliphist list | fuzzel --dmenu --prompt='Clipboard> ')" || exit 0
      [[ -n "$selection" ]] || exit 0

      printf '%s' "$selection" | cliphist decode | wl-copy
    '';
  };
in
{
  services.cliphist = {
    enable = true;
    extraOptions = [
      "-max-dedupe-search"
      "100"
      "-max-items"
      "100"
    ];
  };

  home.packages = [ cliphistPicker ];

  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+V" = lib.mkDefault {
      action = spawn (lib.getExe cliphistPicker);
      repeat = false;
      hotkey-overlay.title = "Clipboard History";
    };
  };
}
