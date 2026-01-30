{
  programs.niri.settings = {
    environment = {
      "LANG" = "zh_CN.UTF-8";
      "LANGUAGE" = "zh_CN:en_GB";
      # Set a variable like this:
      "QT_QPA_PLATFORM" = "wayland";

      "ELECTRON_OZONE_PLATFORM_HINT" = "auto";

      # # GTK_IM_MODULE "fcitx"
      # "QT_IM_MODULE" = "fcitx";
      # # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland#Sway
      # "XMODIFIERS" = "@im=fcitx";
      # "QT_IM_MODULES" = "wayland;fcitx";
      # "GTK_IM_MODULE" = null;
      # "SDL_IM_MODULE" = null;
      # "GLFW_IM_MODULE" = null;
    };
  };
}
