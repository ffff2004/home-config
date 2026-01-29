{
  lib,
  stdenvNoCC,
  fetchurl,
  umu-launcher-wrapper,
  maaPath,
  android-tools,
  zenity,
  writeShellScript,
  imagemagick,
  makeDesktopItem,
  copyDesktopItems,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "maa";

  dontUnpack = true;

  icon512 = fetchurl {
    url = "https://docs.maa.plus/images/maa-logo_512x512.png";
    hash = "sha256-29AUkVyjpN+5Hh9izH5rqTdYSmgEoJyx5DsEieg13SY=";
  };

  desktopItems = [
    (makeDesktopItem {
      name = "MAA";
      exec = finalAttrs.script;
      icon = "maa";
      comment = finalAttrs.meta.description;
      desktopName = "MAA";
      categories = [ "Game" ];
    })
  ];

  nativeBuildInputs = [
    copyDesktopItems
  ];

  script = writeShellScript "maa" ''
    set -euo pipefail
    export PATH="${
      builtins.concatStringsSep ":" (
        map (p: "${p}/bin") [
          android-tools
          zenity
        ]
      )
    }:$PATH"
    maa_path="${maaPath}"
    # 如果 maa_path 未设置，则使用默认值
    if [ -z "$maa_path" ]; then
        maa_path="$HOME/Games/maa"
    fi
    maa_bin="$maa_path/MAA.exe"
    config_file="$maa_path/config/gui.json"

    echo "maa_path=$maa_path"
    echo "maa_bin=$maa_bin"
    echo "config_file=$config_file"

    maa_cmd="env GAMEID=maa ${lib.getExe umu-launcher-wrapper} $maa_bin"
    echo "maa_cmd=$maa_cmd"
    ${builtins.readFile ./maa.sh}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${finalAttrs.script} $out/bin/maa

    mkdir -p $out/share/icons/hicolor/512x512/apps/
    ln -s ${finalAttrs.icon512} $out/share/icons/hicolor/512x512/apps/maa.png
    for size in 16 32 48 64 128 256; do
      res="$size"x"$size"
      mkdir -p $out/share/icons/hicolor/"$res"/apps/
      ${lib.getExe imagemagick} \
          $out/share/icons/hicolor/512x512/apps/maa.png \
          -resize "$res" \
          $out/share/icons/hicolor/"$res"/apps/maa.png
    done

    runHook postInstall
  '';

  meta = {
    mainProgram = "maa";
    description = "MAA Assistant Arknights 一款明日方舟游戏小助手";
  };
})
