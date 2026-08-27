{
  lib,
  writeShellApplication,
  coreutils,
  git,
  gnutar,
  uv,
  zstd,
}:
writeShellApplication {
  name = "export-dependency-wheelhouse";
  runtimeInputs = [
    coreutils
    git
    gnutar
    uv
    zstd
  ];
  text = builtins.readFile ./export-dependency-wheelhouse.sh;

  meta = with lib; {
    description = "Export locked Python dependencies into a compressed wheelhouse archive";
    platforms = platforms.linux;
    mainProgram = "export-dependency-wheelhouse";
  };
}
