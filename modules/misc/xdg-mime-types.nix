{
  config,
  lib,
  ...
}:
let
  inherit (builtins)
    concatStringsSep
    isAttrs
    isList
    isString
    replaceStrings
    ;
  inherit (lib)
    escapeXML
    literalExpression
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optionalString
    types
    throwIf
    ;

  cfg = config.xdg.mime;

  globType = {
    options = {
      weight = mkOption {
        default = 50;
        description = ''
          The weight for the glob pattern.
        '';
        type = types.int;
      };
      pattern = mkOption {
        type = types.str;
        description = ''
          The glob pattern for the mimetype.
        '';
      };
    };
  };

  magicMatchType = {
    options = {
      type = mkOption {
        description = ''
          The type of the attribute.
        '';
        type = types.enum [
          "string"
          "host16"
          "host32"
          "big16"
          "big32"
          "little16"
          "little32"
          "byte"
        ];
      };
      offset = mkOption {
        type = types.either types.int (types.strMatching "[[:digit:]]+:[[:digit:]]+");
        description = ''
          The byte offset(s) in the file to check. This may be a single number
          or a range in the form `start:end', indicating that all offsets in
          the range should be checked. The range is inclusive.
        '';
      };
      value = mkOption {
        type = types.str;
        description = ''
          The value to compare the file contents with, in the format indicated
          by the type attribute. The string type supports the C character
          escapes (\0, \t, \n, \r, \xAB for hex, \777 for octal).
        '';
      };
    };
  };

  magicType = {
    options = {
      priority = mkOption {
        default = 50;
        type = types.int;
        description = ''
          The priority of the magic value.
        '';
      };
      matches = mkOption {
        type = types.listOf (types.submodule magicMatchType);
        description = ''
          Elements for matching file content.
        '';
      };
    };
  };

  mimeType =
    let
      essenceMatchPattern = "[a-zA-Z0-9.+-]+/[a-zA-Z0-9.+-]+";
    in
    {
      options = {
        aliases = mkOption {
          default = null;
          type = types.nullOr (types.listOf (types.strMatching essenceMatchPattern));
          description = ''
            Essences through which the mimetype is also known.
          '';
          example = [
            "text/x-diff"
            "text/patch"
            "text/x-patch"
          ];
        };
        comment = mkOption {
          default = null;
          description = ''
            A comment for the mimetype.
          '';
          type = types.nullOr types.str;
        };
        essence = mkOption {
          description = ''
            The essence of the mimetype, e. g., text/x-patch.
          '';
          type = types.nullOr (types.strMatching essenceMatchPattern);
        };
        globs = mkOption {
          description = ''
            Glob patterns against which to match a filename.
          '';
          type = types.nullOr (types.listOf (types.submodule globType));
          default = null;
          example = literalExpression ''
            [
              {
                weight = 50;
                pattern = "*.txt";
              }
            ]
          '';
        };
        glob-deleteall = mkOption {
          default = false;
          type = types.bool;
          description = ''
            Enable glob-deleteall option.
          '';
        };
        magic = mkOption {
          default = null;
          type = types.nullOr (types.submodule magicType);
          description = ''
            Element for matching file content.
          '';
        };
        magic-deleteall = mkOption {
          default = false;
          type = types.bool;
          description = ''
            Enable magic-deleteall option.
          '';
        };
        sub-class = mkOption {
          default = null;
          description = ''
            The sub-class of the mimetype.
          '';
          type = types.nullOr types.str;
        };
      };
    };
  makeMimeType =
    {
      essence,
      aliases ? null,
      globs ? null,
      magic ? null,
      magic-deleteall ? true,
      comment ? null,
      glob-deleteall ? true,
      sub-class ? null,
    }:
    throwIf (globs == null && magic == null) "Either `globs` or `magic` must be set" (
      let
        name = replaceStrings [ "/" ] [ "-" ] essence;
        aliases' = concatStringsSep "\n" (map (alias: "\t\t<alias type=\"${alias}\"/>") aliases);
        globs' = concatStringsSep "\n" (
          map (
            glob:
            let
              weight = toString glob.weight;
              pattern = escapeXML glob.pattern;
            in
            "\t\t<glob weight=\"${weight}\" pattern=\"${pattern}\"/>"
          ) globs
        );
        magic' =
          "\t\t<magic priority=\"${toString magic.priority}\">\n"
          + concatStringsSep "\n" (
            map (
              match:
              let
                inherit (match) type;
                offset = toString match.offset;
                value = escapeXML match.value;
              in
              "\t\t\t<match type=\"${type}\" offset=\"${offset}\" value=\"${value}\"/>"
            ) magic.matches
          )
          + "\n\t\t</magic>";
      in
      {
        target = "mime/packages/${name}.xml";
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          ${"\t"}<mime-type type="${essence}">
        ''
        + (optionalString (isString comment) "\t\t<comment>${comment}</comment>\n")
        + (optionalString (isString sub-class) "\t\t<sub-class-of type=\"${sub-class}\"/>\n")
        + (optionalString glob-deleteall "\t\t<glob-deleteall/>\n")
        + (optionalString magic-deleteall "\t\t<magic-deleteall/>\n")
        + (optionalString (isList aliases) "${aliases'}\n")
        + (optionalString (isList globs) "${globs'}\n")
        + (optionalString (isAttrs magic) "${magic'}\n")
        + ''
          ${"\t"}</mime-type>
          </mime-info>
        '';
      }
    );
in
{
  #meta.maintainers = with lib.maintainers; [];

  options.xdg.mimeTypes = {
    enable = mkEnableOption "custom XDG mime types";
  };

  options.xdg.mime.types = mkOption {
    description = "User custom mimetypes.";
    # An attribute set is used instead of a list of attribute sets, so that the
    # user may still easily access their values (e. g.,
    # config.xdg.mime.customTypes.<my-custom-type>.essence).
    type = types.attrsOf (types.submodule mimeType);
    default = { };
    example = literalExpression ''
      {
        scdoc = {
          aliases = [
            "text/scd"
            "text/scdoc"
            "application/scdoc"
          ];
          comment = "Mimetype for scdoc files";
          essence = "text/x-scd";
          globs = [
            {
              weight = 100;
              pattern = "*.scd";
            }
          ];
          glob-deleteall = true;
          sub-class = "text";
        };
      }
    '';
  };

  config = mkIf (cfg.enable && cfg.types != { }) {
    xdg.dataFile = mapAttrs' (n: v: nameValuePair "xdg-mime-type-${n}" (makeMimeType v)) cfg.types;
  };
}
