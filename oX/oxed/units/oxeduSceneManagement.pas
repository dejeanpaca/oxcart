{
   oxeduSceneManagement, scene management
   Copyright (C) 2018. Dejan Boras

   Started On:    20.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneManagement;

INTERFACE

   USES
      sysutils, uStd, uLog, udvars, dvaruFile, uFileUtils, appuPaths,
      {ox}
      uOX, oxuScene, oxuPaths,
      {oxed}
      uOXED, oxeduDefaultScene, oxeduProject, oxeduProjectSettings, oxeduProjectSession, oxeduMessages, oxeduProjectManagement,
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
      oxedMessages.i('scene > New');
end;

class procedure oxedTSceneManagement.Save();
begin
   if(oxScene = nil) then
      exit;

   if(oxfScene.Write(oxedProject.ScenePath, oxScene) = 0) then begin
      oxedProject.SetLastScene(oxedProject.ScenePath);
      oxedMessages.i('scene > Wrote ' + oxedProject.ScenePath);
      oxedProject.MarkModified();
   end else
      oxedMessages.e('scene > Failed writing ' + oxedProject.ScenePath);
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
         oxedMessages.i('scene > Loaded: ' + path);
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
   TProcedures.Initialize(oxedSceneManagement.OnNewScene);
   TProcedures.Initialize(oxedSceneManagement.OnSceneOpen);
   TProcedures.Initialize(oxedSceneManagement.OnSceneClosed);
   TProcedures.Initialize(oxedSceneManagement.OnSceneSaved);

   oxedProjectManagement.OnNew.Add(@onProjectCreated);
   oxedProjectManagement.OnOpen.Add(@onProjectOpened);
   oxedProjectManagement.OnClosed.Add(@onProjectClosed);

END.
