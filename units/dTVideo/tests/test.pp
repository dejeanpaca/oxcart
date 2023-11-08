PROGRAM test;

   USES uLog, uTVideo, SysUtils;

BEGIN
   randomize();

   logInitStd('test.log', 'uTVideo', logcREWRITE);

   tvInit();
   tvDeInit();
END.

