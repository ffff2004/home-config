{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  nix,
  coreutils,
}:
let
  runtimeInputs = [
    bash
    nix
    coreutils
  ];
in
stdenvNoCC.mkDerivation {
  pname = "nix-py";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src/nix-py.sh" "$out/libexec/nix-py/nix-py"
    makeWrapper "$out/libexec/nix-py/nix-py" "$out/bin/nix-py" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Run Python with Nix-provided packages (repo-local wrapper)";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "nix-py";
  };
}
