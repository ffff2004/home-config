---
name: nix-eval
description: Read-only Nix evaluation for this Home Manager flake. Use it to confirm actual flake outputs, merged Home Manager config values, attribute existence, attrset keys, package attributes, and pinned input paths instead of relying on source search alone.
---

# nix-eval

Use `nix eval` for read-only checks of actual Nix values. Do not use this skill for `nix build`, `home-manager build`, `home-manager switch`, or other state-changing operations.

## When To Use

- Confirm a final value under `homeConfigurations.fym.config`
- Check whether an attribute exists
- List attrset keys before drilling deeper
- Resolve pinned flake input paths
- Verify values produced by imports, option merging, overlays, or package selection

## Rules

1. Prefer non-interactive `nix eval`.
2. Use `--raw` only for strings and paths.
3. Use `--json` when output must be parsed or summarized.
4. For attrset exploration, list keys first with `--apply builtins.attrNames --json`; only evaluate a child attribute after choosing a specific key.
5. Use `nix repl` only when `nix eval` cannot answer the question clearly.
6. Do not evaluate `homeConfigurations.fym.config` or another broad attrset directly unless the user explicitly asks for the full value.

## Commands

Exact Home Manager value:

```bash
nix eval .#homeConfigurations.fym.config.programs.zoxide.enable
```

String or path value:

```bash
nix eval .#homeConfigurations.fym.config.home.username --raw
```

List keys before drilling into an attrset:

```bash
nix eval .#homeConfigurations.fym.config.programs --apply builtins.attrNames --json
```

Check whether an attribute exists:

```bash
nix eval --json --expr 'builtins.hasAttr "zoxide" (builtins.getFlake (toString ./.)).homeConfigurations.fym.config.programs'
```

Resolve the pinned Home Manager input path:

```bash
nix eval --impure --raw /home/fym/repos/home-config#inputs.home-manager.outPath
```

Evaluate a standalone expression:

```bash
nix eval --json --expr '{ foo = 1 + 1; bar = "hello"; }'
```

Manual exploration fallback:

```bash
nix repl .
```

## Output

When reporting results, include:

- The exact command used
- The evaluated value or key list
- Whether the answer is a final merged config value or only an intermediate attrset
