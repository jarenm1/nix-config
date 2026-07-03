{ lib
, buildNpmPackage
, fetchurl
, makeWrapper
, bun
, fd
, ripgrep
, versionCheckHook
, writableTmpDirAsHomeHook
}:

buildNpmPackage rec {
  pname = "oh-my-pi";
  version = "16.1.23";

  src = fetchurl {
    url = "https://registry.npmjs.org/@oh-my-pi/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-AkS8QRFzyh/4+2gMP+rN23pLYN9upuuSpzjbgHcj0ek=";
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./oh-my-pi-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-L1ed2P2RMLRSRl6KyPspaQM+KV8jbs9Tr84dCtaSDxM=";
  dontNpmBuild = true;
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    local packageOut="$out/lib/node_modules/@oh-my-pi/pi-coding-agent"
    mkdir -p "$packageOut" "$out/bin"
    cp -R . "$packageOut"

    makeWrapper ${lib.getExe bun} "$out/bin/omp" \
      --add-flags "$packageOut/dist/cli.js" \
      --prefix PATH : ${lib.makeBinPath [ fd ripgrep ]}

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgram = "${placeholder "out"}/bin/omp";
  versionCheckProgramArg = "--version";

  meta = {
    description = "Opinionated Pi coding agent configuration";
    homepage = "https://omp.sh";
    downloadPage = "https://www.npmjs.com/package/@oh-my-pi/pi-coding-agent";
    changelog = "https://github.com/can1357/oh-my-pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
