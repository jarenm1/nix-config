{ lib, python3Packages }:

let
  py = python3Packages;

  # Not in nixpkgs; pure-Python wheels.
  jupyter-mimetypes = py.buildPythonPackage rec {
    pname = "jupyter_mimetypes";
    version = "0.2.0";
    format = "wheel";
    src = py.fetchPypi {
      inherit pname version format;
      dist = "py3";
      python = "py3";
      hash = "sha256-5tzZiSWOP8lENltlbZFzGRUX4OOTvYeOl85QDls4hSc=";
    };
    dependencies = with py; [ pyarrow typing-extensions ];
    pythonImportsCheck = [ "jupyter_mimetypes" ];
  };

  jupyter-kernel-client = py.buildPythonPackage rec {
    pname = "jupyter_kernel_client";
    version = "0.9.0";
    format = "wheel";
    src = py.fetchPypi {
      inherit pname version format;
      dist = "py3";
      python = "py3";
      hash = "sha256-d6y48vc42XYl1r0B7ozyHE1ZeQt7pGQQhxLbOHBBbyA=";
    };
    dependencies = with py; [
      jupyter-client
      jupyter-core
      jupyter-mimetypes
      requests
      traitlets
      typing-extensions
      websocket-client
    ];
    pythonImportsCheck = [ "jupyter_kernel_client" ];
  };
in
py.buildPythonApplication rec {
  pname = "google_colab_cli";
  version = "0.8.0";
  format = "wheel";
  src = py.fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-XmI9CzTm76hOqBVx0M7GAJngauvn6jRexi9T6BDaLsE=";
  };

  dependencies = with py; [
    click
    filelock
    google-auth
    google-auth-oauthlib
    html2text
    jupyter-kernel-client
    keyring
    nbformat
    packaging
    prompt-toolkit
    pydantic
    pygments
    requests
    rich
    typer
    typing-extensions
    websocket-client
  ];

  pythonImportsCheck = [ "colab_cli" ];

  meta = {
    description = "CLI for Google Colab runtimes";
    homepage = "https://github.com/googlecolab/google-colab-cli";
    license = lib.licenses.asl20;
    mainProgram = "colab";
  };
}
