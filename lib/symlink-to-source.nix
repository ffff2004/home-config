{
  pkgs,
  lib,
  hmLib,
  sourceRoot,
  ...
}:
let
  inherit (import ./ls.nix { lib = lib; }) lsFileRecursively;
in
rec {
  toSourcePath =
    path:
    builtins.replaceStrings [ (toString sourceRoot.inStore) ] [ (toString sourceRoot.source) ] (
      toString path
    );

  mkSymlinkToSource =
    let
      mkOutOfStoreSymlink =
        path:
        let
          pathStr = toString path;
          name = hmLib.strings.storeFileName (baseNameOf pathStr);
        in
        pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg pathStr} $out";
    in
    path: mkOutOfStoreSymlink (toSourcePath path);

  mkSymlinkToSourceRecursively =
    target: path:
    lib.genAttrs' (lsFileRecursively path) (
      file:
      lib.nameValuePair "${target}/${lib.removePrefix ((toString path) + "/") (toString file)}" {
        source = mkSymlinkToSource file;
      }
    );
}
