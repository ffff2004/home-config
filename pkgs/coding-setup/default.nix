{
  lib,
  writeShellApplication,
}:
writeShellApplication {
  name = "coding-setup";
  runtimeInputs = [ ];
  text = builtins.readFile ./coding-setup.sh;

  meta = with lib; {
    description = "Set up a tmux coding workspace";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "coding-setup";
  };
}
