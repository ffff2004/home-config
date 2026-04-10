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
        unar
        trash-cli

        htop
        btop

        lesspass-cli

        android-tools

        jq
        ;

      inherit (pkgsFrom.fym998-nur) bitsrun-rs;
    }
  );
}
