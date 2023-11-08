{
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}
PROGRAM test;

USES
   uAppInfo, uLog,
   appuEvents, appuRun, appuKeys, appuPaths;

BEGIN
   appcName := 'Test';
   appcNameShort := 'test';

   logInitStd('test.log', appcName, logcREWRITE);

   appCreateConfigDir();
END.
