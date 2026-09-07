{ localLib, ... }:
{
  imports = [
    ./logs-tmpfiles-workaround.nix
    ./codexctl.nix
  ];

  home.file = localLib.mkSymlinkToSourceRecursively ".codex" ./config;
}
