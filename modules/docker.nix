{ pkgs, ... }: {
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
      liveRestore = true;
      daemon.settings = {
        # Keep userland-proxy (the default): Caddy reaches containers through
        # ports published on 127.0.0.1, and without docker-proxy nothing
        # actually listens there; the iptables-only path for loopback breaks.
        # It is also what forwards host IPv6 to IPv4-only containers below.

        # Ports published without an address (`5001:5001`) bind to [::1] only,
        # instead of every interface. Explicit addresses still win.
        # `ip` covers the default bridge, the network option covers networks
        # created from now on (i.e. compose projects).
        ip = "::1";
        default-network-opts.bridge."com.docker.network.bridge.host_binding_ipv4" = "::1";

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
