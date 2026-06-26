{
  lib,
  stdenvNoCC,
  python3,
  gnugrep,
  pinentry-curses,
  pinentry-gnome3,
}:
stdenvNoCC.mkDerivation {
  pname = "pinentry-auto";
  version = "0.1.2";

  dontUnpack = true;
  dontBuild = true;
  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    substitute ${./pinentry-auto.py} "$out/bin/pinentry" \
      --replace-fail '@python@' '${lib.getExe python3}' \
      --replace-fail '@pinentry_curses@' '${pinentry-curses}/bin/pinentry' \
      --replace-fail '@pinentry_gnome3@' '${pinentry-gnome3}/bin/pinentry'
    chmod +x "$out/bin/pinentry"

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ gnugrep ];
  installCheckPhase = ''
    runHook preInstallCheck

    ${python3}/bin/python3 -m py_compile "$out/bin/pinentry"
    "$out/bin/pinentry" --help >/dev/null
    "$out/bin/pinentry" --version | grep -q '^pinentry-auto '
    "$out/bin/pinentry" --print-backend --ttyname /dev/tty3 --display :0 | grep -qx 'curses linux-vt'
    "$out/bin/pinentry" --print-backend --ttyname /dev/pts/2 | grep -qx 'curses tty-without-display'
    "$out/bin/pinentry" --print-backend --display :0 | grep -qx 'gnome3 request-display'
    DISPLAY=:0 "$out/bin/pinentry" --print-backend | grep -qx 'gnome3 graphical-env'
    env -u DISPLAY -u WAYLAND_DISPLAY "$out/bin/pinentry" --print-backend | grep -qx 'curses fallback'

    # gpg-agent passes upstream pinentry CLI options before opening the Assuan
    # protocol. These checks prevent regressing into "No pinentry" on startup.
    printf 'BYE\n' | "$out/bin/pinentry" --ttyname /dev/tty3 --ttytype linux >/dev/null
    printf 'BYE\n' | "$out/bin/pinentry" -T /dev/tty3 -N linux >/dev/null

    # Exercise incremental request/response behavior. A previous block-read
    # proxy deadlocked because gpg-agent sends one Assuan command at a time.
    PINENTRY="$out/bin/pinentry" ${python3}/bin/python3 - <<'PY'
    import os
    import select
    import subprocess

    proc = subprocess.Popen(
        [os.environ["PINENTRY"], "--ttyname", "/dev/tty3", "--ttytype", "linux"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        bufsize=0,
    )

    def readline():
        ready, _, _ = select.select([proc.stdout], [], [], 2)
        if not ready:
            raise TimeoutError("timed out waiting for pinentry-auto response")
        line = proc.stdout.readline()
        if not line:
            raise RuntimeError("pinentry-auto exited unexpectedly")
        return line

    assert readline().startswith(b"OK")
    proc.stdin.write(b"GETINFO pid\n")
    proc.stdin.flush()
    assert readline().startswith(b"D ")
    assert readline().startswith(b"OK")
    proc.stdin.write(b"BYE\n")
    proc.stdin.flush()
    assert readline().startswith(b"OK")
    assert proc.wait(timeout=2) == 0
    PY

    runHook postInstallCheck
  '';

  meta = {
    description = "Pinentry proxy that selects a graphical or terminal backend per request";
    license = lib.licenses.mit;
    mainProgram = "pinentry";
    platforms = lib.platforms.linux;
  };
}
