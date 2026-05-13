{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  diffutils,
  findutils,
  gitMinimal,
  gnugrep,
  shellcheck,
}:
let
  runtimeInputs = [
    bash
    coreutils
    diffutils
    findutils
    gitMinimal
    gnugrep
  ];
in
stdenvNoCC.mkDerivation {
  pname = "codex-config-sync";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    makeWrapper
    shellcheck
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src/sync-codex-config.sh" "$out/libexec/codex-config-sync/sync-codex-config"
    makeWrapper "$out/libexec/codex-config-sync/sync-codex-config" "$out/bin/sync-codex-config" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    install -Dm644 "$src/test-sync-codex-config.sh" \
      "$out/share/codex-config-sync/test-sync-codex-config.sh"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export PATH=${lib.makeBinPath runtimeInputs}:$PATH

    shellcheck "$src/sync-codex-config.sh" "$src/test-sync-codex-config.sh"
    ${bash}/bin/bash "$src/test-sync-codex-config.sh" "$out/bin/sync-codex-config"

    runHook postInstallCheck
  '';

  meta = {
    description = "Synchronize tracked Codex config between the repo and ~/.codex";
    license = lib.licenses.mit;
    mainProgram = "sync-codex-config";
    platforms = lib.platforms.linux;
  };
}
