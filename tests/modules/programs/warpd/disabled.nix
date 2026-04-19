{
  warpd.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/warpd"
  '';
}
