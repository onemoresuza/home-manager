{
  programs.warpd = {
    enable = true;

    settings = {
      hint = "o";
      hint_chars = "abcde";
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/warpd/config \
      ${builtins.toFile "warpd-config" ''
        hint: o
        hint_chars: abcde
      ''}
  '';
}
