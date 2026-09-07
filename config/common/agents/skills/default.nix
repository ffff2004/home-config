{ inputs, pkgs, ... }:
{
  local.agents.skills = {
    #karpathy-guidelines = "${inputs.andrej-karpathy-skills}/skills/karpathy-guidelines";

    codexctl-as-subagent = "${inputs.codexctl}/examples/codexctl-as-subagent";
    impl-review-orchestrator = "${inputs.codexctl}/examples/impl-review-orchestrator";

    ask-matt = "${inputs.mattpocock-skills}/skills/engineering/ask-matt";
    code-review = "${inputs.mattpocock-skills}/skills/engineering/code-review";
    codebase-design = "${inputs.mattpocock-skills}/skills/engineering/codebase-design";
    diagnosing-bugs = pkgs.applyPatches {
      name = "diagnosing-bugs";
      src = "${inputs.mattpocock-skills}/skills/engineering/diagnosing-bugs";
      patches = [ ./diagnosing-bugs/disable-implicit-invocation.patch ];
    };
    domain-modeling = "${inputs.mattpocock-skills}/skills/engineering/domain-modeling";
    grill-with-docs = "${inputs.mattpocock-skills}/skills/engineering/grill-with-docs";
    improve-codebase-architecture = "${inputs.mattpocock-skills}/skills/engineering/improve-codebase-architecture";
    research = "${inputs.mattpocock-skills}/skills/engineering/research";
    setup-matt-pocock-skills = pkgs.applyPatches {
      name = "setup-matt-pocock-skills";
      src = "${inputs.mattpocock-skills}/skills/engineering/setup-matt-pocock-skills";
      patches = [ ./setup-matt-pocock-skills/issue-tracker-github.patch ];
      postPatch = "rm issue-tracker-github.md.orig";
    };
    prototype = "${inputs.mattpocock-skills}/skills/engineering/prototype";
    tdd = "${inputs.mattpocock-skills}/skills/engineering/tdd";
    to-spec = "${inputs.mattpocock-skills}/skills/engineering/to-spec";
    to-tickets = "${inputs.mattpocock-skills}/skills/engineering/to-tickets";
    triage = "${inputs.mattpocock-skills}/skills/engineering/triage";
    wayfinder = "${inputs.mattpocock-skills}/skills/engineering/wayfinder";

    wizard = "${inputs.mattpocock-skills}/skills/engineering/wizard";

    grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
    handoff = "${inputs.mattpocock-skills}/skills/productivity/handoff";
    teach = "${inputs.mattpocock-skills}/skills/productivity/teach";
    writing-for-agents = "${inputs.mattpocock-skills}/skills/productivity/writing-for-agents";

    orchestrate-impl-review = ./orchestrate-impl-review;
  };
}
