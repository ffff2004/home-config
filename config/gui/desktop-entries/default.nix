{ lib, localLib, ... }:
{
  xdg.dataFile = lib.genAttrs' (localLib.lsFileRecursively ./files) (
    file:
    lib.nameValuePair "applications/${lib.removePrefix ((toString ./files) + "/") (toString file)}" {
      source = localLib.mkSymlinkToSource file;
    }
  );
}
