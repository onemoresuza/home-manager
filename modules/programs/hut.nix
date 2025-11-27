{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) concatStringsSep;
  inherit (lib)
    mapAttrsToList
    mkEnableOption
    mkPackageOption
    mkIf
    mkOption
    literalExpression
    optionalString
    types
    ;

  cfg = config.programs.hut;

  instanceType = {
    options = {
      access-token = mkOption {
        description = "Sourcehut access string";
        type = types.nullOr types.str;
        default = null;
        example = literalExpression "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
      };
      access-token-cmd = mkOption {
        description = "Command which outpus to stdout a Sourcehut access string";
        type = types.nullOr types.str;
        default = null;
        example = literalExpression "rbw get hut";
      };
      meta = mkOption {
        description = "Origin for each service";
        type = types.nullOr (types.attrsOf types.str);
        default = { };
        example = literalExpression ''
          meta {
            origin "https://meta.sr.ht"
          }
        '';
      };
    };
  };

  instanceToText =
    name: value:
    let
      inherit (value) access-token access-token-cmd meta;
      access-token' = optionalString (access-token != null) "\taccess-token \"${access-token}\"\n";
      access-token-cmd' = optionalString (
        access-token-cmd != null
      ) "\taccess-token-cmd ${access-token-cmd}\n";
      metaToList = concatStringsSep "\n" (mapAttrsToList (n: v: "\t\t${n} \"${v}\"") meta);
      meta' = optionalString (meta != { }) ("\tmeta {\n" + metaToList + "\n" + "\t}\n");
    in
    "instance \"${name}\" {\n" + access-token' + access-token-cmd' + meta' + "}\n";

  text = concatStringsSep "\n" (mapAttrsToList instanceToText cfg.instances);
in
{
  options.programs.hut = {
    enable = mkEnableOption "hut, a Sourcehut cli";
    package = mkPackageOption pkgs "hut" { nullable = true; };
    instances = mkOption {
      description = "Sourcehut instances configurations";
      default = { };
      type = types.attrsOf (types.submodule instanceType);
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."hut/config" = mkIf (cfg.instances != { }) {
      inherit text;
    };
  };
}
