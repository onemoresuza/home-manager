{
  xdg.mime = {
    enable = true;
    types = {
      dummyPackage = {
        essence = "application/dummy";
        globs = [
          {
            pattern = "*.dummy";
          }
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.local/share/mime/packages/application-dummy.xml
    assertFileContent home-files/.local/share/mime/packages/application-dummy.xml \
      ${builtins.toFile "application-dummy.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
        ${"\t"}<mime-type type="application/dummy">
        ${"\t\t"}<glob weight="50" pattern="*.dummy"/>
        ${"\t"}</mime-type>
        </mime-info>
      ''}
  '';
}
