{ pkgs, ... }: {

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
    users.root = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKIABDEIeccdbZwTgxhkVUIyZa8fx9uyiE0I2S9t4x1 cab404@meow2"
      ];
    };
  };

}
