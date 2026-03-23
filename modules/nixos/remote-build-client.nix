{ config, lib, ... }:

let
  cfg = config.jaren.remoteBuilds;
in
{
  options.jaren.remoteBuilds = {
    hostName = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "desktop.tail1234.ts.net";
      description = ''
        Tailscale DNS name or IP address of the remote build machine.
        Remote builds stay disabled until this is set.
      '';
    };

    sshUser = lib.mkOption {
      type = lib.types.str;
      default = "builder";
      description = "SSH user used by the laptop to connect to the remote builder.";
    };

    knownHostNames = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "desktop.tail1234.ts.net" "100.101.102.103" ];
      description = ''
        Hostnames or IPs that should be pinned to knownHostPublicKey.
        Leave empty if you are managing known_hosts outside Nix.
      '';
    };

    knownHostPublicKey = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";
      description = "Pinned SSH host key for the remote builder.";
    };

    systems = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "x86_64-linux" ];
      description = "Systems the remote builder can build.";
    };

    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Maximum concurrent build jobs the remote builder should run.";
    };

    speedFactor = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Relative speed of the remote builder compared to this laptop.";
    };

    supportedFeatures = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "big-parallel" ];
      description = "System features advertised by the remote builder.";
    };

    mandatoryFeatures = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "big-parallel" ];
      description = ''
        Features that every derivation must request before it is sent to the
        remote builder. Keeping big-parallel here reserves the desktop for
        larger builds.
      '';
    };
  };

  config = lib.mkIf (cfg.hostName != null) {
    assertions = [
      {
        assertion = cfg.knownHostPublicKey == null || cfg.knownHostNames != [ ];
        message = "Set jaren.remoteBuilds.knownHostNames when using jaren.remoteBuilds.knownHostPublicKey.";
      }
    ];

    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;
    nix.buildMachines = [
      {
        hostName = "nixos-1";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        sshUser = "jaren";
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [ "big-parallel" "kvm"]
      }
    ];

    programs.ssh.knownHosts = lib.mkIf (cfg.knownHostPublicKey != null) (
      builtins.listToAttrs (map (name: {
        inherit name;
        value.publicKey = cfg.knownHostPublicKey;
      }) cfg.knownHostNames)
    );
  };
}
