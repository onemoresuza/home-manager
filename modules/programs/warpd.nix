{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) concatStringsSep toString;
  inherit (lib)
    mapAttrsToList
    mkEnableOption
    mkPackageOption
    mkIf
    mkOption
    literalExpression
    types
    ;

  cfg = config.programs.warpd;
  attrToCfgFormat = n: v: "${n}: ${toString v}";
  # NOTE: the trailling newline is needed or else the foreground color will
  # changed at every new invocation of the program.
  text = (concatStringsSep "\n" (mapAttrsToList attrToCfgFormat cfg.settings)) + "\n";
in
{
  options.programs.warpd = {
    enable = mkEnableOption "warpd, a keyboard driven mouse interface";
    package = mkPackageOption pkgs "warpd" { nullable = true; };
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
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."warpd/config" = mkIf (cfg.settings != null) {
      inherit text;
    };
  };
}
