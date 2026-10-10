{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.korpcal =
            let
              korpcal = pkgs.python313Packages.callPackage ./derivation.nix { };
            in
            pkgs.python313.withPackages (_: [ korpcal ]);
          devshells.default =
            let
              pwp = pkgs.python313.withPackages (ppkgs: [
                ppkgs.apscheduler
                ppkgs.flask
                ppkgs.gunicorn
                ppkgs.icalendar
                ppkgs.selenium
              ]);
            in
            {
              env = [
              ];

              commands = [
                {
                  help = "start flask local development server";
                  name = "startflask";
                  command = ''flask --app "./src/korpcal:create_app()" run --host 0.0.0.0  -p 8081 --debug'';
                }
              ];

              packages = [
                pwp
                pkgs.firefox
                # self'.packages.korpcal
              ];
            };
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        nixosModules = {
          korpcal =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            let
              cfg = config.services.korpcal;
            in
            {
              options.services.korpcal = {
                enable = lib.mkEnableOption "Enable the korpcal http service";
                enableProxy = lib.mkEnableOption "enableProxy";

                port = lib.mkOption {
                  type = lib.types.port;
                  default = 8080;
                  description = "TCP port number for receiving connections";
                };
                listenAddress = lib.mkOption {
                  type = lib.types.str;
                  default = "0.0.0.0";
                  description = "Interface address for receiving connections";

                };
              };
              config = lib.mkIf cfg.enable {
                henning.nginx.virtualHosts = lib.mkIf cfg.enableProxy {
                  "korpcal.phan.se" = {
                    forceSSL = true;
                    enableACME = true;
                    locations."/" = {
                      proxyPass = "http://${cfg.listenAddress}:8080";
                      extraConfig = ''
                        proxy_set_header        Host $host;
                        proxy_set_header        X-Real-IP $proxy_protocol_addr;
                        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header        X-Forwarded-Proto $scheme;
                        proxy_set_header        X-Forwarded-Host $host;
                        proxy_set_header        X-Forwarded-Server $host;
                      '';
                    };
                  };
                };
                systemd.services.korpcal = {
                  wantedBy = [ "multi-user.target" ];
                  environment = {
                    HOME = "%C/korpcal";
                  };
                  serviceConfig = {
                    DynamicUser = "true";
                    CapabilityBoundingSet = "";
                    LockPersonality = "true";
                    NoNewPrivileges = "true";
                    ProtectControlGroups = "true";
                    PrivateDevices = "true";
                    PrivateTmp = "true";
                    ProtectClock = "true";
                    ProtectHome = "true";
                    ProtectHostname = "true";
                    ProtectKernelLogs = "true";
                    ProtectKernelTunables = "true";
                    ProtectProc = "invisible";
                    RestrictAddressFamilies = [
                      "AF_INET"
                      "AF_INET6"
                    ];
                    RestrictNamespaces = "true";
                    RestrictSUIDSGID = "true";
                    ProtectSystem = "full";
                    Restart = "on-failure";
                    ExecStart =
                      let
                        start_http = pkgs.writeShellScript "start_http" ''
                          ${self.packages.x86_64-linux.korpcal}/bin/gunicorn \
                                  "korpcal:create_app()" \
                                  -b ${cfg.listenAddress}:${builtins.toString cfg.port}
                        '';
                      in
                      "${start_http}";
                    RuntimeDirectory = "korpcal";
                    RuntimeDirectoryMode = "750";
                    CacheDirectory = "korpcal";
                    CacheDirectoryMode = "750";
                  };
                };
              };
            };
        };
      };
    };
}
