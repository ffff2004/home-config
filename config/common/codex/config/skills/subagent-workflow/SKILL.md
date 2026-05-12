---
name: subagent-workflow
description: Use when the user explicitly asks to use subagents, parallel exploration or investigation, PR review with subagents, or multi-agent debugging. Do not use for small, obvious, single-file edits.
---

# Subagent Workflow Entry

This workflow is opt-in.

It is an entry point for deciding whether to use the repository's subagent workflow. It does not automatically require spawning subagents.

## Do not use this workflow when

* The task is small or obvious.
* The likely change is a single file.
* The implementation path is already clear.
* The work is highly sequential.
* Subagents would need frequent communication with each other.
* Coordination overhead would dominate.
* Multiple agents would likely compete over the same files or design decisions.
* The main agent would need to re-read most raw subagent output anyway.

## Pre-spawn decision checklist

Before spawning any subagents, the main agent must check:

* Has the user explicitly allowed subagents?
* Can the work be split into independent, non-overlapping scopes?
* Is there a clear stop condition for each subagent?
* Will subagent output be much smaller than the raw context it summarizes?
* Is at least one useful subtask read-only?
* Is coordination overhead likely lower than single-agent work?

If the answer is no, continue with a single-agent workflow.

## Required next step

If the workflow is appropriate, read [workflow.md](workflow.md) before spawning any subagents.

If [workflow.md](workflow.md) is missing or cannot be read, do not improvise a multi-agent workflow from memory. Report the issue to the user and proceed with a single-agent workflow.
