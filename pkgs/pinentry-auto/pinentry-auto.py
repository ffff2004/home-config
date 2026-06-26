#!@python@
import argparse
import os
import re
import subprocess
import sys
import threading
from dataclasses import dataclass
from typing import BinaryIO


VERSION = "0.1.2"
CURSES_PINENTRY = "@pinentry_curses@"
GNOME3_PINENTRY = "@pinentry_gnome3@"
GREETING = b"OK Pleased to meet you, this is pinentry-auto\n"
OK = b"OK\n"
UNKNOWN_GETINFO = b"ERR 67109144 IPC parameter error\n"


@dataclass
class RequestContext:
    ttyname: str | None = None
    ttytype: str | None = None
    display: str | None = None
    xauthority: str | None = None
    lc_ctype: str | None = None
    lc_messages: str | None = None


@dataclass
class BackendChoice:
    name: str
    path: str
    reason: str


def is_linux_vt(ttyname: str | None) -> bool:
    return ttyname is not None and re.fullmatch(r"/dev/tty[0-9]+", ttyname) is not None


def has_graphical_env(env: dict[str, str]) -> bool:
    return bool(env.get("DISPLAY") or env.get("WAYLAND_DISPLAY"))


def choose_backend(context: RequestContext, env: dict[str, str]) -> BackendChoice:
    # Linux VTs must win over any graphical environment inherited by gpg-agent.
    # The original gnome3-only setup sent TTY requests to a GUI prompt that was
    # not visible from the active console.
    if is_linux_vt(context.ttyname):
        return BackendChoice("curses", CURSES_PINENTRY, "linux-vt")

    # A tty without a display covers SSH/headless terminals and should not
    # depend on a graphical prompter being available.
    if not context.display and context.ttyname:
        return BackendChoice("curses", CURSES_PINENTRY, "tty-without-display")

    if context.display:
        return BackendChoice("gnome3", GNOME3_PINENTRY, "request-display")

    if has_graphical_env(env):
        return BackendChoice("gnome3", GNOME3_PINENTRY, "graphical-env")

    return BackendChoice("curses", CURSES_PINENTRY, "fallback")


def command_name(line: bytes) -> bytes:
    stripped = line.strip()
    if not stripped:
        return b""
    return stripped.split(maxsplit=1)[0].upper()


def is_staged_command(line: bytes) -> bool:
    command = command_name(line)
    return command == b"OPTION" or command.startswith(b"SET") or command == b"RESET"


def getinfo_response(line: bytes) -> list[bytes] | None:
    # gpg-agent may probe pinentry with GETINFO before sending OPTION ttyname or
    # display. Starting a real backend at that point caused the proxy to enter
    # forwarding too early, so the later context never reached pinentry-curses.
    stripped = line.strip()
    if command_name(stripped) != b"GETINFO":
        return None

    parts = stripped.split(maxsplit=1)
    if len(parts) != 2:
        return [UNKNOWN_GETINFO]

    what = parts[1].lower()
    if what == b"pid":
        return [f"D {os.getpid()}\n".encode(), OK]
    if what == b"version":
        return [f"D {VERSION}\n".encode(), OK]
    if what == b"flavor":
        return [b"D auto\n", OK]

    return [UNKNOWN_GETINFO]


def decode_assuan_value(value: bytes) -> str:
    return value.decode("utf-8", errors="surrogateescape")


def update_context_from_line(context: RequestContext, line: bytes) -> None:
    stripped = line.strip()
    if command_name(stripped) != b"OPTION":
        return

    parts = stripped.split(maxsplit=1)
    if len(parts) != 2 or b"=" not in parts[1]:
        return

    key, value = parts[1].split(b"=", 1)
    key_text = key.decode("ascii", errors="ignore").lower()
    value_text = decode_assuan_value(value)

    if key_text == "ttyname":
        context.ttyname = value_text
    elif key_text == "ttytype":
        context.ttytype = value_text
    elif key_text == "display":
        context.display = value_text
    elif key_text == "xauthority":
        context.xauthority = value_text
    elif key_text == "lc-ctype":
        context.lc_ctype = value_text
    elif key_text == "lc-messages":
        context.lc_messages = value_text


def debug_log(enabled: bool, message: str) -> None:
    if enabled:
        print(f"pinentry-auto: {message}", file=sys.stderr, flush=True)


def read_assuan_response(stdout: BinaryIO) -> bytes:
    response = b""
    while True:
        line = stdout.readline()
        if not line:
            raise RuntimeError("backend pinentry exited while replaying setup")
        response += line
        if line.startswith((b"OK", b"ERR")):
            return response


def start_backend(choice: BackendChoice, backend_args: list[str]) -> subprocess.Popen[bytes]:
    return subprocess.Popen(
        [choice.path, *backend_args],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=None,
    )


def replay_staged_lines(
    backend: subprocess.Popen[bytes],
    staged_lines: list[bytes],
    debug: bool,
) -> None:
    assert backend.stdin is not None
    assert backend.stdout is not None

    greeting = backend.stdout.readline()
    if not greeting.startswith(b"OK"):
        raise RuntimeError(f"backend pinentry returned invalid greeting: {greeting!r}")

    # We acknowledged these setup commands while deciding which backend to use.
    # Replay them so the selected backend still receives the full pinentry
    # context, especially ttyname for curses.
    for line in staged_lines:
        backend.stdin.write(line)
        backend.stdin.flush()
        response = read_assuan_response(backend.stdout)
        if not response.startswith(b"OK"):
            debug_log(debug, f"backend rejected replayed command {line.strip()!r}: {response.strip()!r}")


def pump_stdin_to_backend(src: BinaryIO, dst: BinaryIO) -> None:
    try:
        while True:
            # Assuan is line-oriented. A previous block read could wait forever
            # because gpg-agent sends one command and waits for one response.
            line = src.readline()
            if not line:
                break
            dst.write(line)
            dst.flush()
    finally:
        try:
            dst.close()
        except BrokenPipeError:
            pass


def pump_backend_to_stdout(src: BinaryIO, dst: BinaryIO) -> None:
    while True:
        # Keep response forwarding line-oriented for the same reason as command
        # forwarding: each OK/ERR line can unblock gpg-agent.
        line = src.readline()
        if not line:
            break
        dst.write(line)
        dst.flush()


def activate_backend_and_proxy(
    context: RequestContext,
    staged_lines: list[bytes],
    trigger_line: bytes,
    env: dict[str, str],
    backend_args: list[str],
    debug: bool,
) -> int:
    choice = choose_backend(context, env)
    debug_log(
        debug,
        f"backend={choice.name} reason={choice.reason} ttyname={context.ttyname!r} "
        f"ttytype={context.ttytype!r} display={context.display!r}",
    )

    backend = start_backend(choice, backend_args)
    assert backend.stdin is not None
    assert backend.stdout is not None

    replay_staged_lines(backend, staged_lines, debug)
    backend.stdin.write(trigger_line)
    backend.stdin.flush()

    input_thread = threading.Thread(
        target=pump_stdin_to_backend,
        args=(sys.stdin.buffer, backend.stdin),
        daemon=True,
    )
    input_thread.start()
    pump_backend_to_stdout(backend.stdout, sys.stdout.buffer)
    return backend.wait()


def protocol_mode(context: RequestContext, backend_args: list[str], debug: bool) -> int:
    staged_lines: list[bytes] = []

    sys.stdout.buffer.write(GREETING)
    sys.stdout.buffer.flush()

    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return 0

        if command_name(line) == b"BYE":
            sys.stdout.buffer.write(OK)
            sys.stdout.buffer.flush()
            return 0

        getinfo_lines = getinfo_response(line)
        if getinfo_lines is not None:
            for response_line in getinfo_lines:
                sys.stdout.buffer.write(response_line)
            sys.stdout.buffer.flush()
            continue

        if is_staged_command(line):
            update_context_from_line(context, line)
            staged_lines.append(line)
            sys.stdout.buffer.write(OK)
            sys.stdout.buffer.flush()
            continue

        try:
            return activate_backend_and_proxy(
                context=context,
                staged_lines=staged_lines,
                trigger_line=line,
                env=os.environ,
                backend_args=backend_args,
                debug=debug,
            )
        except Exception as exc:
            debug_log(True, str(exc))
            sys.stdout.buffer.write(f"ERR 67109133 {exc}\n".encode())
            sys.stdout.buffer.flush()
            return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Select a pinentry backend per request context.")
    parser.add_argument("--version", action="store_true", help="print version and backend paths")
    parser.add_argument("--debug", action="store_true", help="write backend selection details to stderr")
    parser.add_argument("--print-backend", action="store_true", help="print the backend selected for test inputs")
    # gpg-agent starts pinentry with the same CLI options supported by upstream
    # pinentry. Rejecting these in protocol mode made gpg-agent report
    # "No pinentry" before the Assuan greeting could be exchanged.
    parser.add_argument("-D", "--display", help="set the display for this request")
    parser.add_argument("-T", "--ttyname", help="set the tty terminal node name")
    parser.add_argument("-N", "--ttytype", help="set the tty terminal type")
    parser.add_argument("-C", "--lc-ctype", dest="lc_ctype", help="set the tty LC_CTYPE value")
    parser.add_argument("-M", "--lc-messages", dest="lc_messages", help="set the tty LC_MESSAGES value")
    parser.add_argument("-o", "--timeout", help="timeout waiting for input after this many seconds")
    parser.add_argument("-g", "--no-global-grab", action="store_true", help="grab keyboard only while focused")
    parser.add_argument("-W", "--parent-wid", help="parent window ID")
    parser.add_argument("-c", "--colors", help="custom colors for ncurses")
    parser.add_argument("-a", "--ttyalert", help="alert mode")
    return parser


def context_from_args(args: argparse.Namespace) -> RequestContext:
    return RequestContext(
        ttyname=args.ttyname,
        ttytype=args.ttytype,
        display=args.display,
        lc_ctype=args.lc_ctype,
        lc_messages=args.lc_messages,
    )


def backend_args_from_args(args: argparse.Namespace, unknown_args: list[str]) -> list[str]:
    backend_args: list[str] = []
    for option, value in [
        ("--display", args.display),
        ("--ttyname", args.ttyname),
        ("--ttytype", args.ttytype),
        ("--lc-ctype", args.lc_ctype),
        ("--lc-messages", args.lc_messages),
        ("--timeout", args.timeout),
        ("--parent-wid", args.parent_wid),
        ("--colors", args.colors),
        ("--ttyalert", args.ttyalert),
    ]:
        if value is not None:
            backend_args.extend([option, value])

    if args.no_global_grab:
        backend_args.append("--no-global-grab")

    backend_args.extend(unknown_args)
    return backend_args


def main() -> int:
    parser = build_parser()
    args, unknown_args = parser.parse_known_args()

    if args.version:
        print(f"pinentry-auto {VERSION}")
        print(f"curses: {CURSES_PINENTRY}")
        print(f"gnome3: {GNOME3_PINENTRY}")
        return 0

    if args.print_backend:
        context = context_from_args(args)
        choice = choose_backend(context, os.environ)
        print(f"{choice.name} {choice.reason}")
        return 0

    return protocol_mode(
        context=context_from_args(args),
        backend_args=backend_args_from_args(args, unknown_args),
        debug=args.debug,
    )


if __name__ == "__main__":
    raise SystemExit(main())
