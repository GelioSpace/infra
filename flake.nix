{
  description = "cab's system config";
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      # "https://helix.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    extra-experimental-features = [
      "pipe-operators"
      "ca-derivations"
    ];
  };

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # snm.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    # snm.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hw.url = "github:nixos/nixos-hardware";

  };

  outputs =
    inputs @ { self
    , nixpkgs
    , home-manager
    , ...
    }:
    let
      system = "x86_64-linux";
      patchedPkgs =
        let
          patches = [
            # ./patches/soft-reboot.patch
            # Place your nixpkgs patches here
            # ./patches/v4.patch # Scary one with x86-64-v4 and a _full_ system rebuild
            # ./patches/361716.patch
          ];
          patched = import "${nixpkgs.legacyPackages.${system}.applyPatches {
              inherit patches;
              name = "nixpkgs-patched";
              src = nixpkgs;
          }}/flake.nix";
          invoked = patched.outputs { self = invoked; };
        in
        if builtins.length patches > 0 then invoked else nixpkgs;

      inherit (patchedPkgs) lib;

      specialArgs = {
        inherit inputs; inherit (inputs) nixos-raspberrypi;
      };

      buildSystem = mode: system: modules: {
          # Mode list. You can add your custom pkgs and stuff here
          default = lib.nixosSystem;
          rpi = inputs.nixos-raspberrypi.lib.nixosSystem;
        }.${mode} { inherit modules system specialArgs; };

      # Path concatenation (not string interpolation), so that relative imports
      # inside node configs resolve within the flake source.
      hostAttrs = dir: {
        settings = import (dir + "/host-metadata.nix");
        config = dir + "/configuration.nix";
        hw-config = dir + "/hardware-configuration.nix";
      };

      node = dir: with hostAttrs dir; buildSystem (settings.mode or "default") settings.system [
        config
        hw-config
      ];

      onPkgs = f: builtins.mapAttrs f patchedPkgs.legacyPackages;

      # Maps over ./nodes directory, reading all of the configs there.
      hosts = with builtins; attrNames (readDir ./nodes);
      nodes = with builtins; listToAttrs (map (a: {name = a; value = ./nodes/${a}; }) hosts);

    in
    rec {

      nixosConfigurations =
        (builtins.mapAttrs (_: node) nodes) //
        {

          installer = buildSystem "default" "x86_64-linux" [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            ({ config, lib, pkgs, ... }: {
              imports = [
                ./modules/home-manager
                ./modules/core.nix
              ];
              home-manager.users.${config._.user}.imports = [
                ./modules/home-manager/user-shell.nix
              ];

              _.user = "nixos";

              networking.networkmanager.enable = true;
              networking.wireless.enable = lib.mkForce false;

              boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

              environment.systemPackages = [
                config.boot.kernelPackages.chipsec
              ];

              boot.extraModulePackages = with config.boot.kernelPackages; [
                chipsec
              ];

            })
          ];

        };

      devShells = onPkgs (system: pkgs: with pkgs; {
        default = mkShell {
          buildInputs = [
            nixVersions.latest
            nixpkgs-fmt
            nil
            nix-output-monitor
            nix
            nushell

          ];
        };
      });


      nodeMeta = builtins.mapAttrs (_: h: (hostAttrs h)) nodes;

      packages.x86_64-linux.installer = nixosConfigurations.installer.config.system.build.iso;
    };

}
