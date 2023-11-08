{
   oxuSceneLoader, scene loader
   Copyright (c) 2018. Dejan Boras

   Started On:    31.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuSceneLoader;

INTERFACE

   USES
      sysutils, uStd, uLog, uTiming,
      {ox}
      oxuEntity, oxuScene;

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
   log.v('scene > Loading: ' + scene.Name);

   startTime := Time();
   oxSceneManagement.SetScene(scene);

   scene.LoadResources();
   log.v('scene > Loaded resources (Elapsed: ' + startTime.ElapsedfToString() + 's)');

   OnLoaded.Call();
   scene.CallOnLoaded();
   log.v('scene > Loaded scene');

   scene.LoadComponentsInChildren();
   log.v('scene > Loaded components');

   scene.StartComponentsInChildren();
   log.v('scene > Started components');
end;

INITIALIZATION
   oxSceneLoader.OnLoadStart.Initialize(oxSceneLoader.OnLoadStart);
   oxSceneLoader.OnLoaded.Initialize(oxSceneLoader.OnLoaded);

END.
