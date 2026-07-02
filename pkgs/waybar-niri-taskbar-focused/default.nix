{
  lib,
  rustPlatform,
  fetchFromGitHub,
  gtk3,
  pkg-config,
  stdenv,
}:

rustPlatform.buildRustPackage {
  pname = "waybar-niri-taskbar-focused";
  version = "0.4.0+niri.26.4-focused";

  src = fetchFromGitHub {
    owner = "jR4dh3y";
    repo = "niri-taskbar";
    rev = "3d9ea9c09a3b27f67477f608fdc46a7120d9c62e";
    hash = "sha256-9e4CVOxU+xzAR8sB3DVKU9N82ZT0548S74CM15TfREE=";
  };

  cargoHash = "sha256-58lmbDJJWezpAiduWyqAzzLto5x/ESZpDycqh/XrTLM=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    gtk3
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/libniri_taskbar.so \
      $out/lib/waybar/libniri_taskbar.so

    runHook postInstall
  '';

  meta = {
    description = "Focused-workspace Niri taskbar module for Waybar";
    homepage = "https://github.com/jR4dh3y/niri-taskbar";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
