{
  programs.hut = {
    enable = true;
    instances = {
      "sr.ht" = {
        access-token = "<token>";
        access-token-cmd = "pass hut";
        meta = {
          origin = "https://meta.sr.ht";
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/hut/config \
    ${builtins.toFile "hut" ''
      instance "sr.ht" {
      ${"\t"}access-token "<token>"
      ${"\t"}access-token-cmd pass hut
      ${"\t"}meta {
      ${"\t\t"}origin "https://meta.sr.ht"
      ${"\t"}}
      }
    ''}
  '';
}
