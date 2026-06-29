{
  config,
  lib,
  pkgs,
  ...
}:
let
  cliphistFuzzelImg = lib.getExe' config.services.cliphist.package "cliphist-fuzzel-img";
  cliphistPicker = pkgs.writeShellApplication {
    name = "gui-cliphist-picker";
    runtimeInputs = [
      config.services.cliphist.package
      config.services.cliphist.clipboardPackage
      config.programs.fuzzel.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
    ];
    text = ''
      exec ${cliphistFuzzelImg}
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
