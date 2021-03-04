{
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
