{ localLib, ... }:
{
  home.file = localLib.mkSymlinkToSourceRecursively ".dsh" ./config;
}
