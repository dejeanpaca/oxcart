{$INCLUDE oxheader.inc}
PROGRAM test;

   USES uLog;

BEGIN
   logInitStd('test.log', 'Drunk Science!', logcREWRITE);

   log.Enter('Information');
      log.Enter('Graphics Device');
         log.i('Manufacturer: AMD');
         log.i('Renderer: AMD Radeon 4850');
         log.i('Extensions: ');
         log.i('GL_EXT_SHADORZ');
         log.i(' GL_EXT_LAZ0RZ');
         log.i(' GL_EXT_FANCY_FX');
         log.i();
      log.Leave();
      log.Enter('CPU');
         log.i('Manufacturer: AMD');
         log.i('Model: AMD Athlon II X240');
      log.Leave();
   log.Leave();
   log.i('This is a test.');
END.
