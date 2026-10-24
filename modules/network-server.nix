# Kernel and limits tuning for a box whose job is shoveling traffic:
# reverse proxy in front, NATed docker containers behind.
# Everything is mkDefault, so a host can override single values.
{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  boot.kernelModules = [
    "tcp_bbr"
    # Loaded early so the conntrack sysctls below apply at boot.
    "nf_conntrack"
  ];

  boot.kernel.sysctl = lib.mapAttrs (_: mkDefault) {
    # BBR + fq pacing instead of cubic.
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Socket buffers. rmem/wmem_max also cover QUIC (Caddy's HTTP/3 wants ~7.5M).
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 131072 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.udp_rmem_min" = 16384;
    "net.ipv4.udp_wmem_min" = 16384;

    # Queues and backlogs for bursts of new connections.
    "net.core.somaxconn" = 65535;
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_max_syn_backlog" = 65535;

    # Connection behaviour.
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_fin_timeout" = 15;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_keepalive_time" = 300;
    "net.ipv4.tcp_keepalive_intvl" = 30;
    "net.ipv4.tcp_keepalive_probes" = 5;
    # Starts above the usual service ports, so outgoing connections don't take
    # a port a container is about to publish.
    "net.ipv4.ip_local_port_range" = "10240 65535";

    # Docker NATs every published port through conntrack.
    "net.netfilter.nf_conntrack_max" = 262144;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400;

    # fs.file-max, fs.nr_open, inotify and vm.max_map_count are already
    # high enough by kernel/NixOS defaults.
  };

  # Raise the default fd limit for all services (soft:hard).
  systemd.settings.Manager.DefaultLimitNOFILE = mkDefault "65536:1048576";
}
