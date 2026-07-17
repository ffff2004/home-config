{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretPatterns = [
    "(^|[^[:alnum:]_])sk-[[:alnum:]_-]+"
    "(^|[^[:alnum:]_])(github_pat_|gh[pousr]_)[[:alnum:]_]+"
    "-----BEGIN ((OPENSSH|RSA|EC|DSA|ENCRYPTED|PGP) )?PRIVATE KEY( BLOCK)?-----"
  ];
  secretPattern = lib.concatStringsSep "|" (map (pattern: "(${pattern})") secretPatterns);
  cliphistFuzzelImg = lib.getExe' config.services.cliphist.package "cliphist-fuzzel-img";
  filteredCliphistStore = pkgs.writeShellApplication {
    name = "gui-filtered-cliphist-store";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      clipboard="$(mktemp)"
      trap 'rm -f "$clipboard"' EXIT

      cat > "$clipboard"

      if grep -qE -- ${lib.escapeShellArg secretPattern} "$clipboard"; then
        exit 0
      fi

      ${lib.getExe config.services.cliphist.package} \
        ${lib.escapeShellArgs config.services.cliphist.extraOptions} \
        store < "$clipboard"
    '';
  };
  cliphistPicker = pkgs.writeShellApplication {
    name = "gui-cliphist-picker";
    runtimeInputs = [
      config.services.cliphist.package
      config.services.cliphist.clipboardPackage
      config.programs.fuzzel.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
    ];
    text = ''
      exec ${cliphistFuzzelImg}
    '';
  };
in
{
  services.cliphist = {
    enable = true;
    extraOptions = [
      "-max-dedupe-search"
      "100"
      "-max-items"
      "100"
    ];
  };

  home.packages = [ cliphistPicker ];

  systemd.user.services.cliphist.Service.ExecStart = lib.mkForce (
    "${lib.getExe' config.services.cliphist.clipboardPackage "wl-paste"}"
    + " --watch ${lib.getExe filteredCliphistStore}"
  );

  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+V" = lib.mkDefault {
      action = spawn (lib.getExe cliphistPicker);
      repeat = false;
      hotkey-overlay.title = "Clipboard History";
    };
  };
}
