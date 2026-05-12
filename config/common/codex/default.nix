{ localLib, lib, ... }:
{
  home.file = lib.genAttrs' (localLib.lsFileRecursively ./config) (
    file:
    lib.nameValuePair ".codex/${lib.removePrefix ((toString ./config) + "/") (toString file)}" {
      source = localLib.mkSymlinkToSource file;
    }
  );
}
