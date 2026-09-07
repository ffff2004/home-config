{ pkgs, inputs, ... }:
{
  local.agents.skills = {
    codexctl-as-subagent = "${inputs.codexctl}/examples/codexctl-as-subagent";
    impl-review-orchestrator = "${inputs.codexctl}/examples/impl-review-orchestrator";
  };
  home.file.".codex/skills/command-resume-hook".source =
    "${inputs.codexctl}/examples/command-resume-hook";
  home.packages = [
    (pkgs.callPackage inputs.codexctl { })
  ];
}
