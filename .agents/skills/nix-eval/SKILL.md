---
name: nix-eval
description: Evaluate narrow Nix values from this flake. Use when Codex needs merged Home Manager values, option definition sources or override priorities, flake or package attributes, source paths, package artifacts, attrset keys, pinned input paths, or profile comparisons.
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

### Evaluate one final Home Manager value

```bash
nix eval .#homeConfigurations.fym.config.programs.zoxide.enable
```

### List keys before drilling into an attrset

```bash
nix eval .#homeConfigurations.fym.config.programs --apply builtins.attrNames --json
```

### Evaluate an attribute name containing `/`

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).homeConfigurations.fym.config.xdg.configFile."tmux/tmux.conf"'
```

### Compare narrow final values across profiles

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

### Inspect the winning definitions of an option

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

### Resolve and, when needed, realize a path

`nix eval` returns the requested value. When that value is a store path needed
for inspection but the path does not exist, realize the original expression
with `nix build`. This is an explicit step because it may fetch or build
dependencies. The `nix eval` result is an intermediate path; the `nix build`
result is realized.

Pinned input source:

```bash
nix eval --raw .#inputs.home-manager.outPath
```

Package artifact:

```bash
nix eval --raw .#packages.x86_64-linux.waybar-niri-taskbar-focused
```

Package source:

```bash
nix eval --raw nixpkgs#packages.x86_64-linux.bash.src
```

Realize when needed:

```bash
nix build --no-link --print-out-paths <flake-url>#<attr-path>
```

The package `src` value denotes the original upstream source input. Patches are
applied later during the package build.
