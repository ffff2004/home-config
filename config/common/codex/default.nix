{ localLib, ... }:
{
  imports = [ ./logs-tmpfiles-workaround.nix ];

  home.file.".codex/AGENTS.md".source = localLib.mkSymlinkToSource ./config/AGENTS.md;
}
