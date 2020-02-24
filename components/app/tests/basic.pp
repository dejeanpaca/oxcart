{
   Copyright (C) 2009. Dejan Boras
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
