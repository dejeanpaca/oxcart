{
   oxeduSceneClone, clone a scene
   Copyright (C) 2017. Dejan Boras

   Started On:    22.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneClone;

INTERFACE

   USES
      uLog,
      {ox}
      oxuEntity, oxuScene, oxuWorld, oxuSceneManagement, oxuSceneRender,
      {oxed}
      oxeduProjectRunner, oxeduLib, oxeduMessages, oxeduScene, oxeduEntities;

IMPLEMENTATION

procedure onBeforeStart();
begin
   oxedOriginalScene := oxScene;
   oxedOriginalWorld := oxWorld;
end;

procedure onAfterInitialize();
var
   entitiesGlobal: oxTEntityGlobal = nil;

begin
   entitiesGlobal := oxTEntityGlobal(oxLibReferences.FindInstance('oxTEntityGlobal'));
   if(entitiesGlobal <> nil) then begin
      oxedEntities.SetupHooks(entitiesGlobal);
   end else
      oxedMessages.e('Could not find ' + oxTSceneRender.ClassName + ' instance in the library');
end;


procedure onStart();
var
   sceneRender: oxTSceneRender;
   scene: oxTScene;
   externalSceneManagement: oxPSceneManagement;

begin
   externalSceneManagement := oxPSceneManagement(oxLibReferences.FindInstancePtr('oxTSceneManagement'));

   if(externalSceneManagement = nil) then begin
      oxedMessages.e('Could not find oxTSceneManagement instance in the library');
      exit;
   end;

   if(externalSceneManagement^.Enabled) then begin
      scene := oxTScene(oxLibReferences.FindInstance('oxTScene'));
      oxWorld := scene.World;
      oxSceneManagement.SetScene(scene);

      sceneRender := oxTSceneRender(oxLibReferences.FindInstance('oxTSceneRender'));

      if(sceneRender <> nil) then begin
         sceneRender.Scenes[0].Scene := oxScene;
         oxedLib.oxWindows^.w[0].oxProperties.ApplyDefaultProjection := false;
      end else
         oxedMessages.e('Could not find ' + oxTSceneRender.ClassName + ' instance in the library');
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

