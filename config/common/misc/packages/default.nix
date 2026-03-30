{ pkgs, pkgsFrom, ... }:
{
  home.packages = (
    builtins.attrValues {
      inherit (pkgs)
        gh

        nil
        nixfmt
        nix-tree

        tree
        zip
        unzip
        unrar

        htop
        btop

        lesspass-cli

        android-tools
        ;

      # inherit (pkgsFrom.fym998-nur) bitsrun-rs;
    }
  );
}
