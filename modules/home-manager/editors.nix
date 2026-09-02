{ lib, pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn";
      editor = {
        line-number = "relative";
        cursor-shape.insert = "bar";
        soft-wrap.enable = true;
      };
    };
  };
}
