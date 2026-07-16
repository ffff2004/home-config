---
name: nix-eval
description: Evaluate narrow Nix values from this flake. Use when Codex needs merged Home Manager values, option definition sources or override priorities, flake or package attributes, attribute existence, attrset keys, pinned input paths, or comparisons between profiles.
---

# Narrow Nix Evaluation

Establish the option contract with `$home-manager-docs`, the effective value here, and the built artifact with `$home-manager-generated-paths`.

## Steps

1. Narrow the target to the smallest expression that answers the question. For an unfamiliar attrset, list its keys before selecting a child. For profile comparisons, evaluate only the compared fields in one expression.

   Complete when every selected field is relevant and no broad Home Manager config attrset is forced.

2. Evaluate non-interactively with `nix eval`. Use `--raw` for a string or path consumed as text, and `--json` for structured output or machine-readable comparison. Use `nix repl` only when a static expression cannot answer the question clearly.

   Attribute names containing `/` require `--expr` with `builtins.getFlake`; flake attr-path syntax cannot address them reliably.

   Complete when the command exits successfully and its output has the intended representation.

3. Report the exact command, the value or key list, and whether it is a final merged config value or an intermediate value.

   Complete when the provenance of every reported value is explicit.

## Patterns

Evaluate one final Home Manager value:

```bash
nix eval .#homeConfigurations.fym.config.programs.zoxide.enable
```

List keys before drilling into an attrset:

```bash
nix eval .#homeConfigurations.fym.config.programs --apply builtins.attrNames --json
```

Evaluate an attribute name containing `/`:

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).homeConfigurations.fym.config.xdg.configFile."tmux/tmux.conf"'
```

Compare narrow final values across profiles:

```bash
nix eval --impure --json --expr '
  let
    flake = builtins.getFlake (toString ./.);
    gui = flake.homeConfigurations.fym.config;
    tty = flake.homeConfigurations."fym-tty".config;
  in {
    gui = gui.services.ssh-agent.enable;
    tty = tty.services.ssh-agent.enable;
  }
'
```

Inspect the winning definitions of an option:

```bash
nix eval --impure --json --expr '
  let
    profile = (builtins.getFlake (toString ./.)).homeConfigurations.fym;
    option = profile.options.services.ssh-agent.enable;
  in {
    finalValue = option.value;
    priority = option.highestPrio;
    definitions = map (definition: {
      file = definition.file;
      valueType = builtins.typeOf definition.value;
    }) option.definitionsWithLocations;
  }
'
```

`definitionsWithLocations` contains definitions that remain after override priority filtering. Inspect dependent final values and artifacts separately.

Resolve a pinned input path:

```bash
nix eval --impure --raw .#inputs.home-manager.outPath
```
