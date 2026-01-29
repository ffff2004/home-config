{
  lib,
  stdenvNoCC,
  fetchurl,
  umu-launcher-wrapper,
  writeShellScript,
  imagemagick,
  makeDesktopItem,
  copyDesktopItems,
  endfieldBin,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "endfield";

  dontUnpack = true;

  icon500 = fetchurl {
    url = "https://bbs.hycdn.cn/asset/endfield.png";
    hash = "sha256-6lRgKGADro9Qq8U/mcp4xoIZiQiWsb9uBYwHRihoZZY=";
  };

  desktopItems = [
    (makeDesktopItem {
      name = "Endfield";
      exec = finalAttrs.script;
      icon = "endfield";
      comment = finalAttrs.meta.description;
      desktopName = "Endfield";
      categories = [ "Game" ];
    })
  ];

  nativeBuildInputs = [
    copyDesktopItems
  ];

  script = writeShellScript "endfield" ''
    set -euo pipefail
    exec env GAMEID=yj ${lib.getExe umu-launcher-wrapper} "${endfieldBin}"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${finalAttrs.script} $out/bin/endfield

    for size in 16 32 48 64 128 256 512; do
      res="$size"x"$size"
      mkdir -p $out/share/icons/hicolor/"$res"/apps/
      ${lib.getExe imagemagick} \
          ${finalAttrs.icon500} \
          -resize "$res" \
          $out/share/icons/hicolor/"$res"/apps/endfield.png
    done

    runHook postInstall
  '';

  meta = {
    mainProgram = "endfield";
    description = "明日方舟：终末地";
  };
})
