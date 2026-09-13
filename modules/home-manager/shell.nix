{ config, lib, pkgs, ... }:
{
  programs.nushell = {
    enable = true;
    package = null;
    settings.show_banner = false;
    extraConfig = lib.mkOrder 2000 ''
      source ${
        pkgs.runCommand "atuin-nushell-config.nu"
          { nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ]; }
          ''
            ${lib.getExe config.programs.atuin.package} init nu ${lib.escapeShellArgs config.programs.atuin.flags} > "$out"
          ''
      }
    '';
  };

  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableNushellIntegration = false;
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = "$directory$git_branch$nix_shell$character";
      right_format = "$battery$time";
      line_break.disabled = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = false;
      };
      battery = {
        disabled = false;
        format = "[$symbol$percentage]($style) ";
        display = [
          {
            threshold = 100;
            style = "dimmed white";
          }
        ];
      };
      git_branch.symbol = " ";
      nix_shell.symbol = " ";
      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%m/%d %R";
        style = "dimmed white";
      };
    };
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
  };
}
