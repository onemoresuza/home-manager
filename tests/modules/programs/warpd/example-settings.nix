{
  programs.warpd = {
    enable = true;
    settings = {
      hint_chars = "abcdefghijklmnopqrstuvwxyz1234567890";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/warpd/config \
      ${builtins.toFile "warpd-config" ''
        hint_chars: abcdefghijklmnopqrstuvwxyz1234567890
      ''}

  '';
}
