{ lib, pkgs, ... }:
{
  lib.umu.buildProtonApp =
    {
      bin,
      umu-launcher-wrapper,
      name,
      desktopName ? name,
      description,
      icon,
      iconSize,
      gameId ? name,
      preCmd ? "",
      postCmd ? "",
      wrapperCmd ? "",
    }:
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit name;
      dontUnpack = true;

      inherit icon;

      meta = {
        inherit description;
        mainProgram = finalAttrs.name;
      };

      desktopItems = [
        (pkgs.makeDesktopItem {
          name = desktopName;
          exec = finalAttrs.name;
          icon = finalAttrs.name;
          comment = finalAttrs.meta.description;
          desktopName = desktopName;
          categories = [ "Game" ];
        })
      ];

      nativeBuildInputs = [
        pkgs.copyDesktopItems
        pkgs.imagemagick
      ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/bin

        cat > "$out/bin/${name}" <<'EOF99999999999'
        #!${pkgs.stdenvNoCC.shell}
        ${preCmd}
        ${wrapperCmd} env GAMEID=${gameId} "${lib.getExe umu-launcher-wrapper}" "${bin}"
        ${postCmd}
        EOF99999999999

        chmod +x $out/bin/${name}


        # 生成各尺寸图标
        readonly icon_path=$(readlink -f "${icon}")
        readonly icon_size=${toString iconSize}
        readonly icon_name=${name}

        readonly TARGET_SIZES=(16 32 48 64 128 256 512)
        for target in "''${TARGET_SIZES[@]}"; do
          if [[ "''${target}" -le "''${icon_size}" ]]; then
            dest_dir="$out/share/icons/hicolor/''${target}x''${target}/apps"
            dest_path="''${dest_dir}/''${icon_name}.png"

            mkdir -p "''${dest_dir}"

            magick "''${icon_path}" \
              -resize "''${target}x''${target}^" \
              "''${dest_path}"
          fi
        done

        runHook postInstall
      '';
    });
}
