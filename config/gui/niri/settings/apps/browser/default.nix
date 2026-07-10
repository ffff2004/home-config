{ localLib, ... }:
{
  imports = localLib.lsSubmodule ./.;

  programs.niri.settings.workspaces.browser = { };
}
