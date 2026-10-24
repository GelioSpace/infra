# Caddy with a Caddyfile that lives outside the store, so it can be edited in place.
# Apply changes with `systemctl reload caddy`; rebuilds don't touch it.
{ config, ... }:
let
  caddyfile = "${config.services.caddy.dataDir}/Caddyfile";
in
{
  services.caddy = {
    enable = true;
    openFirewall = true;
    configFile = caddyfile;
  };

  # Seed a placeholder on first boot so caddy can start; never overwritten.
  # (Caddy refuses a completely empty Caddyfile, a comment is fine.)
  systemd.tmpfiles.settings."10-caddy".${caddyfile}.f = {
    inherit (config.services.caddy) user group;
    mode = "0644";
    argument = "# Edit me, then: systemctl reload caddy\n";
  };
}
