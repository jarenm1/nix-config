{ lib
, stdenvNoCC
, fetchurl
, buildFHSEnv
, fd
, ripgrep
}:

let
  version = "16.5.2-appserver-4";

  src = fetchurl {
    url = "https://github.com/lyc-aon/oh-my-pi/releases/download/t4code-${version}/omp-linux-x64";
    hash = "sha256-+aMyizKi9JxKZ0lAYUPhP8b4+YwJSGWxGdXGMIDr01E=";
  };

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "oh-my-pi-unwrapped";
    inherit version src;
    dontUnpack = true;
    installPhase = ''
      install -m 755 -D $src $out/bin/omp
    '';
  };
in
buildFHSEnv {
  name = "omp";
  runScript = "${unwrapped}/bin/omp";
  targetPkgs = _: [ fd ripgrep ];

  meta = {
    description = "Opinionated Pi coding agent with T4 Code appserver support";
    homepage = "https://omp.sh";
    downloadPage = "https://github.com/lyc-aon/oh-my-pi/releases/tag/t4code-${version}";
    changelog = "https://github.com/lyc-aon/oh-my-pi/releases/tag/t4code-${version}";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
