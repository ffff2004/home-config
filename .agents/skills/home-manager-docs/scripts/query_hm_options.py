#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


DOC_KINDS = ["json", "html", "manpages"]


class CommandError(RuntimeError):
    def __init__(self, cmd: list[str], returncode: int, stdout: str, stderr: str):
        self.cmd = cmd
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr
        super().__init__(f"command failed with exit code {returncode}: {' '.join(cmd)}")


def find_repo_root(start: Path) -> Path:
    for candidate in [start, *start.parents]:
        if (candidate / "flake.nix").exists():
            return candidate
    raise FileNotFoundError(f"no flake.nix found from {start} or its parents")


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode != 0:
        raise CommandError(cmd, result.returncode, result.stdout, result.stderr)
    return result.stdout.strip()


def resolve_home_manager_flake(repo_root: Path) -> str:
    attr_path = f"{repo_root}#inputs.home-manager.outPath"
    return run(["nix", "eval", "--impure", "--raw", attr_path])


def build_artifact(home_manager_flake: str, cache_dir: Path, kind: str) -> Path:
    attr_by_kind = {
        "json": "docs-json",
        "html": "docs-html",
        "manpages": "docs-manpages",
    }
    if kind not in attr_by_kind:
        raise ValueError(f"unknown kind: {kind}")
    cache_dir.mkdir(parents=True, exist_ok=True)
    link = cache_dir / kind
    run(["nix", "build", f"{home_manager_flake}#{attr_by_kind[kind]}", "--out-link", str(link)])
    return link


def built_docs_paths(home_manager_flake: str, cache_dir: Path, kinds: list[str]) -> dict[str, Path]:
    roots = {kind: build_artifact(home_manager_flake, cache_dir, kind) for kind in kinds}
    paths = {}
    if "manpages" in roots:
        paths["manpage"] = roots["manpages"] / "share/man/man5/home-configuration.nix.5"
    if "html" in roots:
        paths["html_index"] = roots["html"] / "share/doc/home-manager/index.xhtml"
        paths["html_options"] = roots["html"] / "share/doc/home-manager/options.xhtml"
    if "json" in roots:
        paths["json_options"] = roots["json"] / "share/doc/home-manager/options.json"
    return paths


def docs_paths(cache_dir: Path) -> dict[str, Path]:
    return {
        "manpage": cache_dir / "manpages/share/man/man5/home-configuration.nix.5",
        "html_index": cache_dir / "html/share/doc/home-manager/index.xhtml",
        "html_options": cache_dir / "html/share/doc/home-manager/options.xhtml",
        "json_options": cache_dir / "json/share/doc/home-manager/options.json",
    }


def load_options(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        print(f"options.json not found: {path}", file=sys.stderr)
        sys.exit(2)


def literal_field(value) -> str:
    if value is None:
        return ""
    if isinstance(value, dict):
        text = value.get("text")
        if isinstance(text, str):
            return text.strip()
    if isinstance(value, str):
        return value.strip()
    return json.dumps(value, ensure_ascii=False)


def print_paths(paths: dict[str, Path]) -> None:
    for key, value in paths.items():
        print(f"{key}: {value}")


def resolve_declaration_path(text: str, home_manager_flake: str) -> str | None:
    prefix = "<home-manager/"
    suffix = ">"
    if not text.startswith(prefix) or not text.endswith(suffix):
        return None
    relative = text[len(prefix) : -len(suffix)]
    return str(Path(home_manager_flake) / relative)


def print_option(name: str, data: dict, home_manager_flake: str) -> None:
    print(name)
    print(f"type: {data.get('type', '')}")
    print(f"readOnly: {data.get('readOnly', False)}")
    default = literal_field(data.get("default"))
    if default:
        print(f"default: {default}")
    example = literal_field(data.get("example"))
    if example:
        print("example:")
        print(example)
    declarations = data.get("declarations") or []
    if declarations:
        print("declaredBy:")
        for decl in declarations:
            text = decl.get("name", "")
            url = decl.get("url", "")
            resolved = resolve_declaration_path(text, home_manager_flake)
            if resolved:
                print(f"- {resolved}")
                if url:
                    print(f"  upstream: {url}")
            elif url:
                print(f"- {text} {url}")
            else:
                print(f"- {text}")
    description = (data.get("description") or "").strip()
    if description:
        print("description:")
        print(description)


def cmd_show(options: dict, key: str, home_manager_flake: str) -> int:
    data = options.get(key)
    if data is not None:
        print_option(key, data, home_manager_flake)
        return 0

    lowered = key.lower()
    matches = [name for name in options if lowered in name.lower()]
    if not matches:
        print(f"no option matched: {key}", file=sys.stderr)
        return 1

    print(f"no exact match for: {key}", file=sys.stderr)
    print("candidates:", file=sys.stderr)
    for name in matches[:20]:
        print(f"- {name}", file=sys.stderr)
    return 1


def cmd_show_many(options: dict, keys: list[str], home_manager_flake: str) -> int:
    status = 0
    for index, key in enumerate(keys):
        if index:
            print()
        status = max(status, cmd_show(options, key, home_manager_flake))
    return status


def cmd_search(options: dict, term: str) -> int:
    lowered = term.lower()
    matches = []
    for name, data in options.items():
        haystacks = [
            name,
            data.get("description") or "",
            data.get("type") or "",
        ]
        if any(lowered in text.lower() for text in haystacks):
            matches.append(name)

    if not matches:
        print(f"no matches for: {term}", file=sys.stderr)
        return 1

    for name in matches[:100]:
        print(name)
    if len(matches) > 100:
        print(f"... {len(matches) - 100} more", file=sys.stderr)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Query local Home Manager options docs")
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Home Manager repo root used to resolve the pinned home-manager input",
    )
    parser.add_argument(
        "--cache-dir",
        type=Path,
        default=Path("/tmp/home-manager-docs"),
        help="Directory for doc build out-links",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("paths")

    build_parser = subparsers.add_parser("build")
    build_parser.add_argument("kind", choices=[*DOC_KINDS, "all"])

    show_parser = subparsers.add_parser("show")
    show_parser.add_argument("options", nargs="+")

    search_parser = subparsers.add_parser("search")
    search_parser.add_argument("term")

    args = parser.parse_args()

    if args.command == "paths":
        print_paths(docs_paths(args.cache_dir))
        return 0


    repo_root = args.repo_root or find_repo_root(Path.cwd())
    home_manager_flake = resolve_home_manager_flake(repo_root)

    if args.command == "build":
        kinds = DOC_KINDS if args.kind == "all" else [args.kind]
        paths = built_docs_paths(home_manager_flake, args.cache_dir, kinds)
        print_paths(paths)
        return 0

    paths = built_docs_paths(home_manager_flake, args.cache_dir, ["json"])
    options = load_options(paths["json_options"])
    if args.command == "show":
        return cmd_show_many(options, args.options, home_manager_flake)
    if args.command == "search":
        return cmd_search(options, args.term)
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (CommandError, FileNotFoundError) as error:
        print(error, file=sys.stderr)
        if isinstance(error, CommandError):
            if error.stdout:
                print(error.stdout.rstrip(), file=sys.stderr)
            if error.stderr:
                print(error.stderr.rstrip(), file=sys.stderr)
            raise SystemExit(error.returncode) from None
        raise SystemExit(2) from None
