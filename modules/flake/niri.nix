# Niri Flake Parts Module
# Provides overlay and shared configuration for niri
{ inputs, ... }:
{
  flake = {
    # Expose the niri overlay for use in nixpkgs
    overlays.niri = inputs.niri.overlays.niri;
  };
}
