{
   oxeduSceneClone, clone a scene
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneClone;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      oxuEntity, oxuScene, oxuWorld, oxuSceneManagement, oxuSceneRender,
      {oxed}
      oxeduProjectRunner, oxeduLib, oxeduScene, oxeduEntities;

IMPLEMENTATION

procedure onBeforeStart();
begin
   oxedOriginalScene := oxScene;
   oxedOriginalWorld := oxWorld;
end;

procedure onAfterInitialize();
var
   entitiesGlobal: oxPEntityGlobal = nil;

begin
   entitiesGlobal := oxLibReferences^.FindInstancePtr('oxTEntityGlobal');

   if(entitiesGlobal <> nil) then
      oxedEntities.SetupHooks(entitiesGlobal^);
end;

procedure onStart();
var
   sceneRender: oxPSceneRender;
   scene: oxTScene;
   externalSceneManagement: oxPSceneManagement;

begin
   externalSceneManagement := oxLibReferences^.FindInstancePtr('oxTSceneManagement');

   if(externalSceneManagement <> nil) and externalSceneManagement^.Enabled then begin
      scene := oxTScene(oxLibReferences^.FindInstance('oxTScene'));
      oxWorld := scene.World;
      oxSceneManagement.SetScene(scene);

      sceneRender := oxPSceneRender(oxLibReferences^.FindInstancePtr('oxTSceneRender'));

      if(sceneRender <> nil) then
         sceneRender^.Scenes[0].Scene := oxScene;
   end;
end;

procedure onStop();
begin
   {scene and world should be freed by the library engine}
   oxWorld := oxedOriginalWorld;
   oxSceneManagement.SetScene(oxedOriginalScene);
   log.v('oxed > Scene restored to original');
end;

INITIALIZATION
   oxedProjectRunner.OnAfterInitialize.Add(@onAfterInitialize);
   oxedProjectRunner.OnBeforeStart.Add(@onBeforeStart);
   oxedProjectRunner.OnStart.Add(@onStart);
   oxedProjectRunner.OnStop.Add(@onStop);

END.

