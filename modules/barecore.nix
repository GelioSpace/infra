{ pkgs, ... }: {

  imports = [ ./ssh-keys.nix ];

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # ctrl:nocaps at last
  };

  i18n.defaultLocale = "C.UTF-8";

  services = {
    avahi.enable = true;
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
    xserver = {
      xkb.layout = "us,ru";
      xkb.options = "ctrl:nocaps,lv3:ralt_switch_multikey,misc:typo,grp:win_space_toggle";
    };
  };

  programs.mosh.enable = true;
  users = {
    mutableUsers = false;
    users.root.shell = pkgs.zsh;
  };

}
