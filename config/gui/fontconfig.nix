{ pkgs, ... }:
{
  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "none";
    subpixelRendering = "rgb";
    defaultFonts = {
      serif = [ "Noto Serif CJK SC" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      monospace = [ "Maple Mono NF CN" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  home.packages = with pkgs; [
    # noto-fonts-cjk-sans
    # noto-fonts-cjk-serif
    # maple-mono.NF-CN
    # noto-fonts-color-emoji
  ];
}
