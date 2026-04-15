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
        Name = "fym998";
        email = "61316972+fym998@users.noreply.github.com";
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
      signByDefault = true;
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
