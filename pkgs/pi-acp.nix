{ lib
, buildNpmPackage
, fetchFromGitHub
, makeWrapper
, pi-coding-agent
}:

buildNpmPackage rec {
  pname = "pi-acp";
  version = "0.0.25";

  src = fetchFromGitHub {
    owner = "svkozak";
    repo = "pi-acp";
    rev = "v${version}";
    hash = "sha256-MdEXjHvn8eCy2mPstgTwXUZh99whr8hCA4CTFis1h3g=";
  };

  postPatch = ''
    cp ${./pi-acp-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-GuHvjqSD4M87cGBtFFSF37FWF79+6pLlai0A99Ii/hM=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/pi-acp \
      --prefix PATH : ${lib.makeBinPath [ pi-coding-agent ]}
  '';

  meta = with lib; {
    description = "ACP adapter for pi coding agent";
    homepage = "https://github.com/svkozak/pi-acp";
    license = licenses.mit;
    mainProgram = "pi-acp";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
