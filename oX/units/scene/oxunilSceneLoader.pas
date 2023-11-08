{
   oxunilSceneLoader, nil scene loader
   Copyright (c) 2020. Dejan Boras

   Started On:    09.01.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxunilSceneLoader;

INTERFACE

   USES
      uLog, uTiming,
      {ox}
      uOX,
      oxuScene, oxuSceneManagement, oxuSceneLoader;

IMPLEMENTATION

procedure start();
var
   timer: TTimer;
   ok: boolean = false;

begin
   if(not oxSceneManagement.Enabled) then begin
      log.v('(nil) scene loading not enabled');
      exit();
   end;

   TTimer.Init(timer);
   timer.InitStart();

   log.i('Loading scene (nil)');
   oxSceneLoader.LoadStart();
   oxSceneLoader.Load(oxScene);

   ok := true;

   timer.Update();
   if(ok) then
      log.i('Loaded scene (nil, elapsed: ' + timer.ElapsedfToString(3) + '): ' + oxScene.Name)
   else
      log.i('Failed to load scene (nil, elapsed: ' + timer.ElapsedfToString(3) + '): ' + oxScene.Name)
end;

INITIALIZATION
   ox.OnLoad.Add('ox.nil_scene_loader', @start);

END.
