{ config, lib, ... }:

let
  cfg = config.jaren.remoteBuilds;
in
{
  options.jaren.remoteBuilds = {
    enable = lib.mkEnableOption "use another machine as a remote Nix builder";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      example = "desktop.tail1234.ts.net";
      description = ''
        Tailscale DNS name or IP address of the remote build machine.
      '';
    };

    sshUser = lib.mkOption {
      type = lib.types.str;
      default = "jaren";
      description = "SSH user used by the laptop to connect to the remote builder.";
    };

    sshKey = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "/root/.ssh/nix-builder";
      description = ''
        Optional private key used by the Nix daemon to SSH into the builder.
        Leave null if root already has non-interactive SSH access to sshUser@hostName.
      '';
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

    system = lib.mkOption {
      type = lib.types.str;
      default = "x86_64-linux";
      description = "System type the remote builder can build.";
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
      default = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      description = "System features advertised by the remote builder.";
    };

    mandatoryFeatures = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = ''
        Features that every derivation must request before it can be sent to
        the remote builder. Leave empty to let normal builds use the desktop.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.knownHostPublicKey == null || cfg.knownHostNames != [ ];
        message = "Set jaren.remoteBuilds.knownHostNames when using jaren.remoteBuilds.knownHostPublicKey.";
      }
    ];

    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;
    nix.buildMachines = [
      ({
        inherit (cfg) hostName sshUser maxJobs speedFactor supportedFeatures mandatoryFeatures;
        protocol = "ssh-ng";
        inherit (cfg) system;
      } // lib.optionalAttrs (cfg.sshKey != null) {
        inherit (cfg) sshKey;
      })
    ];

    programs.ssh.knownHosts = lib.mkIf (cfg.knownHostPublicKey != null) (
      builtins.listToAttrs (map (name: {
        inherit name;
        value.publicKey = cfg.knownHostPublicKey;
      }) cfg.knownHostNames)
    );
  };
}
