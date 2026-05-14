{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
}:
let
  runtimeInputs = [ bash ];
in
stdenvNoCC.mkDerivation {
  pname = "coding-setup";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src/coding-setup.sh" "$out/libexec/coding-setup/coding-setup"
    makeWrapper "$out/libexec/coding-setup/coding-setup" "$out/bin/coding-setup" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Set up a tmux coding workspace";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "coding-setup";
  };
}
