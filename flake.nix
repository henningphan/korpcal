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
          packages.stadcal =
            let
              stadcal = pkgs.python313Packages.callPackage ./derivation.nix { };
            in
            pkgs.python313.withPackages (_: [ stadcal ]);
          devshells.default =
            let
              pwp = pkgs.python313.withPackages (ppkgs: [
                ppkgs.apscheduler
                ppkgs.flask
                ppkgs.gunicorn
                ppkgs.icalendar
                ppkgs.selenium
                ppkgs.playwright
              ]);
            in
            {
              env = [
                {
                  name = "PLAYWRIGHT_BROWSERS_PATH";
                  value = "${pkgs.playwright-driver.browsers}";
                }

                {
                  name = "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS";
                  value = "true";
                }
              ];

              commands = [
                {
                  help = "start flask local development server";
                  name = "startflask";
                  command = ''flask --app "./src/stadcal:create_app('../../example.config.toml')" run --host 0.0.0.0  -p 8081 --debug'';
                }
              ];

              packages = [
                pwp
                pkgs.firefox
                # self'.packages.stadcal
              ];
            };
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        nixosModules = {
          stadcal =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            let
              cfg = config.services.stadcal;
            in
            {
              options.services.stadcal = {
                enable = lib.mkEnableOption "Enable the stadcal http service";
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
                configPath = lib.mkOption {
                  type = lib.types.path;
                  default = "/run/secrets/stadcal.toml";
                  description = "Path to stadcal toml config file";
                };
              };
              config = lib.mkIf cfg.enable {
                henning.nginx.virtualHosts = lib.mkIf cfg.enableProxy {
                  "stadcal.phan.se" = {
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
                systemd.services.stadcal = {
                  wantedBy = [ "multi-user.target" ];
                  environment = {
                    HOME = "%C/stadcal";
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
                          export "PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}"
                          export "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true"
                          ${self.packages.x86_64-linux.stadcal}/bin/gunicorn \
                                  "stadcal:create_app('$CREDENTIALS_DIRECTORY/stadcal.toml')" \
                                  -b ${cfg.listenAddress}:${builtins.toString cfg.port}
                        '';
                      in
                      "${start_http}";
                    RuntimeDirectory = "stadcal";
                    RuntimeDirectoryMode = "750";
                    CacheDirectory = "stadcal";
                    CacheDirectoryMode = "750";
                    LoadCredential = [ "stadcal.toml:${cfg.configPath}" ];
                  };
                };
              };
            };
        };
      };
    };
}
