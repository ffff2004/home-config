#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


DOC_KINDS = ["json", "html", "manpages"]


def find_repo_root(start: Path) -> Path:
    candidates = [start, *start.parents]
    for candidate in candidates:
        if (candidate / "flake.nix").exists():
            return candidate
    fallback = Path.home() / "repos" / "home-config"
    return fallback


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, check=True, text=True, capture_output=True)
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


def print_option(name: str, data: dict) -> None:
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
            if url:
                print(f"- {text} {url}")
            else:
                print(f"- {text}")
    description = (data.get("description") or "").strip()
    if description:
        print("description:")
        print(description)


def cmd_show(options: dict, key: str) -> int:
    data = options.get(key)
    if data is not None:
        print_option(key, data)
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
        default=find_repo_root(Path.cwd()),
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
    show_parser.add_argument("option")

    search_parser = subparsers.add_parser("search")
    search_parser.add_argument("term")

    args = parser.parse_args()
    home_manager_flake = resolve_home_manager_flake(args.repo_root)

    if args.command == "paths":
        paths = built_docs_paths(home_manager_flake, args.cache_dir, DOC_KINDS)
        print_paths(paths)
        return 0

    if args.command == "build":
        kinds = DOC_KINDS if args.kind == "all" else [args.kind]
        paths = built_docs_paths(home_manager_flake, args.cache_dir, kinds)
        print_paths(paths)
        return 0

    paths = built_docs_paths(home_manager_flake, args.cache_dir, ["json"])
    options = load_options(paths["json_options"])
    if args.command == "show":
        return cmd_show(options, args.option)
    if args.command == "search":
        return cmd_search(options, args.term)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
