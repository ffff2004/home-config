{
  programs = {
    bash = {
      enable = true;
      package = null;
      enableCompletion = true;
    };
    fish = {
      generateCompletions = false;
      enable = true;
    };
  };
  home.shellAliases = {
    "soft-reboot" = "systemctl soft-reboot";
    "waydsestop" = "waydroid session stop";
    "waydsestart" = "waydroid session start";
    "waydalaunch" = "waydroid app launch";
    "waydstatus" = "waydroid status";
    "hm" = "home-manager";
  };
}
