{ localLib, inputs, ... }:
{
  imports = [ ./logs-tmpfiles-workaround.nix ];

  home.file = (localLib.mkSymlinkToSourceRecursively ".codex" ./config) // {
    ".codex/skills/command-resume-hook".source = "${inputs.codexctl}/examples/command-resume-hook";
  };
}
