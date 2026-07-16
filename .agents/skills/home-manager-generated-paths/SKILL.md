---
name: home-manager-generated-paths
description: Verify Home Manager artifacts. Use when Codex needs to select profiles for artifact builds, map home paths into result/home-files or result/home-path, inspect generated systemd units, identify the source option for a file, or validate generated outputs after a profile build.
---

# Home Manager Artifacts

Establish the option contract with `$home-manager-docs`, the effective value with `$nix-eval`, and the built artifact here.

Use this mapping vocabulary:

`profile -> out-link -> generation -> home path -> artifact path -> source option`

## Artifact map

| Source | Typical artifact |
| --- | --- |
| `home.file`, `xdg.configFile`, `xdg.dataFile` | `GENERATION/home-files/...` |
| `systemd.user.services` and `systemd.user.sockets` | `GENERATION/home-files/.config/systemd/user/...` |
| Packages and profile executables | `GENERATION/home-path/...` |

The final `home.file` attrset contains files materialized by several upstream modules. Treat an attr name as an implementation key until its evaluated `target` or built path confirms the home path.

## Profile selection

Separate profile selection into two sets:

- Candidate profiles import or depend on the changed module.
- Affected profiles may have different final values or artifacts after the change.

Evaluate every candidate with `$nix-eval`, but build only affected profiles. A `config/gui` change normally makes only `fym` a candidate; a `config/common` change makes both `fym` and `fym-tty` candidates.

Use common override patterns only as initial expectations:

| Pattern | Initial expectation | Required evidence |
| --- | --- | --- |
| Common `mkDefault`; GUI normal definition or `mkForce` | GUI is often unchanged | Confirm the GUI final value and dependent artifact are unchanged before and after. |
| Common normal definition; GUI `mkForce` | GUI is often unchanged | Confirm the GUI final value and dependent artifact are unchanged before and after. |
| Common definition; no GUI override | Both profiles are likely affected | Evaluate the final value in both profiles. |
| `mkBefore`, `mkAfter`, or list/attrset merge | The common contribution usually remains | Compare the merged final value; definition priority alone is insufficient. |
| `mkIf` or a profile-dependent condition | Impact depends on each profile's condition | Evaluate the condition and resulting final option in each profile. |

When override priority affects profile selection, use `$nix-eval`'s winning-definition pattern.

Exclude a candidate only when explicit narrow evidence shows that its relevant final values and dependent artifacts are unchanged. Treat missing baseline evidence, incomplete probes, or uncertainty as affected.

## Steps

1. Determine candidate and affected profiles using the profile-selection rules above.

   Complete when every candidate is either affected or excluded with explicit narrow evidence.

2. For every affected profile, evaluate the narrow source option with `$nix-eval`. For file options, inspect `target`; for systemd artifacts, inspect the relevant service or socket; for packages, confirm the selected package.

   Complete when the profile, expected home path, and source option are explicit.

3. Build each affected profile's `activationPackage` with a profile-specific out-link under `/tmp/home-manager-builds/PROFILE`:

   ```bash
   nix build FLAKE#homeConfigurations.PROFILE.activationPackage \
     --out-link /tmp/home-manager-builds/PROFILE
   ```

   Use one invocation and one named out-link per profile. These independent builds may run concurrently because their links do not collide. Reuse the stable profile link across runs; an existing out-link remains a GC root while it exists.

   When repository policy separately requires `home-manager build`, run that validation with `--no-out-link`; use the profile-specific Nix out-link for artifact inspection. For build-only validation of several profiles, one `nix build` may accept several activation packages with `--no-link --print-out-paths`.

   Complete when every inspected profile has a distinct named out-link and `readlink -f` resolves each link to its intended `home-manager-generation`.

4. Inspect the artifact beneath the profile-specific out-link. Follow symlinks, distinguish `home-files` from `home-path`, and verify content when existence alone cannot prove correctness.

   For a user unit, inspect both the evaluated `systemd.user` value and `home-files/.config/systemd/user/NAME.service` or `.socket`.

   Complete when every requested artifact exists or is explicitly confirmed absent, and every symlink or duplicate-looking entry has an accounted-for target.

5. Report candidate profiles, affected profiles, exclusions with evidence, and the artifact mapping for every built profile. Group large results by subsystem.

   Complete when every requested artifact has one full mapping and `home-files`/`home-path` are not conflated.

## Commands

Create a stable artifact link for one affected profile:

```bash
mkdir -p /tmp/home-manager-builds
nix build '.#homeConfigurations."fym-tty".activationPackage' \
  --out-link /tmp/home-manager-builds/fym-tty
readlink -f /tmp/home-manager-builds/fym-tty
```

Inspect a generated config file and an installed executable:

```bash
ls -l /tmp/home-manager-builds/fym-tty/home-files/.config/tmux/tmux.conf
ls -l /tmp/home-manager-builds/fym-tty/home-path/bin/tmux
```

Inspect a generated user unit:

```bash
ls -l /tmp/home-manager-builds/fym-tty/home-files/.config/systemd/user/ssh-agent.service
sed -n '1,160p' /tmp/home-manager-builds/fym-tty/home-files/.config/systemd/user/ssh-agent.service
```

Only when profile selection marks several profiles as affected, build them together without creating links:

```bash
nix build \
  .#homeConfigurations.fym.activationPackage \
  '.#homeConfigurations."fym-tty".activationPackage' \
  --no-link \
  --print-out-paths
```

## Report shape

- Candidate profiles: `fym`, `fym-tty`
- Affected profiles: `fym-tty`
- Excluded: `fym` — relevant final values are unchanged
- Profile: `fym-tty`
- Out-link: `/tmp/home-manager-builds/fym-tty`
- Generation: `/nix/store/...-home-manager-generation`
- Home path: `~/.config/example/config.toml`
- Artifact: `home-files/.config/example/config.toml`
- Source: `xdg.configFile."example/config.toml"`
- Verified: symlink target and relevant content
