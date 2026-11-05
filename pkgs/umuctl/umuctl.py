#!/usr/bin/env python3
"""Small, shell-free umu launcher. Requires Python 3.11+ (tomllib)."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import tomllib
import urllib.parse
import urllib.request

ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]*\Z")
ENV_KEY = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")
WINDOWS = re.compile(r"^[A-Za-z]:[\\/]")
ICON_LIMIT = 8 * 1024 * 1024


class Error(Exception):
    pass


def expand(value):
    """Expand HOME only, never shell syntax or arbitrary environment variables."""
    home = os.environ.get("HOME", str(Path.home()))
    value = re.sub(r"\$(?:\{HOME\}|HOME\b)", lambda _match: home, value)
    if value == "~" or value.startswith("~/"):
        value = home + value[1:]
    return value


def path_value(value, base):
    path = Path(expand(value))
    return str(path if path.is_absolute() else base / path)


def executable(value, base):
    if WINDOWS.match(value):
        return value
    value = expand(value)
    return path_value(value, base) if "/" in value else value


def strings(value, label):
    if not isinstance(value, list) or any(not isinstance(v, str) or "\0" in v for v in value):
        raise Error(f"{label} must be an array of strings without NUL bytes")


def validate_table(table, label, fields):
    if not isinstance(table, dict):
        raise Error(f"{label} must be a table")
    unknown = table.keys() - fields
    if unknown:
        raise Error(f"{label}: unknown fields: {', '.join(sorted(unknown))}")
    for key in ("env",):
        env = table.get(key, {})
        if not isinstance(env, dict):
            raise Error(f"{label}.env must be a table")
        for name, value in env.items():
            if not ENV_KEY.fullmatch(name) or type(value) not in (str, int) or "\0" in str(value):
                raise Error(f"{label}.env: invalid name/value for {name!r}; use strings or integers")
    strings(table.get("unset", []), f"{label}.unset")
    if any(not ENV_KEY.fullmatch(v) for v in table.get("unset", [])):
        raise Error(f"{label}.unset contains an invalid environment name")


def icd_files(value, label):
    if not isinstance(value, list) or not value or any(
        not isinstance(item, str) or not item or any(char in item for char in (":", "\0", "\n", "\r"))
        for item in value
    ):
        raise Error(f"{label} must be a nonempty array of nonempty paths without colons, newlines or NUL bytes")
    return value


def gpu_paths(config, name, base):
    if name not in config.get("gpu", {}):
        raise Error(f"unknown GPU profile: {name!r}")
    label = f"gpu.{name}.icd_files"
    values = icd_files(config["gpu"][name].get("icd_files"), label)
    paths = [os.path.abspath(path_value(value, base)) for value in values]
    return icd_files(paths, label)


def validate_icd(path):
    try:
        with Path(path).open(encoding="utf-8") as stream:
            manifest = json.load(stream)
    except (OSError, ValueError, UnicodeError) as exc:
        raise Error(f"cannot read Vulkan ICD manifest {path}: {exc}") from exc
    icd = manifest.get("ICD") if isinstance(manifest, dict) else None
    library = icd.get("library_path") if isinstance(icd, dict) else None
    if not isinstance(library, str) or not library.strip():
        raise Error(f"not a Vulkan ICD manifest: {path} (ICD.library_path must be a nonempty string)")


def effective_icd_paths(env):
    # The newer loader override takes precedence over the legacy variable.
    variable = next((key for key in ("VK_DRIVER_FILES", "VK_ICD_FILENAMES") if key in env), None)
    if variable is None:
        return None, []
    values = icd_files(env[variable].split(":"), variable)
    # Inherited loader paths are relative to cwd, not to the configuration.
    return variable, [os.path.abspath(value) for value in values]


def load_config(path, missing_ok=False):
    try:
        with path.open("rb") as stream:
            config = tomllib.load(stream)
    except FileNotFoundError:
        if missing_ok:
            return {"proton": {}, "gpu": {}, "apps": {}}
        raise Error(f"configuration not found: {path}") from None
    except (OSError, tomllib.TOMLDecodeError) as exc:
        raise Error(f"cannot read configuration {path}: {exc}") from exc
    if config.keys() - {"proton", "gpu", "apps"}:
        raise Error("configuration only supports [proton.ID], [gpu.ID] and [apps.ID] tables")
    profiles = config.setdefault("gpu", {})
    if not isinstance(profiles, dict):
        raise Error("gpu must be a table")
    for key, table in profiles.items():
        if not ID.fullmatch(key) or key == "default":
            raise Error(f"invalid or reserved gpu ID: {key!r}")
        if not isinstance(table, dict) or table.keys() - {"icd_files"}:
            raise Error(f"gpu.{key} must be a table containing only icd_files")
        icd_files(table.get("icd_files"), f"gpu.{key}.icd_files")
    for kind in ("proton", "apps"):
        entries = config.setdefault(kind, {})
        if not isinstance(entries, dict):
            raise Error(f"{kind} must be a table")
        for key, table in entries.items():
            if not ID.fullmatch(key):
                raise Error(f"invalid {kind} ID: {key!r}")
            fields = {"path", "env", "unset"} if kind == "proton" else {
                "name", "exe", "proton", "game_id", "prefix", "wayland", "gpu",
                "icon", "comment", "args", "env", "unset", "before", "after",
            }
            validate_table(table, f"{kind}.{key}", fields)
            for field, value in table.items():
                if field in {"env", "unset", "args", "before", "after", "wayland"}:
                    continue
                if not isinstance(value, str) or "\0" in value or "\n" in value or "\r" in value:
                    raise Error(f"{kind}.{key}.{field} must be a single-line string")
            required = "path" if kind == "proton" else "exe"
            if not table.get(required):
                raise Error(f"{kind}.{key}.{required} is required")
            if "wayland" in table and type(table["wayland"]) is not bool:
                raise Error(f"apps.{key}.wayland must be a boolean")
            strings(table.get("args", []), f"apps.{key}.args")
            for hook in ("before", "after"):
                commands = table.get(hook, [])
                if not isinstance(commands, list):
                    raise Error(f"apps.{key}.{hook} must be an array of argv arrays")
                for command in commands:
                    strings(command, f"apps.{key}.{hook}")
                    if not command or not command[0]:
                        raise Error(f"apps.{key}.{hook}: commands must not be empty")
    for key, app in config["apps"].items():
        if "proton" in app and app["proton"] not in config["proton"]:
            raise Error(f"apps.{key}: unknown proton preset {app['proton']!r}")
        if "gpu" in app and app["gpu"] != "default" and app["gpu"] not in profiles:
            raise Error(f"apps.{key}: unknown GPU profile {app['gpu']!r}")
    return config


def overlay(env, table):
    for key in table.get("unset", []):
        env.pop(key, None)
    env.update({key: str(value) for key, value in table.get("env", {}).items()})


def launch_env(config, app, options, base, inherited=None, validate_gpu=True):
    inherited = dict(os.environ if inherited is None else inherited)
    env = dict(inherited)
    selected = getattr(options, "proton", None)
    preset_id = selected if selected is not None else app.get("proton")
    preset = config["proton"].get(preset_id, {})
    if preset_id is not None and not preset:
        raise Error(f"unknown proton preset: {preset_id}")
    if preset.get("path") and not inherited.get("PROTONPATH"):
        env["PROTONPATH"] = path_value(preset["path"], base)
    overlay(env, preset)
    overlay(env, app)
    if selected is not None:
        env["PROTONPATH"] = path_value(preset["path"], base)
    for field, variable in (("prefix", "WINEPREFIX"), ("game_id", "GAMEID")):
        value = getattr(options, field, None)
        if value is None:
            value = app.get(field)
        if value is not None:
            if field == "prefix" and not value:
                raise Error("prefix must not be empty")
            env[variable] = path_value(value, base) if field == "prefix" else value
    wayland = getattr(options, "wayland", None)
    if wayland is None:
        wayland = app.get("wayland")
    if wayland is not None:
        env["PROTON_ENABLE_WAYLAND"] = "1" if wayland else "0"
    gpu = getattr(options, "gpu", None)
    if gpu is None:
        gpu = app.get("gpu")
    if gpu == "default":
        env.pop("VK_ICD_FILENAMES", None)
        env.pop("VK_DRIVER_FILES", None)
    elif gpu is not None:
        paths = gpu_paths(config, gpu, base)
        if validate_gpu:
            for path in paths:
                validate_icd(path)
        env["VK_ICD_FILENAMES"] = ":".join(paths)
        env.pop("VK_DRIVER_FILES", None)
    for variable in ("WINEPREFIX", "PROTONPATH"):
        if env.get(variable):
            env[variable] = path_value(env[variable], base)
    return env


def status(returncode):
    return returncode if returncode >= 0 else 128 - returncode


def supervise(command, env, before=(), after=(), base=None):
    """Forward INT/TERM to the active process group, then always run cleanup."""
    active = None
    received = None
    cleaning = False

    def forward(signum, _frame):
        nonlocal received
        if cleaning:
            return  # A repeated terminal signal must not interrupt restoration.
        received = signum
        if active is not None:
            try:
                os.killpg(active.pid, signum)
            except ProcessLookupError:
                pass

    def run(argv):
        nonlocal active
        active = subprocess.Popen(argv, env=env, start_new_session=True)
        try:
            return status(active.wait())
        finally:
            active = None

    old = {sig: signal.signal(sig, forward) for sig in (signal.SIGINT, signal.SIGTERM)}
    result = 0
    try:
        try:
            for hook in before:
                result = run([executable(hook[0], base), *map(expand, hook[1:])])
                if result or received:
                    break
            if not result and not received:
                result = run(command)
        except OSError as exc:
            print(f"umuctl: cannot launch command: {exc}", file=sys.stderr)
            result = 127 if isinstance(exc, FileNotFoundError) else 126
        finally:
            cleaning = True
            for hook in after:
                try:
                    code = run([executable(hook[0], base), *map(expand, hook[1:])])
                    if code:
                        print(f"umuctl: after hook exited {code}: {hook[0]}", file=sys.stderr)
                except OSError as exc:
                    print(f"umuctl: after hook failed: {exc}", file=sys.stderr)
    finally:
        for sig, handler in old.items():
            signal.signal(sig, handler)
    return 128 + received if received else result


def desktop_string(value):
    return value.replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")


def desktop_arg(value):
    # Exec quoting is parsed after Desktop Entry string unescaping (not by sh).
    quoted = value.replace("%", "%%")
    for char in ("\\", '"', "`", "$"):
        quoted = quoted.replace(char, "\\" + char)
    return desktop_string('"' + quoted + '"')


def launcher_path():
    candidate = os.environ.get("UMUCTL_EXECUTABLE") or sys.argv[0]
    if not os.path.isabs(candidate):
        candidate = shutil.which(candidate) or str(Path(candidate).absolute())
    # Do not resolve symlinks: the package wrapper, not its Python payload, is needed.
    return candidate


def desktop_entry(key, app, config_path, icon=None):
    argv = [launcher_path(), "--config", str(config_path), "run", key]
    lines = ["[Desktop Entry]", "Type=Application", "Version=1.0",
             "Name=" + desktop_string(app.get("name", key)),
             "Exec=" + " ".join(map(desktop_arg, argv)), "Terminal=false",
             "Categories=Game;"]
    if app.get("comment"):
        lines.append("Comment=" + desktop_string(app["comment"]))
    if icon:
        lines.append("Icon=" + desktop_string(str(icon)))
    return ("\n".join(lines) + "\n").encode()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".umuctl-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def xdg(name, fallback):
    return Path(expand(os.environ.get(name) or fallback)).absolute()


def read_icon(value, base):
    parsed = urllib.parse.urlsplit(value)
    if parsed.scheme in {"http", "https"}:
        with urllib.request.urlopen(value, timeout=15) as response:
            if urllib.parse.urlsplit(response.geturl()).scheme not in {"http", "https"}:
                raise Error("icon redirected to a non-HTTP URL")
            data = response.read(ICON_LIMIT + 1)
        suffix = Path(parsed.path).suffix.lower()
    else:
        path = Path(path_value(value, base))
        with path.open("rb") as stream:
            data = stream.read(ICON_LIMIT + 1)
        suffix = path.suffix.lower()
    if len(data) > ICON_LIMIT:
        raise Error(f"icon exceeds {ICON_LIMIT} bytes")
    if suffix not in {".png", ".svg", ".jpg", ".jpeg", ".webp", ".ico", ".xpm"}:
        raise Error(f"unsupported icon extension: {suffix or '(none)'}")
    return data, suffix


def sync(config, config_path):
    import fcntl

    # Canonicalize directory roots, never leaf files: changed directory symlinks
    # must not redirect an old manifest's cleanup into a different directory.
    desktops = (xdg("XDG_DATA_HOME", "~/.local/share") / "applications").resolve()
    icons = (xdg("XDG_CACHE_HOME", "~/.cache") / "umuctl" / "icons").resolve()
    state = (xdg("XDG_STATE_HOME", "~/.local/state") / "umuctl").resolve()
    state.mkdir(parents=True, exist_ok=True)
    lock = state / "sync.lock"
    if lock.is_symlink():
        raise Error(f"refusing symlink lock: {lock}")
    with lock.open("a") as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        _sync(config, config_path, desktops, icons, state / "manifest.json")


def _sync(config, config_path, desktops, icons, manifest):
    """Only modify exact, unchanged files owned by a previously validated manifest."""
    def safe_target(path):
        return ((path.parent == desktops and re.fullmatch(r"umuctl-[A-Za-z0-9][A-Za-z0-9_-]*\.desktop", path.name))
                or (path.parent == icons and re.fullmatch(r"umuctl-[A-Za-z0-9][A-Za-z0-9_-]*\.(png|svg|jpg|jpeg|webp|ico|xpm)", path.name)))

    previous = {}
    if manifest.is_symlink():
        raise Error(f"refusing symlink manifest: {manifest}")
    if manifest.exists():
        try:
            data = json.loads(manifest.read_text())
            if data.get("version") != 1 or not isinstance(data.get("files"), dict):
                raise ValueError("unsupported manifest format")
            for raw, checksum in data["files"].items():
                path = Path(raw)
                if not safe_target(path) or not isinstance(checksum, str) or not re.fullmatch(r"[0-9a-f]{64}", checksum):
                    raise ValueError(f"unsafe manifest entry: {raw}")
                previous[path] = checksum
        except (ValueError, TypeError, AttributeError) as exc:
            raise Error(f"invalid manifest: {exc}") from exc
    for path, checksum in previous.items():
        if path.is_symlink() or (path.exists() and (not path.is_file() or digest(path.read_bytes()) != checksum)):
            raise Error(f"refusing to modify changed or unsafe owned file: {path}")
    desired = {}
    for key, app in sorted(config["apps"].items()):
        icon = None
        if app.get("icon"):
            data, suffix = read_icon(app["icon"], config_path.parent)
            icon = icons / f"umuctl-{key}{suffix}"
            desired[icon] = data
        desired[desktops / f"umuctl-{key}.desktop"] = desktop_entry(key, app, config_path, icon)
    for path in desired:
        if path.is_symlink() or (path.exists() and path not in previous):
            raise Error(f"refusing to overwrite unrelated file: {path}")
    for path, data in desired.items():
        atomic_write(path, data)
    for path in previous.keys() - desired.keys():
        # safe_target + checksum verification above authorize only generated files.
        if path.exists():
            path.unlink()
    content = {"version": 1, "files": {str(path): digest(data) for path, data in desired.items()}}
    atomic_write(manifest, (json.dumps(content, indent=2, sort_keys=True) + "\n").encode())
    print(f"synced {len(config['apps'])} desktop entries")


def default_prefix(env):
    """Mirror umu's fallback without creating the prefix or other directories."""
    if "WINEPREFIX" in env:
        return env["WINEPREFIX"]
    home = Path(env.get("HOME") or str(Path.home()))
    if env.get("STORE"):
        return str(home / "Games" / env["STORE"])
    return str(home / "Games" / "umu" / (env.get("GAMEID") or "umu-default"))


def resolved_exe(value, prefix, search_path=None):
    if WINDOWS.match(value):
        if not prefix:
            return None
        drive, rest = value[0].lower(), value[3:].replace("\\", "/")
        return Path(prefix) / "dosdevices" / (drive + ":") / rest
    return Path(value) if "/" in value else (Path(found) if (found := shutil.which(value, path=search_path)) else None)


def doctor(config, options, base):
    problems = []

    def check(condition, message):
        if not condition:
            problems.append(message)

    host = executable(options.umu_run, base)
    host_path = resolved_exe(host, None)
    check(host_path is not None and host_path.is_file() and os.access(host_path, os.X_OK), f"umu-run not executable: {host}")
    for key, preset in config["proton"].items():
        path = Path(path_value(preset["path"], base))
        check(path.is_dir() and (path / "proton").is_file() and os.access(path / "proton", os.X_OK), f"proton.{key}: missing Proton directory or executable proton file: {path}")
    for key in config.get("gpu", {}):
        try:
            paths = gpu_paths(config, key, base)
        except Error as exc:
            problems.append(str(exc))
            continue
        for path in paths:
            try:
                validate_icd(path)
            except Error as exc:
                problems.append(f"gpu.{key}: {exc}")
    for key, app in config["apps"].items():
        try:
            env = launch_env(config, app, options, base, validate_gpu=False)
        except Error as exc:
            problems.append(f"apps.{key}: {exc}")
            continue
        try:
            variable, paths = effective_icd_paths(env)
            selection = f"{variable}: {':'.join(paths)}" if variable else "unrestricted (loader defaults)"
            print(f"apps.{key}: effective Vulkan ICD manifests: {selection}")
            for path in paths:
                try:
                    validate_icd(path)
                except Error as exc:
                    problems.append(f"apps.{key}: {exc}")
        except Error as exc:
            print(f"apps.{key}: effective Vulkan ICD manifests: invalid selection")
            problems.append(f"apps.{key}: {exc}")
        prefix = default_prefix(env)
        check(bool(prefix) and Path(prefix).is_dir(), f"apps.{key}: missing prefix: {prefix or '(empty WINEPREFIX)'}")
        check(bool(env.get("PROTONPATH")), f"apps.{key}: PROTONPATH is unset")
        if env.get("PROTONPATH"):
            path = Path(env["PROTONPATH"])
            check(path.is_dir() and (path / "proton").is_file() and os.access(path / "proton", os.X_OK), f"apps.{key}: invalid effective PROTONPATH: {path}")
        exe = executable(app["exe"], base)
        path = resolved_exe(exe, prefix, env.get("PATH", os.defpath))
        check(path is not None and path.is_file(), f"apps.{key}: executable not found: {exe}")
        for hook in (*app.get("before", []), *app.get("after", [])):
            command = executable(hook[0], base)
            path = resolved_exe(command, None, env.get("PATH", os.defpath))
            check(path is not None and path.is_file() and os.access(path, os.X_OK), f"apps.{key}: hook not executable: {command}")
    for problem in problems:
        print("ERROR: " + problem)
    if not problems:
        print("OK: configuration and launch paths validated (no applications launched)")
    return 1 if problems else 0


def parser():
    result = argparse.ArgumentParser(prog="umuctl", description=__doc__)
    result.add_argument("--config", type=Path, help="TOML configuration (default: $XDG_CONFIG_HOME/umuctl/config.toml)")
    result.add_argument("--umu-run", default=os.environ.get("UMUCTL_UMU_RUN", "/usr/bin/umu-run"))
    commands = result.add_subparsers(dest="command", required=True)
    commands.add_parser("list", help="list configured apps")
    run = commands.add_parser("run", help="launch an app; all arguments after ID are forwarded")
    run.add_argument("id")
    run.add_argument("args", nargs=argparse.REMAINDER)
    direct = commands.add_parser("exec", help="launch an unregistered executable")
    for launch in (run, direct):
        launch.add_argument("--proton")
        launch.add_argument("--prefix")
        launch.add_argument("--game-id")
        launch.add_argument("--wayland", action=argparse.BooleanOptionalAction, default=None)
        launch.add_argument("--gpu", metavar="NAME", help="GPU profile name; default clears driver restrictions")
    direct.add_argument("args", nargs=argparse.REMAINDER)
    commands.add_parser("sync", help="synchronize owned desktop entries and cached icons")
    commands.add_parser("doctor", help="validate without launching or creating prefixes")
    return result


def main(argv=None):
    arguments = parser().parse_args(argv)
    config_path = arguments.config or xdg("XDG_CONFIG_HOME", "~/.config") / "umuctl" / "config.toml"
    config_path = Path(expand(str(config_path))).absolute()
    try:
        config = load_config(config_path, missing_ok=arguments.command == "exec" and not arguments.proton)
        base = config_path.parent
        if arguments.command == "list":
            for key, app in sorted(config["apps"].items()):
                print(f"{key}\t{app.get('name', key)}")
            return 0
        if arguments.command == "doctor":
            return doctor(config, arguments, base)
        if arguments.command == "sync":
            sync(config, config_path)
            return 0
        app = {}
        if arguments.command == "run":
            if arguments.id not in config["apps"]:
                raise Error(f"unknown app: {arguments.id}")
            app = config["apps"][arguments.id]
        args = arguments.args
        if args[:1] == ["--"]:
            args = args[1:]
        if arguments.command == "exec" and not args:
            raise Error("exec requires an executable after --")
        env = launch_env(config, app, arguments, base)
        payload = [executable(app["exe"], base), *app.get("args", []), *args] if app else [executable(args[0], base), *args[1:]]
        command = [executable(arguments.umu_run, base), *payload]
        return supervise(command, env, app.get("before", []), app.get("after", []), base)
    except (Error, OSError, ValueError) as exc:
        print(f"umuctl: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
