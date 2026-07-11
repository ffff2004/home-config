{ pkgs, localLib, ... }:
{
  home = {
    packages = [ pkgs.rustup ];
    file.".cargo/config.toml".source = localLib.mkSymlinkToSource ./cargo-config.toml;
    sessionVariables = {
      RUSTUP_UPDATE_ROOT = "https://mirrors.cernet.edu.cn/rustup/rustup";
      RUSTUP_DIST_SERVER = "https://mirrors.cernet.edu.cn/rustup";
    };
  };
}
