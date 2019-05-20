{
   oxeduProjectManagement, project management for oxed
   Copyright (C) 2017. Dejan Boras

   Started On:    04.05.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectManagement;

INTERFACE

   USES
      sysutils, uStd, uLog, uFileUtils,
      {app}
      appuPaths, appuActionEvents,
      {ox}
      uOX,
      {oxed}
      uOXED, oxeduSettings, oxeduProject, oxeduProjectSettings, oxeduProjectSession, oxeduMessages, oxeduActions;

TYPE
   { oxedTProjectManagement }

   oxedTProjectManagement = record
      Current: oxedTProject;

      {called when a new project is created}
      OnNew,
      {called when the project is open}
      OnOpen,
      {called when the project is closed}
      OnClosed,
      {called when the project is saved}
      OnSaved,
      {called when a project is overwritten (after save)}
      OnOverwritten: TProcedures;

      {destroy current project}
      procedure Destroy();
      {create a new project}
      class procedure New(); static;
      {save current project}
      class procedure Save(); static;
      {open project from file}
      function Open(const path: string): boolean;
   end;

VAR
   oxedProjectManagement: oxedTProjectManagement;

IMPLEMENTATION

{ oxedTProjectManagement }

procedure oxedTProjectManagement.Destroy();
begin
   if(oxedProject <> nil) then begin
      FreeObject(oxedProject);

      OnClosed.Call();
      SetCurrentDir(appPath.GetExecutablePath());

      log.i('project > Destroyed current project');
   end;
end;

class procedure oxedTProjectManagement.New();
begin
   oxedProjectManagement.Destroy();

   oxedProject := oxedTProject.Create();
   oxedProjectManagement.Current := oxedProject;

   oxedProjectManagement.OnNew.Call();

   if(ox.Started) then
      oxedMessages.i('project > New');
end;

class procedure oxedTProjectManagement.Save();
begin
   if(oxedProject = nil) then
      exit;

   if(not FileUtils.DirectoryExists(oxedProject.ConfigPath)) then begin
      if(not CreateDir(oxedProject.ConfigPath)) then begin
         oxedMessages.e('Failed to create directory: ' + oxedProject.ConfigPath);
         exit;
      end;
   end;

   SetCurrentDir(oxedProject.Path);

   oxedProjectSettings.Save();
   log.v('project > Saved settings: ' + oxedProject.Name);
   oxedProjectSession.Save();
   log.v('project > Saved session: ' + oxedProject.Name);
   oxedProjectManagement.OnSaved.Call();
   log.v('project > On saved called: ' + oxedProject.Name);

   oxedProject.MarkModified(false);
   log.v('project > On modified called: ' + oxedProject.Name);

   oxedMessages.i('project > Saved: ' + oxedProject.Path);
end;

function oxedTProjectManagement.Open(const path: string): boolean;
var
   fn: string;

procedure CannotOpen(const message: string);
begin
   oxed.ErrorMessage('Cannot open project ', 'Cannot open project at: ' + fn + #13#13 + message);
   log.e('project > ' + message);
end;

begin
   fn := IncludeTrailingPathDelimiter(path);

   if(FileUtils.DirectoryExists(fn)) then begin
      log.i('project > Opening from: ' + fn);

      {check if the project exists}
      if(FileUtils.DirectoryExists(fn + oxPROJECT_DIRECTORY)) then begin
         New();
         oxedProject.MarkModified(false);

         oxedMessages.Clear();
         oxedProject.SetPath(fn);

         SetCurrentDir(fn);

         {TODO: Check if project settings loaded properly}
         oxedProjectSettings.Load();
         log.v('project > Loaded settings: ' + oxedProject.Name);
         oxedProjectSession.Load();
         log.v('project > Loaded session: ' + oxedProject.Name);
         oxedProject.RecreateTempDirectory();

         OnOpen.Call();
         oxedMessages.i('project > Loaded: ' + oxedProject.Name + ' (' + oxedProject.Identifier + ')');

         if(oxedSettings.BuildOnProjectOpen) then
            appActionEvents.Queue(oxedActions.BUILD);

         exit(True);
      end else
         CannotOpen('Project doesn''t seem like an oX project. (Missing ' + oxPROJECT_DIRECTORY + ' directory)');
   end else
      CannotOpen('Path not found: ' + fn);

   Result := false;
end;

INITIALIZATION
   TProcedures.Initialize(oxedProjectManagement.OnNew);
   TProcedures.Initialize(oxedProjectManagement.OnOpen);
   TProcedures.Initialize(oxedProjectManagement.OnClosed);
   TProcedures.Initialize(oxedProjectManagement.OnSaved);
   TProcedures.Initialize(oxedProjectManagement.OnOverwritten);

END.
