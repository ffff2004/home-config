{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        duration = "1h";
        mode = "fit-border-color";
        sorting = "random";
        recursive = false;
        "queue-size" = 100;
        "transition-time" = 1000;
      };

      any = {
        path = "/home/fym/Pictures/Wallpapers";
        group = 1;
      };
    };
  };
}
