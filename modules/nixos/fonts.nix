{ pkgs, ... }: {
  fonts.packages = with pkgs; [
    roboto
    inter
    (nerd-fonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}