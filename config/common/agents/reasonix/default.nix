{ localLib, ... }:
{
  home.file = localLib.mkSymlinkToSourceRecursively ".reasonix" ./config;
}
