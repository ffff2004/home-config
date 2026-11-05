{
  lib,
  stdenvNoCC,
  python3,
  runtimeShell,
}:
stdenvNoCC.mkDerivation {
  pname = "umuctl";
  version = "0.1.0";

  src = lib.cleanSource ./.;
  dontBuild = true;
  doCheck = true;
  nativeCheckInputs = [ python3 ];

  checkPhase = ''
    runHook preCheck
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${lib.getExe python3} -m unittest discover -s . -p 'test_*.py' -v
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/libexec" "$out/share/doc/umuctl"
    cp umuctl.py "$out/libexec/umuctl.py"
    cp README.md "$out/share/doc/umuctl/README.md"
    cat > "$out/bin/umuctl" <<EOF
    #!${runtimeShell}
    export UMUCTL_EXECUTABLE="$out/bin/umuctl"
    exec ${lib.getExe python3} "$out/libexec/umuctl.py" "\$@"
    EOF
    chmod +x "$out/bin/umuctl"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/umuctl" --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Manage local UMU applications, Proton presets and desktop entries";
    mainProgram = "umuctl";
    platforms = lib.platforms.linux;
  };
}
