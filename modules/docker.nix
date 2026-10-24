{ pkgs, ... }: {
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
      liveRestore = true;
      daemon.settings = {
        # Published ports via iptables NAT instead of a docker-proxy process per port.
        userland-proxy = false;
        # Container logs are unbounded by default.
        log-driver = "json-file";
        log-opts = { max-size = "10m"; max-file = "3"; };
        default-ulimits.nofile = { Name = "nofile"; Soft = 65536; Hard = 1048576; };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
