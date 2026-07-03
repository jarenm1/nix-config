{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    roboto
    roboto-serif
    inter
    nerd-fonts.commit-mono
  ];
}
