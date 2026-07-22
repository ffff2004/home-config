{
  pkgs,
  lib,
  hmLib,
  sourceRoot,
  ...
}:
let
  inherit (import ./ls.nix { lib = lib; }) lsFileRecursively;
  isWithin =
    root: path:
    let
      rootStr = toString root;
      pathStr = toString path;
    in
    pathStr == rootStr || lib.hasPrefix "${rootStr}/" pathStr;

  # Return true for existing files and directories, including symlinks whose
  # targets exist. Return false for missing paths, and fail evaluation for a
  # dangling symlink while probing its missing target.
  #
  # `builtins.pathExists` alone is insufficient because it checks the symlink
  # entry itself and therefore returns true for dangling symlinks. Follow
  # symlinks explicitly: `pathIsDirectory` covers directory targets, while
  # `hashFile` covers file targets without loading their contents into a Nix
  # string (and consequently detects a missing target).
  sourceExists =
    path:
    builtins.pathExists path
    && (
      builtins.readFileType path != "symlink"
      || lib.pathIsDirectory path
      || builtins.hashFile "sha256" path != ""
    );
in
rec {
  toSourcePath =
    path:
    if isWithin sourceRoot.inStore path then
      (toString sourceRoot.source) + lib.removePrefix (toString sourceRoot.inStore) (toString path)
    else
      toString path;

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
    path:
    if !sourceExists path then
      throw "mkSymlinkToSource: path does not exist or is a dangling symlink: ${toString path}"
    else if isWithin sourceRoot.source (toSourcePath path) then
      mkOutOfStoreSymlink (toSourcePath path)
    else
      path;

  mkSymlinkToSourceRecursively =
    target: path:
    lib.genAttrs' (lsFileRecursively path) (
      file:
      lib.nameValuePair "${target}/${lib.removePrefix ((toString path) + "/") (toString file)}" {
        source = mkSymlinkToSource file;
      }
    );
}
