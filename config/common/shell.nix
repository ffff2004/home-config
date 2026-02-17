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
    "wdsestop" = "waydroid session stop";
    "wdsestart" = "waydroid session start";
    "wdalaunch" = "waydroid app launch";
    "wdstatus" = "waydroid status";
  };
}
