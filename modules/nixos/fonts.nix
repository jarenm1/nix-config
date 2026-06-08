{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    roboto
    roboto-serif
    inter
  ];
}
