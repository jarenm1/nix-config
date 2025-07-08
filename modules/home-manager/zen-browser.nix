{ pkgs, inputs, ... }:

{
  imports = [
    inputs.zen-browser
  ];

  programs.zen-browser = {
    enable = true;
    # other zen config below
  }
}
