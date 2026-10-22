## System Info

- GPU: Intel iGPU + NVIDIA
- Distro: Arch Linux

## Preferences

- Use uv to manage python dependencies and run python scripts (`uv run <SCRIPT>.py` or `uv run python ...`)
- Use pnpm to manage npm dependencies
- Use nix to run ad-hoc tools and build ad-hoc environment
- Git repositories (including cloned checkouts) live in `~/repos`
- User scripts live in `~/.local/sbin`

- When searching the file system, try precise ranges first
- Use the First Principle Thinking
- Prefer simplicity
- When the user makes a mistake, point it out
- When there is ambiguity in the user’s instructions, ask for clarification
- 翻译时保留领域术语作为对照

### Subagents

- After spawning subagents, **do not** do the same work in parallel.
- Be patient with subagents.
- Ask subagents to report pitfalls and friction, so that you can optimize your prompt spawning another subagent.
- 当你的subagent工具可用时，为了节约token和避免context rot，需要探索或者搜索文件系统，且以下条件中至少一条为真时，交给subagent来执行:
  - keyword或match pattern可能的空间很大，或pattern很宽泛，导致可能有很多无关结果
  - 结果所在的文件路径范围不确定，导致需要搜索的范围很大或可能有很多无关文件
- 当你需要进行web search时，如果遇上类似的情况（pattern很宽泛或网址不确定），也交给subagent来执行
