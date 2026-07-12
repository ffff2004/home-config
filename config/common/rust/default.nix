{
  config,
  pkgs,
  localLib,
  ...
}:
let
  cargoHome = "${config.home.homeDirectory}/.cargo";
in
{
  home = {
    packages = [ pkgs.rustup ];
    file."${cargoHome}/config.toml".source = localLib.mkSymlinkToSource ./cargo-config.toml;
    sessionVariables = {
      CARGO_HOME = cargoHome;
      RUSTUP_UPDATE_ROOT = "https://mirrors.cernet.edu.cn/rustup/rustup";
      RUSTUP_DIST_SERVER = "https://mirrors.cernet.edu.cn/rustup";
    };
    sessionSearchVariables.PATH = [ "${cargoHome}/bin" ];
  };
}
