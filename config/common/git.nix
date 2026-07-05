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
        cl = "clone --filter=blob:none";
        clrs = "clone --filter=blob:none --recurse-submodules --also-filter-submodules";
      };
      # https://forums.whonix.org/t/git-users-enable-fsck-by-default-for-better-security/2066
      transfer.fsckobjects = true;
      fetch.fsckobjects = true;
      receive.fsckobjects = true;
    };
    # Signing config is machine-local so this flake can be deployed on
    # machines with different signing keys or no signing key.
    includes = [
      { path = "~/.config/git/signing.gitconfig"; }
    ];
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit.enable = true;
}
