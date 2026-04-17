{
  pkgs,
  inputs,
  localLib,
  ...
}:
{
  xdg.configFile = {
    "tmux/tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";
    "tmux/tmux.conf.local".source = localLib.mkSymlinkToSource ./tmux.conf.local;
  };
  home.packages = [ pkgs.tmux ];
}
