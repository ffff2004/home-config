{
  lib,
  writeShellApplication,
  bash,
  coreutils,
  diffutils,
  findutils,
  gitMinimal,
  gnugrep,
  shellcheck,
}:
writeShellApplication {
  name = "sync-codex-config";
  runtimeInputs = [
    coreutils
    diffutils
    findutils
    gitMinimal
    gnugrep
  ];
  text = builtins.readFile ./sync-codex-config.sh;

  checkPhase = ''
    runHook preCheck

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    shellcheck ${./sync-codex-config.sh} ${./test-sync-codex-config.sh}
    ${bash}/bin/bash ${./test-sync-codex-config.sh} "$target"

    runHook postCheck
  '';
  derivationArgs.nativeBuildInputs = [ shellcheck ];

  meta = {
    description = "Synchronize tracked Codex config between the repo and ~/.codex";
    license = lib.licenses.mit;
    mainProgram = "sync-codex-config";
    platforms = lib.platforms.linux;
  };
}
