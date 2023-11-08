{
   appuKeys, keys
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$INCLUDE oxdefines.inc}
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
