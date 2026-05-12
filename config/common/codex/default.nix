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
        target = "${config.home.homeDirectory}/.codex/${relativePath}";
      in
      ''
        run ${pkgs.coreutils}/bin/rm -f ${lib.escapeShellArg target}
        if [ -x ${lib.escapeShellArg (toString file)} ]; then
          run ${pkgs.coreutils}/bin/install -Dm755 ${lib.escapeShellArg (toString file)} ${lib.escapeShellArg target}
        else
          run ${pkgs.coreutils}/bin/install -Dm644 ${lib.escapeShellArg (toString file)} ${lib.escapeShellArg target}
        fi
      ''
    ) (localLib.lsFileRecursively configRoot)
  );
}
