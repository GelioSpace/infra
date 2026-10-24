{ pkgs, lib, ... }: {

  imports = [ ./options.nix ./barecore.nix ];

  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    settings = {
      trusted-users = [ "root" ];
      experimental-features = [ "nix-command" "flakes" ];
    };

    # Channel hack — pin channel nixpkgs to the same revision as the one used by the flake — so nix-shell works predictably.
    nixPath = [ "nixpkgs=${pkgs.path}" ];
    # Same thing for the channels.
    registry =
      let
        lock = (with builtins; fromJSON (readFile ../flake.lock));
      in
      lib.mkForce {
        nixpkgs = with lock.nodes.${lock.nodes.${lock.root}.inputs.nixpkgs}; {
          from = { id = "nixpkgs"; type = "indirect"; };
          to = locked;
        };
      };
  };

  boot = {
    loader.timeout = 1;
    kernelParams = [ "quiet" ];
  };

  services.fwupd.enable = true;

  programs.zsh = {
    enable = true;
    shellAliases = {
      vi = "hx";
    };
  };

  environment.shells = [ pkgs.zsh ];
  environment.pathsToLink = [ "/share/zsh" ];
  environment.variables = {
    EDITOR = "hx";
  };

  environment.defaultPackages = (with pkgs; [
    # this section is a tribute to my PEP-8 hatred
    socat curl htop git tmux rsync hexedit # find one which does not fit
    ntfsprogs btrfs-progs  # why aren't those there by default?
    killall usbutils pciutils zip unzip  # WHY AREN'T THOSE THERE BY DEFAULT?
    nmap arp-scan
    nix-index  # woo, search in nix packages files!
    nix-zsh-completions zsh-completions  # systemctl ena<TAB>... AAAAGH
    helix
  ]);

}
