{ lib
, appimageTools
, fetchurl
}:

let
  pname = "t4-code";
  version = "0.1.17";

  src = fetchurl {
    url = "https://github.com/LycaonLLC/t4-code/releases/download/v${version}/T4-Code-${version}-linux-x86_64.AppImage";
    hash = "sha256-96nosLRHtt8n1ah96ZCJRFdUjUAQ68r1kH0NY2XbKzk=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/t4-code.desktop \
      $out/share/applications/t4-code.desktop
    install -m 444 -D ${appimageContents}/t4-code.png \
      $out/share/icons/hicolor/512x512/apps/t4-code.png
    substituteInPlace $out/share/applications/t4-code.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=t4-code'
  '';

  meta = {
    description = "Open-source desktop client for Oh My Pi";
    homepage = "https://t4code.net";
    downloadPage = "https://github.com/LycaonLLC/t4-code/releases";
    license = lib.licenses.mit;
    mainProgram = "t4-code";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
