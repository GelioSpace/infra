{ sysconfig, pkgs, lib, ... }: {

  home.stateVersion = "24.05";

  home.keyboard = {
    layout = sysconfig.services.xserver.xkb.layout;
    options = with builtins;
      filter isString (split "," sysconfig.services.xserver.xkb.options);
  };

  home.packages = with pkgs; [
    ripgrep
  ];

  programs = let
    onWithShell = { enable = true; enableZshIntegration = true; };
  in {

    git.enable = true;

    direnv = { enable = true; nix-direnv.enable = true; };

    keychain = onWithShell // {
      keys = [];
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      defaultKeymap = "emacs";
      initContent = ''
      zstyle ':completion:*' menu select
      export PATH=$PATH:~/.cargo/bin
      '';

      shellAliases = {
        l = lib.mkDefault "ll";
      };

      history = {
        extended = true;
        ignoreDups = true;
        size = 10000000;
        save = 10000000;
      };

      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "82ca15e638cc208e6d8368e34a1625ed75e08f90";
            sha256 = "BjgMhILEL/qdgfno4LR64LSB8n9pC9R+gG7IQWwgyfQ=";
          };
        }
      ];

    };

  };

}
