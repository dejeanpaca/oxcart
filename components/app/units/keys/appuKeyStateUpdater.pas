{
   appuKeys, keys
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuKeyStateUpdater;

INTERFACE

   USES
      appuKeys,
      {ox}
      oxuRunRoutines, oxuRun;

IMPLEMENTATION

procedure run();
begin
   appk.UpdateCycle();
end;


INITIALIZATION
   oxRun.AddPreRoutine('app.keystateupdater', @run);

END.
