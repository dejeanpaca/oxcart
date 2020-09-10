{
   oxuSceneRunner, scene runner
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSceneRunner;

INTERFACE

   USES
      sysutils, uStd, uLog, uTiming,
      {ox}
      uOX, oxuEntity, oxuScene, oxuRunRoutines;

TYPE
   { oxTSceneRunner }

   oxTSceneRunner = record
      class procedure Run(); static;
   end;

VAR
   oxSceneRunner: oxTSceneRunner;

IMPLEMENTATION

{ oxTSceneRunner }

class procedure oxTSceneRunner.Run();
begin
    if(oxScene <> nil) then
       oxScene.UpdateComponentsInChildren();
end;


INITIALIZATION
   ox.OnRun.Add('ox.scene_runner', @oxTSceneRunner.Run);

END.
