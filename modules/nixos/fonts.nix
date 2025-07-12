{ pkgs, ... }: {
  fonts.packages = with pkgs; [
    roboto
    inter
  ];
}
