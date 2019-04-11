{
   oxuSceneRunner, scene runner
   Copyright (c) 2018. Dejan Boras

   Started On:    19.12.2018.
}

{$INCLUDE oxdefines.inc}
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

VAR
   routine: oxTRunRoutine;

INITIALIZATION
   ox.OnRun.Add(routine, 'ox.scene_runner', @oxTSceneRunner.Run);

END.
