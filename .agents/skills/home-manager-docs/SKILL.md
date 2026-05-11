---
name: home-manager-docs
description: Query Home Manager documentation from this repository's pinned home-manager input. Build the needed docs into stable out-links under /tmp/home-manager-docs instead of relying on result* symlinks. Use options.json for exact option metadata, HTML docs for narrative manual content, and declaration source files for implementation details.
---

# Home Manager Docs

Use this skill to answer Home Manager documentation questions against this repository's pinned `home-manager` input. Build docs into stable out-links under `/tmp/home-manager-docs`; do not read repository `result*` links because they may be overwritten by unrelated builds.

## When To Use

- Look up a Home Manager option's type, default, example, readOnly status, description, or declarations
- Find which options a module or feature exposes
- Answer how to configure a Home Manager option in this pinned version
- Search the pinned Home Manager manual for concepts, chapters, migration notes, or tutorial-style explanations
- Confirm option behavior by following declaration paths into the pinned Home Manager source

## Sources

- `options.json`: primary source for exact option metadata
- HTML manual: use for concepts, chapters, migration notes, and narrative explanations
- Module source from option `declarations`: final source for implementation behavior
- Manpage: quick terminal browsing only

## Workflow

1. For option lookup, run `query_hm_options.py show` or `search`. The script builds `docs-json` into `/tmp/home-manager-docs/json` as needed.
2. For manual or conceptual questions, run `query_hm_options.py build html`, then search under `/tmp/home-manager-docs/html/share/doc/home-manager`.
3. If behavior needs confirmation, open the source files listed in the option `declarations`.
4. Prefer the pinned local docs and source over external or remembered Home Manager documentation.
5. Run commands from the repository root when possible. If running elsewhere, pass `--repo-root /home/fym/repos/home-config`.

## Commands

List all built documentation paths:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py paths
```

Build one documentation artifact:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py build html
python .agents/skills/home-manager-docs/scripts/query_hm_options.py build json
python .agents/skills/home-manager-docs/scripts/query_hm_options.py build manpages
```

Show one exact option:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py show programs.zoxide.enable
```

Search options by name, description, or type:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py search zoxide
```

Search narrative HTML manual content after building HTML docs:

```bash
rg -n "activation|flakes|stateVersion" /tmp/home-manager-docs/html/share/doc/home-manager
```

## Output Requirements

- For option questions, include the option name, type, default, readOnly status, declarations, and a short description when available.
- If the user asks how to configure something, provide a minimal usable Nix snippet before deeper explanation.
- If the script returns multiple candidates, do not guess. List the most relevant candidates and explain that they are name or text matches.
- If docs and source could differ, trust the current local build artifacts and pinned source, and state what you used as evidence.

## Limits

- The script uses `nix build --out-link` to prepare documentation artifacts. Existing store paths are usually fast; first builds may take time or require Nix access.
- `options.json` covers option metadata, not the full manual.
- Final confirmation of module behavior should come from the source files pointed to by `declarations`.
