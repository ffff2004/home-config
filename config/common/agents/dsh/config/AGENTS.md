## System Info

- GPU: Intel iGPU + NVIDIA
- Distro: Arch Linux
- DSH 由 systemd user dsh-web.service 管理

## Preferences

- Use uv to manage python dependencies
- Use pnpm to manage npm dependencies
- Use nix to run ad-hoc tools and build ad-hoc environment
- Git repositories (including cloned checkouts) live in `~/repos`
- Reusable user scripts live in `~/.local/sbin`

- When searching the file system, try precise scope first

- Use the First Principle Thinking
- Prefer simplicity
- When the user makes a mistake, point it out
- When there is ambiguity in the user’s instructions, ask for clarification before action
- 翻译时保留领域术语原文，不做翻译
- 使用skill后报告值得修复/更新/新增的点，但禁止在未获得用户授权时自行修改
- Prefer short documents, avoid unnecessary descriptions; 思考文档的职责（面向的读者和阅读场景），不要直接包含不必要的细节，而是引用其来源（例如代码或其他文档）；如有必要可以拆分/新建文档——职责明确的多个文档好于混杂不清的单个文档
- In UI, avoid unnecessary secondary labels and descriptions; let the layout/interaction do the explaining
- Only write tests that assert our own public interface / contract; do not assert internal implementation or upstream dependencies
- After git pushing, report checks' result if there is

### Subagents

- After spawning subagents, **do not** do the same work in parallel
- Be patient with subagents
- As a subagent, report pitfalls and friction, so that your parent can optimize prompt spawning another subagent
