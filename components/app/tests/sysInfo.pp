{
   Copyright (C) 2012. Dejan Boras
}

{$MODE OBJFPC}{$H+}
PROGRAM sysInfo;

   USES uLog, uAppInfo, appuSysInfo, appuPaths, appuLog, uApp;

BEGIN
   appInfo.setName('sysinfo');
   appInfo.org := 'oxcart';
END.
