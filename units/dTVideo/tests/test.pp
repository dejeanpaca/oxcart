PROGRAM test;

   USES uLog, uTVideo, SysUtils;

BEGIN
   randomize();

   log.InitStd('test.log', 'uTVideo', logcREWRITE);
   consoleLog.Close();

   tvGlobal.Initialize();
   tvGlobal.LogModes();
   tvGlobal.Deinitialize();
END.

