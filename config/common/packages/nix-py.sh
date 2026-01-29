#!/bin/sh

# nix-py: Run Python with Nix-provided packages
# Usage: nix-py [-p PYTHON_PKG] [DEPS...] [-- ARGS...]

set -eu

python_pkg="python3"
deps=""
extra_args=""

# Parse options
while [ $# -gt 0 ]; do
    case $1 in
        -p)
            if [ $# -lt 2 ]; then
                echo "error: -p requires an argument" >&2
                exit 1
            fi
            python_pkg="$2"
            shift 2
            ;;
        --)
            shift
            extra_args="$*"
            set --  # clear positional args
            ;;
        -*)
            echo "error: unknown option '$1'" >&2
            exit 1
            ;;
        *)
            # Accumulate dependencies
            if [ -z "$deps" ]; then
                deps="$1"
            else
                deps="$deps $1"
            fi
            shift
            ;;
    esac
done

# Build the Nix expression
if [ -z "$deps" ]; then
    nix_expr="(import <nixpkgs> {}).$python_pkg"
else
    # Convert space-separated deps to Nix list: foo bar -> [ foo bar ]
    nix_expr="(import <nixpkgs> {}).$python_pkg.withPackages (pyPkgs: with pyPkgs; [ $deps ])"
fi

# Construct command
cmd="nix run --impure --expr '$nix_expr'"
if [ -n "$extra_args" ]; then
    cmd="$cmd -- $extra_args"
fi

# Execute
exec sh -c "$cmd"