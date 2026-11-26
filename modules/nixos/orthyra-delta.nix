# Orthyra Delta production on this workstation. Every scheduled capture, document watch, imagery run and
# registry/state rebuild runs as a system service from the pinned `orthyra` flake input, never from the
# ~/orthyra working copy.
#
# Production has its own storage: system PostgreSQL (database `delta`, peer auth on the local socket) and
# SeaweedFS S3 on 127.0.0.1:8333, with data in /var/lib/postgresql and /var/lib/delta-s3. The dev stack in
# ~/orthyra (Postgres :55432, S3 :58333, ~/orthyra/.data) is separate and untouched.
#
# Deploy: `cd ~/orthyra && jj git fetch`, then `nix flake update orthyra` here, then switch.
{ inputs, lib, ... }:
let
  orthyra = inputs.orthyra;
  scheduled = file: lib.mapAttrs (_: schedule: { inherit schedule; }) (import "${orthyra}/nix/${file}");
in
{
  imports = [ orthyra.nixosModules.default ];

  services.delta = {
    enable = true;
    # S3 credentials are generated once on the host (root-only, never in the store); jaren gets a read-only
    # login on the production database. Both are module options, covered by the module's VM test.
    localInfra = {
      enable = true;
      generateSecrets = true;
      readers = [
        "jaren"
        "agent"
      ];
      # Point-in-time recovery to /var/lib/delta-backup. Off-site (box) waits for bounded WAL archiving.
      backup.enable = true;
    };
    connectors = scheduled "schedules.nix";
    watches = scheduled "watch-schedules.nix";
    imagery.enable = true;
    registry.enable = true;
  };
}
