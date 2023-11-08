{
   oxuSceneLoader, scene loader
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuSceneLoader;

INTERFACE

   USES
      sysutils, uStd, uLog, uTiming,
      {ox}
      oxuEntity, oxuScene, oxuSceneManagement;

TYPE
   { oxTSceneLoader }

   oxTSceneLoader = record
      OnLoadStart,
      OnLoaded: TProcedures;

      procedure LoadStart();
      procedure Load(scene: oxTScene);
   end;

VAR
   oxSceneLoader: oxTSceneLoader;

IMPLEMENTATION

{ oxTSceneLoader }

procedure oxTSceneLoader.LoadStart();
begin
   OnLoadStart.Call();
end;

procedure oxTSceneLoader.Load(scene: oxTScene);
var
   startTime: TDateTime;

begin
   if(not oxSceneManagement.Enabled) then begin
      log.v('Scene > Not enabled to load: ' + scene.Name);
      exit;
   end;

   log.v('scene > Loading: ' + scene.Name);

   startTime := Time();
   oxSceneManagement.SetScene(scene);

   scene.LoadResources();
   log.v('scene > Loaded resources (Elapsed: ' + startTime.ElapsedfToString() + 's)');

   scene.LoadComponentsInChildren();
   log.v('scene > Loaded components');

   OnLoaded.Call();
   scene.CallOnLoaded();
   log.v('scene > Loaded scene');

   scene.StartComponentsInChildren();
   log.v('scene > Started components');
end;

INITIALIZATION
   oxSceneLoader.OnLoadStart.Initialize(oxSceneLoader.OnLoadStart);
   oxSceneLoader.OnLoaded.Initialize(oxSceneLoader.OnLoaded);

END.
