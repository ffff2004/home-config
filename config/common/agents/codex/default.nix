{ localLib, ... }:
{
  imports = [ ./logs-tmpfiles-workaround.nix ];

  home.file = localLib.mkSymlinkToSourceRecursively ".codex" ./config;
}
