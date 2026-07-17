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

## Rules

- Never run multiple Git commands that mutate the same repository state in parallel. Git state-changing operations such as `git add`, `git commit`, `git reset`, `git restore --staged`, `git rebase`, and any command that writes `.git` refs or locks must be executed serially.
- If a permission like GPU or network access is REALLY needed, do not work around it or give up early. Request approval instead.
