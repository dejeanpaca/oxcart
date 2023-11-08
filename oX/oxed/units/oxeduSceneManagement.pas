{
   oxeduSceneManagement, scene management
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduSceneManagement;

INTERFACE

   USES
      uStd, uLog, uFileUtils,
      {ox}
      uOX, oxuScene, oxuSceneManagement,
      {oxed}
      uOXED, oxeduDefaultScene, oxeduConsole,
      oxeduProject, oxeduProjectManagement,
      oxuSceneFile;

TYPE
   { oxedTSceneManagement }

   oxedTSceneManagement = record
      {called when a new scene is created}
      OnNewScene,
      {called when the scene is open}
      OnSceneOpen,
      {called when the scene is closed}
      OnSceneClosed,
      {called when the scene is saved}
      OnSceneSaved: TProcedures;

      {destroy current scene}
      class procedure Destroy(); static;
      {create a new project}
      class procedure New(); static;
      {save current project}
      class procedure Save(); static;
      {open scene from file}
      function Open(const path: string): boolean;
   end;

VAR
   oxedSceneManagement: oxedTSceneManagement;

IMPLEMENTATION

{ oxedTSceneManagement }

class procedure oxedTSceneManagement.Destroy();
begin
   if(oxScene <> nil) then begin
      log.i('scene > Destroyed current');

      oxScene.Empty();

      oxedSceneManagement.OnSceneClosed.Call();
   end;
end;

class procedure oxedTSceneManagement.New();
begin
   Destroy();

   oxedProject.ScenePath := '';
   oxedDefaultScene.Create();

   oxedSceneManagement.OnNewScene.Call();

   if(ox.Started) then
      oxedConsole.i('scene > New');
end;

class procedure oxedTSceneManagement.Save();
begin
   if(oxScene = nil) then
      exit;

   if(oxfScene.Write(oxedProject.ScenePath, oxScene) = 0) then begin
      oxedProject.SetLastScene(oxedProject.ScenePath);
      oxedConsole.i('scene > Wrote ' + oxedProject.ScenePath);
      oxedProject.MarkModified();
   end else
      oxedConsole.e('scene > Failed writing ' + oxedProject.ScenePath);
end;

function oxedTSceneManagement.Open(const path: string): boolean;
var
   scene: oxTScene;


begin
   if(FileUtils.Exists(path) > -1) then begin
      log.i('scene > Opening: ' + path);

      scene := oxfScene.Read(path);
      if(scene <> nil) then begin
         FreeObject(oxScene);

         oxSceneManagement.SetScene(scene);
         oxedProject.ScenePath := path;
         oxedConsole.i('scene > Loaded: ' + path);
         exit(true);
      end;

      oxed.ErrorMessage('Scene failed loading', 'Scene failed to load from: ' + path);
      oxedProject.SetLastScene('');
   end else
      oxed.ErrorMessage('Scene file not found', 'Scene file not found at: ' + path);

   Result := false;
end;

procedure onProjectCreated();
begin
   oxedSceneManagement.New();
end;

procedure onProjectClosed();
begin
   oxedSceneManagement.Destroy();
end;

procedure onProjectOpened();
begin
   if(oxedProject.LastScene <> '') then
      oxedSceneManagement.Open(oxedProject.LastScene);
end;

INITIALIZATION
   TProcedures.InitializeValues(oxedSceneManagement.OnNewScene);
   TProcedures.InitializeValues(oxedSceneManagement.OnSceneOpen);
   TProcedures.InitializeValues(oxedSceneManagement.OnSceneClosed);
   TProcedures.InitializeValues(oxedSceneManagement.OnSceneSaved);

   oxedProjectManagement.OnNew.Add(@onProjectCreated);
   oxedProjectManagement.OnOpen.Add(@onProjectOpened);
   oxedProjectManagement.OnClosed.Add(@onProjectClosed);

END.
