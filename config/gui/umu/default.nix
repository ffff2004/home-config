{ pkgsFrom, ... }:
{
  # Application and Proton preset data are read by umuctl at runtime, not by Nix.
  home.packages = [ pkgsFrom.self.umuctl ];
}
