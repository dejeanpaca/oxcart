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
      procedure Loaded(scene: oxTScene);
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

   scene.LoadResources();
   log.v('scene > Loaded resources (Elapsed: ' + startTime.ElapsedfToString() + 's)');

   Loaded(scene);
   log.v('scene > Loaded scene');
end;

procedure oxTSceneLoader.Loaded(scene: oxTScene);
begin
   oxSceneManagement.SetScene(scene);

   OnLoaded.Call();
   scene.CallOnLoaded();
end;

INITIALIZATION
   oxSceneLoader.OnLoadStart.Initialize(oxSceneLoader.OnLoadStart);
   oxSceneLoader.OnLoaded.Initialize(oxSceneLoader.OnLoaded);

END.
