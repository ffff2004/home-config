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
    "hms" = "home-manager switch -b hmbak";
    "hmso" = "home-manager switch -b hmbak --option substitute false";
    "hmb" = "home-manager build";
    "hmbo" = "home-manager build --option substitute false";
    "soft-reboot" = "systemctl soft-reboot";
    "waydsestop" = "waydroid session stop";
    "waydsestart" = "waydroid session start";
    "waydalaunch" = "waydroid app launch";
    "waydstatus" = "waydroid status";
  };
}
