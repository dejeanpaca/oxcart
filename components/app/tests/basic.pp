{
   Started On:    09.02.2011.
}


{$MODE OBJFPC}{$H+}
PROGRAM test;

USES
   uAppInfo, uLog,
   uApp, appuEvents, appuRun, appuKeys, appuPaths, appuLog;

BEGIN
   {$INCLUDE basic.appinfo.inc}

   app.Initialize();
END.
