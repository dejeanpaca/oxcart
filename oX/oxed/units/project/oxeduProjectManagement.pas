{
   oxeduProjectManagement, project management for oxed
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectManagement;

INTERFACE

   USES
      sysutils, uStd, uLog, uFileUtils,
      {app}
      appuPaths, appuActionEvents,
      {ox}
      uOX,
      {oxed}
      uOXED, oxeduSettings, oxeduProject, oxeduProjectSettings, oxeduProjectSession, oxeduConsole, oxeduActions;

TYPE
   { oxedTProjectManagement }

   oxedTProjectManagement = record
      Current: oxedTProject;

      {called when a new project is created}
      OnNew,
      {called when the project is open}
      OnPreOpen,
      {called when the project is open}
      OnOpen,
      {called before the project is closed}
      OnClose,
      {called when the project is closed}
      OnClosed,
      {called when the project is saved}
      OnSaved,
      {called when a project is overwritten (after save)}
      OnOverwritten,
      {called when the project is being loaded}
      OnLoadProject,
      {called when the project is done being loaded}
      OnLoadedProject,
      {called when the project is being saved}
      OnSaveProject: TProcedures;

      {destroy current project}
      procedure Destroy();
      {create a new project}
      procedure New();
      {save current project}
      procedure Save();
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
      OnClose.Call();

      FreeObject(oxedProject);

      OnClosed.Call();
      SetCurrentDir(appPath.GetExecutablePath());

      log.i('project > Destroyed current project');
   end;
end;

procedure oxedTProjectManagement.New();
begin
   Destroy();

   oxedProject := oxedTProject.Create();
   Current := oxedProject;

   OnNew.Call();

   if(ox.Started) then
      oxedConsole.i('project > New');
end;

procedure oxedTProjectManagement.Save();
begin
   if(oxedProject = nil) then
      exit;

   if(not FileUtils.DirectoryExists(oxedProject.ConfigPath)) then begin
      if(not CreateDir(oxedProject.ConfigPath)) then begin
         oxedConsole.e('Failed to create directory: ' + oxedProject.ConfigPath);
         exit;
      end;

      {$IFDEF WINDOWS}
      FileUtils.HideFile(oxedProject.ConfigPath);
      {$ENDIF}
   end;

   oxedProject.RecreateSessionDirectory();

   SetCurrentDir(oxedProject.Path);

   log.v('project > Saving: ' + oxedProject.Name);

   oxedProjectSettingsFile.Save();
   log.v('project > Saved settings');
   oxedProjectSessionFile.Save();
   log.v('project > Saved session');

   {save other project data}
   OnSaveProject.Call();
   log.v('project > Saved data');

   OnSaved.Call();
   log.v('project > On saved called');

   oxedProject.MarkModified(false);
   log.v('project > On modified(false) called');

   oxedConsole.i('project > Saved: ' + oxedProject.Path);
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

      {prevent opening the same project}
      if(oxedProject <> nil) and (fn = oxedProject.Path) then begin
         oxedConsole.i('Project already open');
         exit(true);
      end;

      {check if the project exists}
      if(FileUtils.DirectoryExists(fn + oxPROJECT_DIRECTORY)) then begin
         New();
         oxedProject.MarkModified(false);

         oxedConsole.Clear();
         oxedProject.SetPath(fn);

         SetCurrentDir(fn);

         {call any methods for setting up the new project}
         OnPreOpen.Call();

         {TODO: Check if project settings loaded properly}
         log.v('project > Loading settings from ' + oxedProjectSettingsFile.GetFn());
         oxedProjectSettingsFile.Load();
         log.v('project > Loading: ' + oxedProject.Name);

         oxedProjectSessionFile.Load();
         log.v('project > Loaded session');
         oxedProject.RecreateSessionDirectory();

         oxedProject.RecreateTempDirectory();

         {load other project data}
         OnLoadProject.Call();
         log.v('project > Loaded');

         OnOpen.Call();
         oxedConsole.i('project > Opened ' + oxedProject.Name + ' (' + oxedProject.Identifier + ')');

         OnLoadedProject.Call();

         if(oxedSettings.BuildOnProjectOpen) then
            appActionEvents.Queue(oxedActions.REBUILD);

         exit(True);
      end else
         CannotOpen('Project doesn''t seem like an oX project. (Missing ' + oxPROJECT_DIRECTORY + ' directory)');
   end else
      CannotOpen('Path not found: ' + fn);

   Result := false;
end;

procedure deinit();
begin
   oxedProjectManagement.Destroy();
end;

INITIALIZATION
   TProcedures.InitializeValues(oxedProjectManagement.OnNew);
   TProcedures.InitializeValues(oxedProjectManagement.OnPreOpen);
   TProcedures.InitializeValues(oxedProjectManagement.OnOpen);
   TProcedures.InitializeValues(oxedProjectManagement.OnClose);
   TProcedures.InitializeValues(oxedProjectManagement.OnClosed);
   TProcedures.InitializeValues(oxedProjectManagement.OnSaved);
   TProcedures.InitializeValues(oxedProjectManagement.OnOverwritten);
   TProcedures.InitializeValues(oxedProjectManagement.OnLoadProject);
   TProcedures.InitializeValues(oxedProjectManagement.OnLoadedProject);
   TProcedures.InitializeValues(oxedProjectManagement.OnSaveProject);

   oxed.Init.dAdd('project_management', @deinit);

END.
