{
  config,
  lib,
  pkgsFrom,
  ...
}:
let
  package = pkgsFrom.self.codex-config-sync;
  repoRoot = ../../..;
  configRoot = ./config;
in
{
  home.activation.copyCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.escapeShellArg "${package}/bin/sync-codex-config"} activate \
      --repo-root ${lib.escapeShellArg (toString repoRoot)} \
      --config-root ${lib.escapeShellArg (toString configRoot)} \
      --codex-home ${lib.escapeShellArg "${config.home.homeDirectory}/.codex"}
  '';
}
