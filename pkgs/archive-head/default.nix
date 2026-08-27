{
  lib,
  writeShellApplication,
  coreutils,
  git,
}:
writeShellApplication {
  name = "archive-head";
  runtimeInputs = [
    coreutils
    git
  ];
  text = builtins.readFile ./archive-head.sh;

  meta = with lib; {
    description = "Archive the current repository HEAD as a gzip-compressed tarball";
    platforms = platforms.linux;
    mainProgram = "archive-head";
  };
}
