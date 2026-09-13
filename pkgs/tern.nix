{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, copyDesktopItems
, makeDesktopItem
, makeWrapper
, python3
, glib
, bashInteractive
, nushell
, coreutils
, wayland
, libxkbcommon
, libGL
, libglvnd
, vulkan-loader
, libx11
, libxcursor
, libxi
, libxrandr
, libxcb
, pipewire
, linux-pam
, webkitgtk_4_1
, fontconfig
, freetype
}:

let
  pname = "tern";
  version = "0.5.3";

  libPath = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    wayland
    libxkbcommon
    libGL
    libglvnd
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    pipewire
    linux-pam
    webkitgtk_4_1
    fontconfig
    freetype
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://build.stencil.so/d/tern/20261006-203431-b7f1010/Tern-${version}-linux-x86_64.tar.gz";
    hash = "sha256-ROZMeGXsA/OQU6mhwNsUSXjhFiiH4v99WJQiDxD2mSw=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
    python3
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    wayland
    libxkbcommon
    libGL
    libglvnd
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    pipewire
    linux-pam
    webkitgtk_4_1
    fontconfig
    freetype
  ];

  appendRunpaths = [
    libPath
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "tern";
      desktopName = "Tern";
      comment = "A multiplexing terminal";
      exec = "tern %F";
      icon = "tern";
      terminal = false;
      categories = [ "System" "TerminalEmulator" ];
      startupWMClass = "tern";
      keywords = [ "terminal" "multiplexer" "shell" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 tern/tern $out/bin/tern

    python3 -c "
import struct, os, re
with open('tern/tern', 'rb') as f:
    data = f.read()
for start in [m.start() for m in re.finditer(b'\x89PNG\r\n\x1a\n', data)]:
    iend = data.find(b'IEND', start)
    if iend != -1:
        chunk = data[start:iend+8]
        if len(chunk) > 24 and chunk[12:16] == b'IHDR':
            w, h = struct.unpack('>II', chunk[16:24])
            if w == h and w in [16, 32, 48, 64, 128, 256, 512, 1024]:
                d = f'$out/share/icons/hicolor/{w}x{w}/apps'
                os.makedirs(d, exist_ok=True)
                with open(f'{d}/tern.png', 'wb') as out:
                    out.write(chunk)
"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/tern \
      --prefix PATH : ${lib.makeBinPath [ glib bashInteractive nushell coreutils ]} \
      --suffix PATH : "/etc/profiles/per-user/current/bin:/run/current-system/sw/bin:/run/wrappers/bin"
  '';
  meta = {
    description = "A multiplexing terminal";
    homepage = "https://stencil.so/tern";
    mainProgram = "tern";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
