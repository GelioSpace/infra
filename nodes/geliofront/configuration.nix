{ ... }: {
  imports = [
    ../../modules/core.nix
    ../../modules/docker.nix
    ../../modules/ssh-keys.nix
    ../../modules/imperative-caddy.nix
    ../../modules/network-server.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "geliofront";
  networking.domain = "";

  system.stateVersion = "25.05";
}
