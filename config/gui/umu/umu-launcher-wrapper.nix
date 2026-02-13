{
  writeShellScriptBin,
  umu-launcher,
  lib,
  protonPath,
  exe ? "umu-run",
  extraEnv ? { },
}:
writeShellScriptBin exe ''
  if [ -z "$PROTONPATH" ]; then
      export PROTONPATH="${protonPath}"
  fi
  ${lib.concatMapStrings (nv: "export ${nv.name}=\"${toString nv.value}\"\n") (
    lib.attrsToList extraEnv
  )}
  exec ${lib.getExe umu-launcher} "$@"
''
