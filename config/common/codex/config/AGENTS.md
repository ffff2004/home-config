## System Info
- CPU: Intel Core i7-12700H (14 cores)
- RAM: 32 GiB
- GPU: NVIDIA GeForce RTX 3060 Mobile ~5.8 GiB
- OS: Arch Linux
- Window Manager: niri (wayland)
- npm & npx unavailable, use pnpm instead.
- pip unavailable, use uv instead.

## Rules
- Never run multiple Git commands that mutate the same repository state in parallel. Git state-changing operations such as `git add`, `git commit`, `git reset`, `git restore --staged`, `git rebase`, and any command that writes `.git` refs or locks must be executed serially.
- If GPU or network access is REALLY needed, do not work around it or give up early. Request approval to run: `nvidia-smi`, `uv ...`, `python ...`, etc.
