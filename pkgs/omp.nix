# omp for jaren (home-manager) and the `agent` account: one derivation, so both run the same build.
{ inputs, pkgs }:
(inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
  withWaylandScreencast = true;
}).overrideAttrs
  (old: {
    # Unmerged upstream fixes; drop each once its PR lands.
    patches = (old.patches or [ ]) ++ [
      ./patches/omp/16512-chunk-dir-naming.patch # duplicate chunk path after the pi-tui rewrite
      ./patches/omp/20371-agy-file-token-storage.patch # antigravity-cli /login on agy 1.5.16
    ];
  })
