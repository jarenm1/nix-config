{ config, lib, ... }:

let
  cfg = config.jaren.remoteBuilderHost;
  userExists = lib.hasAttrByPath [ "users" "users" cfg.user ] config;
in
{
  options.jaren.remoteBuilderHost = {
    enable = lib.mkEnableOption "expose this machine as a remote Nix builder";

    user = lib.mkOption {
      type = lib.types.str;
      default = "jaren";
      description = "SSH user remote clients use for builds on this machine.";
    };

    createUser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Create the remote builder user in NixOS. Leave disabled when using an
        existing login such as your normal user account.
      '';
    };

    authorizedKeys = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... laptop" ];
      description = ''
        SSH public keys allowed to access the remote builder account. This is
        only required when createUser is enabled.
      '';
    };

    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Maximum build jobs to allow on this machine.";
    };

    supportedFeatures = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "big-parallel" ];
      description = "System features this machine can advertise to remote clients.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.createUser || userExists;
        message = "The remote builder user must already exist unless jaren.remoteBuilderHost.createUser is enabled.";
      }
      {
        assertion = !cfg.createUser || cfg.authorizedKeys != [ ];
        message = "Set jaren.remoteBuilderHost.authorizedKeys when jaren.remoteBuilderHost.createUser is enabled.";
      }
    ];

    services.openssh.enable = true;

    users.users = lib.mkIf cfg.createUser {
      "${cfg.user}" = {
        isNormalUser = true;
        description = "Remote Nix builder";
        createHome = true;
        home = "/var/lib/${cfg.user}";
        openssh.authorizedKeys.keys = cfg.authorizedKeys;
      };
    };

    nix.settings.builders-use-substitutes = true;
    nix.settings.max-jobs = cfg.maxJobs;
    nix.settings.trusted-users = lib.mkAfter [ cfg.user ];
    nix.settings.system-features = lib.mkAfter cfg.supportedFeatures;
  };
}
