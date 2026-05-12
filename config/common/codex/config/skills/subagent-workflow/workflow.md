# Repo Subagent Workflow

This document describes how to execute the workflow after `SKILL.md` has determined that subagents are appropriate.

Do not use this file to decide whether subagents are allowed. That decision belongs in `SKILL.md`.

## Purpose

Use subagents to reduce main-agent context load and isolate noisy work without creating coordination chaos.

Prefer parallel reading over parallel writing.

The workflow should optimize for:

- Lower main-agent context pressure
- Lower noise from repository search, logs, and test output
- Clear ownership of design and final review
- Minimal duplicated work
- Minimal edit conflicts
- Evidence-based summaries rather than raw process logs

## Main agent responsibilities

The main agent owns:

- Requirement interpretation
- Planning
- Coordination
- Architecture and public API decisions
- Security, auth, payment, and data-model decisions
- Implementation strategy
- Task sequencing
- Integration
- Final diff review
- Final verification decision
- User-facing summary

Subagents may investigate, analyze, implement narrow patches, or review, but they must not take over global design, final integration, or final acceptance.

## Agent selection

Use built-in `explorer` for read-heavy repository exploration.

Use custom `patch_worker` for narrow implementation tasks with explicit file ownership.

Use custom `test_analyst` for test and log triage when available.

Use custom `code_reviewer` for final read-only review of risky, broad, or important changes when available.

## Model selection

Prefer `gpt-5.4-mini` for bounded subagents, including small isolated patches, exploration, and test/log analysis. Use `gpt-5.4` or stronger only for subtle logic, high-risk changes, security/auth/payment/data-model concerns, or final review.

## Cost and coordination Rules:

- Avoid duplicated repository scans.
- Parallelize reading, not writing.
- Keep subagent scopes narrow and non-overlapping.
- Prefer read-only subagents first.
- Keep subagent summaries concise and evidence-based.
- Stop exploration once likely change points are identified.
- Do not include raw logs unless the exact text is necessary.
- Treat subagent output as evidence to evaluate, not as automatic truth.
- If coordination overhead starts to exceed the benefit, stop spawning new subagents and return to the main-agent workflow.

## Sync modes

Default sync mode: pipeline.

### Barrier sync

Use barrier sync for broad read-only exploration, PR review, or independent risk analysis.

Pattern:

1. Spawn independent read-only agents.
2. Wait for all results.
3. Main agent deduplicates findings.
4. Main agent decides next steps.

Use this when parallel perspectives are useful and the main agent should not decide until all findings are available.

### Pipeline sync

Use pipeline sync for bug fixes, feature work, and refactors.

Pattern:

1. Explore.
2. Main agent designs.
3. One narrow worker implements.
4. Reviewer or test analyst verifies.
5. Main agent integrates and reviews.

Use this when later steps depend on earlier conclusions.

### Speculative read-only sync

Use speculative read-only sync for uncertain debugging or design approaches.

Pattern:

1. Spawn read-only agents to investigate competing hypotheses.
2. Do not let them implement.
3. Main agent compares evidence.
4. Main agent chooses one path.

Use this to reduce uncertainty, not to create multiple competing implementations.

## Single-writer rule

At any time, only one agent may own code modifications.

Read-only agents may run in parallel.

Write-capable agents should run sequentially unless their file ownership is explicitly disjoint.

Do not allow two agents to edit the same file or overlapping modules.

If file ownership becomes unclear, stop parallel writing and return control to the main agent.

## Write permission rules

Patch workers may edit only explicitly assigned files.

Subagents must not change the following unless explicitly instructed by the main agent:

- Public APIs
- Auth logic
- Security-sensitive code
- Payment logic
- Database migrations
- Data model semantics
- Dependency versions
- Lockfiles
- Build or release configuration
- Unrelated formatting

Review agents and test-analysis agents must not modify code.

Read-only agents must not perform implementation work.

When using built-in `worker`, the main agent must provide explicit file ownership and a narrow task scope.

## Escalation policy

A subagent must stop and report back instead of acting when:

- The assigned scope is insufficient
- The task requires changing public APIs
- The task touches auth, security, payment, migrations, dependencies, or lockfiles
- Tests indicate a broader design issue
- It needs network access or dependency installation
- It would need to modify files outside its assigned ownership
- It finds conflicting evidence that changes the implementation strategy
- It cannot provide evidence for its conclusion

The subagent should report what it found, why it stopped, and what decision is needed from the main agent.

## Fallback policy

If subagent results conflict:

1. Main agent identifies the conflicting claims.
2. Main agent verifies the smallest necessary evidence directly.
3. Main agent does not merge conclusions blindly.
4. If uncertainty remains, continue with a conservative single-agent workflow.

If a patch worker produces a broad or risky diff:

1. Reject or revert the broad parts.
2. Keep only minimal safe changes if appropriate.
3. Reassign with narrower file ownership if needed.
4. Use a reviewer before final acceptance.

If the workflow becomes more expensive than useful:

1. Stop spawning new subagents.
2. Summarize current findings.
3. Continue with a single-agent workflow.

## Required subagent report format

Each subagent must return:

1. Task assigned
2. Scope inspected
3. Files inspected or changed
4. Key findings
5. Evidence with file paths and symbols or line references when possible
6. Risks or uncertainties
7. Recommended next action

Role-specific agents may include additional fields.

For example, `test_analyst` should also include:

- Commands run
- Test results
- Failure summary

`code_reviewer` should also include:

- Findings ranked by severity
- Suggested fixes
- Missing tests or checks

Patch workers should also include:

- Files changed
- Summary of changes
- Tests or checks run
- Assumptions

## Evidence requirements

Every non-trivial claim should include evidence:

- File path
- Symbol, function, class, route, command, or config name
- Line reference when available
- Command run, if based on test output
- Exact short error text only when necessary

Do not treat subagent agreement as proof without evidence.

Do not accept broad claims such as "the code is fine" or "tests are sufficient" unless supported by concrete files, commands, or inspected behavior.

## Output budget

Subagent reports should be concise.

Prefer:

- Short summaries
- Relevant file paths
- Key evidence
- Risks or uncertainties
- Recommended next action

Avoid:

- Raw logs
- Long command output
- Full file excerpts
- Step-by-step process narration
- Repeating the task prompt
- Speculative conclusions without evidence

Quote raw output only when the exact text is necessary to understand a failure or risk.

## Anti-patterns

Avoid:

- Letting each agent independently design a solution
- Allowing multiple workers to edit the same module
- Using subagents for tiny edits
- Using subagents when the main agent must re-read all raw output anyway
- Treating parallelism as inherently better
- Treating subagent completion as proof that the task is done
- Letting a worker expand scope because the local fix seems convenient
- Letting review agents modify code
- Letting test-analysis agents fix failures directly

## Final review

The main agent must inspect the final diff before finishing.

For larger or riskier changes, use `code_reviewer` before the final response.

The main agent should verify:

- Changed files are expected
- No unrelated files were modified
- Implementation matches the chosen design
- Subagent findings have been deduplicated
- Evidence supports the final conclusion
- Tests or checks are appropriate
- Unresolved risks are stated

The final response should summarize:

- What changed
- Files changed
- Tests or checks run
- Remaining risks or follow-up work

## Done definition

The workflow is done only when:

- The main agent has reviewed the final diff
- Changed files are listed
- Tests or verification steps are reported
- Unresolved risks are stated
- Subagent findings have been deduplicated
- No subagent has unresolved ownership conflicts
- No review or test-analysis subagent has modified code
- The final answer reflects what was actually verified

