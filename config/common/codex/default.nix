{
  config,
  lib,
  ...
}:
let
  repoRoot = ../../..;
  configRoot = ./config;
  syncScript = ../../../scripts/sync-codex-config.sh;
in
{
  home.activation.copyCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.escapeShellArg (toString syncScript)} activate \
      --repo-root ${lib.escapeShellArg (toString repoRoot)} \
      --config-root ${lib.escapeShellArg (toString configRoot)} \
      --codex-home ${lib.escapeShellArg "${config.home.homeDirectory}/.codex"}
  '';
}
