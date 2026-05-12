{
  config,
  localLib,
  lib,
  pkgs,
  ...
}:
let
  configRoot = ./config;
in
{
  home.activation.copyCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (
      file:
      let
        relativePath = lib.removePrefix ((toString configRoot) + "/") (toString file);
        source = toString file;
        target = "${config.home.homeDirectory}/.codex/${relativePath}";
      in
      ''
        if [ ! -e ${lib.escapeShellArg target} ]; then
          if [ -x ${lib.escapeShellArg source} ]; then
            run ${pkgs.coreutils}/bin/install -Dm755 ${lib.escapeShellArg source} ${lib.escapeShellArg target}
          else
            run ${pkgs.coreutils}/bin/install -Dm644 ${lib.escapeShellArg source} ${lib.escapeShellArg target}
          fi
        elif ${pkgs.diffutils}/bin/cmp -s ${lib.escapeShellArg source} ${lib.escapeShellArg target}; then
          :
        else
          printf '%s\n' ${lib.escapeShellArg "Codex config differs, not overwriting: ${target}"}
          printf '%s\n' ${lib.escapeShellArg "Run scripts/sync-codex-config.sh --apply from the home-config repo to sync local changes back."}
        fi
      ''
    ) (localLib.lsFileRecursively configRoot)
  );
}
