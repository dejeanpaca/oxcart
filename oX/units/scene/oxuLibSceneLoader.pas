{
   oxuLibSceneLoader, library scene loader
   Copyright (c) 2018. Dejan Boras

   Started On:    31.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuLibSceneLoader;

INTERFACE

   USES
      uStd, uLog, uTiming,
      {ox}
      uOX, oxuRunRoutines,
      oxuGlobalInstances, oxuEntity, oxuScene, oxuWorld, oxuSceneLoader, oxuSceneClone, oxuSerialization;

IMPLEMENTATION

procedure start();
var
   timer: TTimer;
   original: oxTScene;
   ok: boolean = false;
   scene: oxTScene = nil;

begin
   if(not oxSceneManagement.Enabled) then begin
      log.v('(lib) scene loading not enabled');
      exit();
   end;

   if(oxExternalGlobalInstances <> nil) then begin
      TTimer.Init(timer);
      timer.InitStart();

      log.i('Loading scene (lib)');
      oxSceneLoader.LoadStart();

      original := oxTScene(oxExternalGlobalInstances.FindInstance('oxTScene'));
      if(original <> nil) then begin
         oxCloneScene(original, scene, oxSerialization);

         scene.Name := scene.Name + ' (lib)';
         oxWorld := scene.World;

         if(scene <> nil) then begin
            log.v('Cloned scene: ' + scene.Name);

            oxSceneLoader.Load(scene);
            ok := true;
         end else
            log.e('Failed to clone original scene ' + original.Name);
      end else
         log.e('Failed to find original scene');

      timer.Update();
      if(ok) then
         log.i('Loaded scene (lib, elapsed: ' + timer.ElapsedfToString(3) + '): ' + oxScene.Name)
      else
         log.i('Failed to load scene (lib, elapsed: ' + timer.ElapsedfToString(3) + '): ' + oxScene.Name)
   end;
end;

VAR
   routine: oxTRunRoutine;

INITIALIZATION
   ox.OnLoad.Add(routine, 'oxlib.scene_loader', @start);

END.
