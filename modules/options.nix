{ lib, ... }:
with lib; with types;
{

  options = {
    users.users = mkOption {
      type = attrsOf (submodule {
        options.homeModules = mkOption {
          type = listOf path;
          default = [];
          description = "List of modules to include in a home profile.";
        };
      });
    };

    _ = {

      user = mkOption {
        type = str;
        default = "user";
        description = "Username for your single-user system.";
      };

    };

  };

}
