{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) foldl' toString;
  inherit (lib)
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.warpd;

  formatSettings = n: v: "${n}: ${toString v}";
in
{
  options.programs.warpd = {
    enable = mkEnableOption "warpd configuration";
    package = mkPackageOption pkgs "warpd" { };
    settings = mkOption {
      description = "configuration options for warpd";
      type = types.nullOr (types.attrsOf (types.either types.str types.int));
      default = null;
      example = literalExpression ''
        {
          hint_chars = "abcdefghijklmnopqrstuvwxyz1234567890";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile = mkIf (cfg.settings != null) {
      # NOTE: builtins.concatStringsSep should not be used here, since warpd
      # needs a trailing '\n' at the end of the config file or else it will
      # change the hint_fgcolor at every new call.
      "warpd/config".text = foldl' (acc: x: acc + x + "\n") "" (
        mapAttrsToList formatSettings cfg.settings
      );
    };
  };
}
