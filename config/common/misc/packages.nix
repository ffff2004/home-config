{ pkgs, pkgsFrom, ... }:
{
  home.packages = (
    builtins.attrValues {
      inherit (pkgs)
        gh

        nil
        nixd
        nixfmt
        nix-tree

        tree
        trash-cli
        ncdu

        zip
        unzip
        unrar
        unar
        qpdf

        htop
        btop

        lesspass-cli

        android-tools

        jq
        ;

      inherit (pkgsFrom.fym998-nur) bitsrun wallpaper-fetcher;
      inherit (pkgsFrom.self) coding-setup;
    }
  );
}
