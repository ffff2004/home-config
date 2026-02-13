{
  writeShellScriptBin,
  umu-launcher,
  lib,
  protonPath,
  exe ? "umu-run",
  extraEnv ? { },
}:
let
  envToSet = lib.filterAttrs (k: v: v != null) extraEnv;
  envToUnset = lib.filterAttrs (k: v: v == null) extraEnv;
in
writeShellScriptBin exe ''
  if [ -z "$PROTONPATH" ]; then
      export PROTONPATH="${protonPath}"
  fi
  ${lib.concatMapStrings (nv: "export ${nv.name}=\"${toString nv.value}\"\n") (
    lib.attrsToList envToSet
  )}
  ${lib.concatMapStrings (nv: "unset ${nv.name}\n") (lib.attrsToList envToUnset)}
  exec ${lib.getExe umu-launcher} "$@"
''
