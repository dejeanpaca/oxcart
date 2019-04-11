{
   appuKeys, keys
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuKeyStateUpdater;

INTERFACE

   USES
      appuKeys,
      {ox}
      oxuRunRoutines, oxuRun;

IMPLEMENTATION

VAR
   runRoutine: oxTRunRoutine;

procedure run();
begin
   appk.UpdateCycle();
end;


INITIALIZATION
   oxRun.AddPreRoutine(runRoutine, 'app.keystateupdater', @run);

END.
