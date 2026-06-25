{
  config,
  lib,
  pkgsFrom,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        Name = "ffff2004";
        email = "293283756+ffff2004@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      alias = {
        cl = "clone --filter=blob:none --recurse-submodules --also-filter-submodules";
      };
      # https://forums.whonix.org/t/git-users-enable-fsck-by-default-for-better-security/2066
      transfer.fsckobjects = true;
      fetch.fsckobjects = true;
      receive.fsckobjects = true;
    };
    signing = {
      key = "8C6ACB933C5FEAC6";
      signByDefault = true;
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit.enable = true;
}
