## System Info

- GPU: Intel iGPU + NVIDIA
- Distro: Arch Linux

## Preferences

- Use uv to manage python dependencies and run python scripts (`uv run <SCRIPT>.py` or `uv run python ...`)
- Use pnpm to manage npm dependencies
- Use nix to run ad-hoc tools and build ad-hoc environment
- Use the First Principle Thinking
- Prefer simplicity
- Git repositories live in `~/repos`
- User scripts live in `~/.local/sbin`

## Rules

- Run multiple Git commands that mutate the same repository state or write `.git` refs or locks *serially*, not in parallel.
- If a command is failed likely due to sandboxing, and a permission like writing files out of the workspace or accessing GPU or network is REALLY needed, do not work around it or give up early, request approval instead.
- When executing a command that takes a long time and the output or exit code matters, wait until the process ends and get the result, do not run again before it ends.

### Sub-agents

- After spawning sub-agents, wait until they complete the work or be blocked. *Do not* do the same work in parallel.
- Ask sub-agents to report trail-and-error and friction, so that you can optimize your prompt next time.
- 为了节约context window和避免context rot，当你需要探索或者搜索一个目录，且以下条件中至少存在一个为真时，启动一个sub-agent来执行:
  - 要搜索的不是一个点，而是一整条路径或者链路
  - keyword或match pattern可能的空间很大，或pattern很宽泛
  - 结果所在的文件路径范围不确定，导致需要搜索的范围很大或可能有很多无关文件
- When using `code-review` or `codebase-design` skill, feel free to spawn sub-agents as the skill asks.
