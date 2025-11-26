{
  programs.warpd.enable = true;
  nmt.script = ''
    assertPathNotExists home-files/.config/warpd
  '';
}
