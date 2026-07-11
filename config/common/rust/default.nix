{ pkgs, localLib, ... }:
{
  home = {
    packages = [ pkgs.rustup ];
    file.".cargo/config.toml".source = localLib.mkSymlinkToSource ./cargo-config.toml;
  };
}
