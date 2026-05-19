# Repo Subagent Workflow

This document describes how to execute the workflow after `SKILL.md` has determined that subagents are appropriate.

Do not use this file to decide whether subagents are allowed. That decision belongs in `SKILL.md`.

## Purpose

Use subagents to reduce main-agent context load and isolate noisy work without creating coordination chaos.

Optimize for:

- Parallel reading over parallel writing
- Clear ownership of design, integration, and final review
- Minimal duplicated repository search, log reading, and test-output parsing
- Narrow, non-overlapping subagent scopes
- Evidence-based summaries instead of raw process logs

Stop spawning subagents when coordination overhead exceeds the benefit.

## Main Agent Ownership

The main agent owns requirement interpretation, planning, coordination, architecture, public API decisions, sensitive-domain decisions, implementation strategy, integration, final diff review, final verification, and the user-facing summary.

Subagents may investigate, analyze, implement narrow patches, or review, but they must not take over global design, final integration, or final acceptance.

## Agent Selection

- Use built-in `explorer` for read-heavy repository exploration. Spawn it with gpt-5.4 model and medium reasoning effort.
- Use custom `patch_worker` for narrow implementation tasks with explicit file ownership.
- Use custom `test_analyst` for test and log triage when available.
- Use custom `code_reviewer` for final read-only review of risky, broad, or important changes when available.

## Sync Patterns

Default sync mode: pipeline.

### Barrier Sync

Use for broad read-only exploration, PR review, or independent risk analysis.

Pattern:

1. Spawn independent read-only agents.
2. Wait for all results.
3. Main agent deduplicates findings.
4. Main agent decides next steps.

### Pipeline Sync

Use for bug fixes, feature work, and refactors where later steps depend on earlier conclusions.

Pattern:

1. Explore.
2. Main agent designs.
3. One narrow worker implements.
4. Reviewer or test analyst verifies.
5. Main agent integrates and reviews.

### Speculative Read-Only Sync

Use for uncertain debugging or competing design hypotheses.

Pattern:

1. Spawn read-only agents to investigate competing hypotheses.
2. Do not let them implement.
3. Main agent compares evidence.
4. Main agent chooses one path.

## Ownership And Write Rules

- Read-only agents may run in parallel.
- At any time, only one agent should own code modifications unless file ownership is explicitly disjoint.
- Do not allow two agents to edit the same file or overlapping modules.
- If file ownership becomes unclear, stop parallel writing and return control to the main agent.
- Patch workers may edit only explicitly assigned files.
- Review agents, test-analysis agents, and read-only agents must not perform implementation work.

Subagents must not change public APIs, auth logic, security-sensitive code, payment logic, database migrations, data-model semantics, dependency versions, lockfiles, build or release configuration, or unrelated formatting unless explicitly instructed by the main agent.

## Stop And Fallback

The subagent should report what it found, why it stopped, and what decision is needed from the main agent.

If subagent results conflict, the main agent identifies the conflicting claims, verifies the smallest necessary evidence directly, and does not merge conclusions blindly. If uncertainty remains, continue with a conservative single-agent workflow.

If a patch worker produces a broad or risky diff, reject or revert the broad parts, keep only minimal safe changes if appropriate, reassign with narrower file ownership if needed, and use a reviewer before final acceptance.

## Report And Evidence

Every non-trivial claim should include a file path, symbol/function/class/route/command/config name, line reference when available, command run when based on test output, and exact short error text only when necessary.

Do not treat subagent agreement as proof without evidence. Do not accept broad claims such as "the code is fine" or "tests are sufficient" unless supported by concrete files, commands, or inspected behavior.

Keep reports concise. Avoid raw logs, long command output, full file excerpts, step-by-step process narration, repeated task prompts, and speculative conclusions without evidence. Quote raw output only when the exact text is necessary to understand a failure or risk.

## Anti-Patterns

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

## Final Review And Done

The main agent must inspect the final diff before finishing. For larger or riskier changes, use `code_reviewer` before the final response.

Before the final response, verify:

- Changed files are expected
- No unrelated files were modified
- Implementation matches the chosen design
- Subagent findings have been deduplicated
- Evidence supports the final conclusion
- Tests or checks are appropriate
- Unresolved risks are stated
- No subagent has unresolved ownership conflicts
- No review or test-analysis subagent has modified code

The final response should summarize what changed, files changed, tests or checks run, and remaining risks or follow-up work.
