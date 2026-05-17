{
  lib,
  writeShellApplication,
  bash,
  coreutils,
  diffutils,
  xclip,
  wl-clipboard,
  clipnotify,
  gnugrep,
  shellcheck,
}:
writeShellApplication {
  name = "clipboard-bridge";
  runtimeInputs = [
    coreutils
    diffutils
    xclip
    wl-clipboard
    clipnotify
    gnugrep
  ];
  text = builtins.readFile ./clipboard-bridge.sh;

  checkPhase = ''
    runHook preCheck

    shellcheck ${./clipboard-bridge.sh}
    ${bash}/bin/bash ${./clipboard-bridge.sh} --help >/dev/null

    runHook postCheck
  '';
  derivationArgs.nativeBuildInputs = [ shellcheck ];

  meta = {
    description = "Bidirectional X11 and Wayland clipboard bridge";
    license = lib.licenses.mit;
    mainProgram = "clipboard-bridge";
    platforms = lib.platforms.linux;
  };
}
