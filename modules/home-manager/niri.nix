# Home Manager Niri Configuration
# Focused on scroll and gesture support
{ pkgs, lib, ... }: {
  programs.niri.config = ''
    spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "/home/jaren/Downloads/background.jpg" "-m" "fill"

    xwayland-satellite {
      path "${lib.getExe pkgs.xwayland-satellite-stable}"
    }

    input {
      touchpad {
        tap
        natural-scroll
        scroll-factor 0.1
      }
    }
    
    layout {
      gaps 8
      center-focused-column "never"
      always-center-single-column
      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }
      
      focus-ring {
        width 2
        active-color "#444444"
        inactive-color "#444444"
      }
    }

    window-rule {
      geometry-corner-radius 8
      clip-to-geometry true
    }
    
    binds {
      // Spawn programs
      Mod+Q { spawn "ghostty"; }
      Mod+R { spawn "wofi" "--show" "drun"; }
      
      // Window management
      Mod+C repeat=false { close-window; }
      Mod+V { toggle-window-floating; }
      
      // Focus movement
      Mod+Left { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up { focus-window-up; }
      Mod+Down { focus-window-down; }
      
      // Window movement
      Mod+Shift+Left { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up { move-window-up; }
      Mod+Shift+Down { move-window-down; }
      
      // Workspace navigation
      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }
      
      // Move to workspace
      Mod+Shift+1 { move-column-to-workspace 1; }
      Mod+Shift+2 { move-column-to-workspace 2; }
      Mod+Shift+3 { move-column-to-workspace 3; }
      Mod+Shift+4 { move-column-to-workspace 4; }
      Mod+Shift+5 { move-column-to-workspace 5; }
      Mod+Shift+6 { move-column-to-workspace 6; }
      Mod+Shift+7 { move-column-to-workspace 7; }
      Mod+Shift+8 { move-column-to-workspace 8; }
      Mod+Shift+9 { move-column-to-workspace 9; }
      
      // Overview
      Mod+Tab { toggle-overview; }
      Mod+O { toggle-overview; }
      
      // Scroll bindings for workspace/column navigation
      Mod+TouchpadScrollUp { focus-workspace-up; }
      Mod+TouchpadScrollDown { focus-workspace-down; }
      Mod+TouchpadScrollLeft { focus-column-left; }
      Mod+TouchpadScrollRight { focus-column-right; }
      
      Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollLeft { focus-column-left; }
      Mod+WheelScrollRight { focus-column-right; }
      
      Mod+Shift+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
      Mod+Shift+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
      
      // Layout controls
      Mod+Comma { consume-window-into-column; }
      Mod+Period { expel-window-from-column; }
      Mod+Slash { switch-preset-column-width; }
      Mod+Shift+Slash { switch-preset-window-height; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
      
      // Exit
      Mod+M { quit; }
    }
  '';
}
