{
  lib,
  writeShellApplication,
  nix,
}:
writeShellApplication {
  name = "nix-py";
  runtimeInputs = [ nix ];
  text = builtins.readFile ./nix-py.sh;

  meta = with lib; {
    description = "Run Python with Nix-provided packages (repo-local wrapper)";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "nix-py";
  };
}
