{
   oxuLibSceneLoader, library scene loader
   Copyright (c) 2018. Dejan Boras

   Started On:    31.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuLibSceneLoader;

INTERFACE

   USES
      uStd, uLog, uTiming, StringUtils,
      {ox}
      uOX, oxuGlobalInstances, oxuEntity, oxuScene, oxuWorld, oxuSceneLoader, oxuSceneClone, oxuSerialization;

IMPLEMENTATION

procedure start();
var
   timer: TTimerData;
   original: oxTScene;
   ok: boolean = false;
   scene: oxTScene = nil;

begin
   if(oxExternalGlobalInstances <> nil) then begin
      TTimerData.Init(timer);
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
         log.i('Loaded scene (lib, elapsed: ' + sf(timer.Elapsedf(), 3) + '): ' + oxScene.Name)
      else
         log.i('Failed to load scene (lib, elapsed: ' + sf(timer.Elapsedf(), 3) + '): ' + oxScene.Name)
   end;
end;

INITIALIZATION
   ox.OnLoad.Add(@start);

END.
