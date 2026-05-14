{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  diffutils,
  xclip,
  wl-clipboard,
  clipnotify,
  gnugrep,
}:
let
  x11ToWlRuntimeInputs = [
    bash
    coreutils
    diffutils
    xclip
    wl-clipboard
    clipnotify
    gnugrep
  ];
  wlToX11RuntimeInputs = [
    bash
    coreutils
    xclip
    wl-clipboard
  ];
in
stdenvNoCC.mkDerivation {
  pname = "clipboard-bridge";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install x11-to-wl bridge
    install -Dm755 "$src/bridge-x11-to-wl.sh" "$out/libexec/clipboard-bridge/bridge-x11-to-wl"
    makeWrapper "$out/libexec/clipboard-bridge/bridge-x11-to-wl" "$out/bin/clipboard-bridge-x11-to-wl" \
      --prefix PATH : ${lib.makeBinPath x11ToWlRuntimeInputs}

    # Install wl-to-x11 bridge
    install -Dm755 "$src/bridge-wl-to-x11.sh" "$out/libexec/clipboard-bridge/bridge-wl-to-x11"
    makeWrapper "$out/libexec/clipboard-bridge/bridge-wl-to-x11" "$out/bin/clipboard-bridge-wl-to-x11" \
      --prefix PATH : ${lib.makeBinPath wlToX11RuntimeInputs}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Bidirectional X11 ↔ Wayland clipboard bridge services";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
