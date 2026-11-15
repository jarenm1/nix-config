{ pkgs, ... }:
let
  # Unreal's Linux binaries are dynamically linked against FHS paths and dlopen
  # Vulkan, X11/Wayland, and audio libraries at runtime. Run them in an FHS
  # sandbox instead of patching binaries or enabling nix-ld system-wide.
  # Usage: `unreal-engine`, then run ~/UnrealEngine/Engine/Binaries/Linux/UnrealEditor
  unreal-engine = pkgs.buildFHSEnv {
    name = "unreal-engine";
    targetPkgs = pkgs: with pkgs; [
      # Source builds (SetupToolchain.sh, GenerateProjectFiles.sh) and project tooling
      git
      git-lfs
      python3
      cmake

      # Vulkan RHI (default on Linux)
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers

      # Windowing and GL
      libGL
      libxkbcommon
      wayland
      libX11
      libXext
      libXi
      libXinerama
      libXrandr
      libXcursor
      libXScrnSaver
      libXtst
      libxcb

      # Audio
      alsa-lib
      libpulseaudio
      pipewire

      # Fonts, text, and system libraries
      fontconfig
      freetype
      icu
      openssl
      zlib
      dbus
      glib
      systemdLibs
      libunwind
      libuuid
      libcap
    ];
    runScript = "bash";
  };
in
{
  environment.systemPackages = [ unreal-engine ];
}
