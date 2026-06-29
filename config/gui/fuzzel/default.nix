{
  config,
  lib,
  ...
}:
let
  configHome = config.xdg.configHome;
  terminalExec = lib.getExe config.xdg.terminal-exec.package;
in
{
  programs.fuzzel = {
    enable = true;
    settings.main = {
      include = "${configHome}/fuzzel/themes/matugen.ini";
      lines = 20;
      terminal = terminalExec;
      width = 40;
    };
  };

  local.gui.theme.templates.fuzzel = {
    # Source: /nix/store/png2iiaqb4cxc7928rpfl1ahv6sxppzn-source/Assets/Templates/fuzzel.conf
    inputPath = ./matugen.ini;
    outputPath = "${configHome}/fuzzel/themes/matugen.ini";
  };

  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+Space" = lib.mkDefault {
      action = spawn (lib.getExe config.programs.fuzzel.package);
      repeat = false;
      hotkey-overlay.title = "Run an Application: fuzzel";
    };
  };
}
