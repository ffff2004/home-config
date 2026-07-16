---
name: home-manager-docs
description: Verify pinned Home Manager contracts. Use when Codex needs exact option metadata, configuration guidance, manual concepts or migration notes, module option discovery, or declaration-level behavior from this repository's pinned home-manager input.
---

# Home Manager Contracts

Establish the option contract here, the effective value with `$nix-eval`, and the built artifact with `$home-manager-generated-paths`.

Use only documentation out-links under `/tmp/home-manager-docs`; repository `result*` links are mutable Home Manager build outputs.

## Evidence branches

| Need | Evidence | Completion criterion |
| --- | --- | --- |
| Exact option metadata | `options.json` through `show` | One exact option name and its type, default, readOnly status, description, and declarations are accounted for. |
| Option discovery | `search`, then `show` | Search candidates are narrowed to an exact option; unresolved candidates remain explicitly unresolved. |
| Configuration guidance | Exact option metadata, then declarations when behavior matters | A minimal valid Nix snippet matches the pinned option type and implementation. |
| Manual concept or migration | Pinned HTML manual | The relevant chapter or release note directly supports the answer. |
| Implementation behavior | Every relevant declaration returned by `show` | The source path implementing the behavior has been read; documentation and implementation differences are resolved in favor of pinned source. |

`options.json` is authoritative for option metadata. The HTML manual is authoritative for narrative guidance. Declaration source is authoritative for implementation behavior. Use manpages only for quick terminal reading.

## Commands

Run from the repository root. From elsewhere, add `--repo-root /home/fym/repos/home-config` before the subcommand.

Search when the exact name is unknown:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py search ssh-agent
```

Show one or several exact options in one invocation:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py show \
  services.ssh-agent.enable \
  sshAuthSock.enable \
  sshAuthSock.systemd.socketProviderUnit
```

Prepare narrative documentation, then search it:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py build html
rg -n "activation|flakes|stateVersion" /tmp/home-manager-docs/html/share/doc/home-manager
```

Print stable documentation paths without building them:

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py paths
```

## Answer contract

- For metadata requests, report the exact option name, type, default, readOnly status, declarations, and a short description when present.
- For configuration requests, lead with a minimal usable Nix snippet and include only metadata that affects the configuration.
- For candidate-only matches, list the relevant candidates and state that they are unresolved name or text matches.
- For behavior claims, name the pinned declaration source used as evidence and label any inference.

The answer is complete when every requested claim is backed by the evidence branch above and no candidate is presented as an exact match.
