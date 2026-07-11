{ inputs, ... }:
{
  local.agents.skills = {
    karpathy-guidelines = "${inputs.andrej-karpathy-skills}/skills/karpathy-guidelines";

    ask-matt = "${inputs.mattpocock-skills}/skills/engineering/ask-matt";
    code-review = "${inputs.mattpocock-skills}/skills/engineering/code-review";
    codebase-design = "${inputs.mattpocock-skills}/skills/engineering/codebase-design";
    diagnosing-bugs = "${inputs.mattpocock-skills}/skills/engineering/diagnosing-bugs";
    domain-modeling = "${inputs.mattpocock-skills}/skills/engineering/domain-modeling";
    grill-with-docs = "${inputs.mattpocock-skills}/skills/engineering/grill-with-docs";
    improve-codebase-architecture = "${inputs.mattpocock-skills}/skills/engineering/improve-codebase-architecture";
    research = "${inputs.mattpocock-skills}/skills/engineering/research";
    setup-matt-pocock-skills = "${inputs.mattpocock-skills}/skills/engineering/setup-matt-pocock-skills";
    prototype = "${inputs.mattpocock-skills}/skills/engineering/prototype";
    tdd = "${inputs.mattpocock-skills}/skills/engineering/tdd";
    to-spec = "${inputs.mattpocock-skills}/skills/engineering/to-spec";
    to-tickets = "${inputs.mattpocock-skills}/skills/engineering/to-tickets";
    triage = "${inputs.mattpocock-skills}/skills/engineering/triage";
    wayfinder = "${inputs.mattpocock-skills}/skills/engineering/wayfinder";

    wizard = "${inputs.mattpocock-skills}/skills/in-progress/wizard";

    grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
    handoff = "${inputs.mattpocock-skills}/skills/productivity/handoff";
    teach = "${inputs.mattpocock-skills}/skills/productivity/teach";
    writing-great-skills = "${inputs.mattpocock-skills}/skills/productivity/writing-great-skills";
  };
}
