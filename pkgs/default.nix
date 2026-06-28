{ pkgs, ... }:
{
  # Local package aggregation
  # Purpose: expose repository-local derivations under a single attrset
  # so Home Manager modules can consume them via `pkgsFrom.self.<name>`.
  #
  # How to add a package:
  # 1. Create `pkgs/<name>/default.nix` that builds the package.
  # 2. Add an entry below: `<name> = pkgs.callPackage ./<name> { };`.
  #
  # Guidelines:
  # - Export runnable, reusable programs (CLI/tools) here.
  # - Keep option-orchestration and systemd units in `config/`.
  # - Prefer stable names and add nix checks for critical tools.
  #
  # Shell script example (checks included): codex-config-sync/default.nix

  codex-config-sync = pkgs.callPackage ./codex-config-sync { };
  coding-setup = pkgs.callPackage ./coding-setup { };
  nix-py = pkgs.callPackage ./nix-py { };
  pinentry-auto = pkgs.callPackage ./pinentry-auto { };
}
