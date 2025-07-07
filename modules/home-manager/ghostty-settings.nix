{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    theme = mkOption {
      type = types.str;
      default = "gruber-darker";
      description = "The color theme to use.";
    };

    font-size = mkOption {
      type = types.int;
      default = 15;
      description = "The font size.";
    };

    font-family = mkOption {
      type = types.str;
      default = "JetBrains Mono Nerd Font";
      description = "The font family to use.";
    };
  };
}
