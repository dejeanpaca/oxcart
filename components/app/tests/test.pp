{
   Started On:    09.02.2011.
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
