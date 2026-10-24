{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "8.8.8.8"
    ];

    defaultGateway = "172.31.1.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "77.42.75.146"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "2a01:4f9:c012:f59c::1"; prefixLength = 64; }
          { address = "fe80::9000:7ff:fe04:321d"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
      };

    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="92:00:07:04:32:1d", NAME="eth0"
  '';
}
