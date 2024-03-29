{
   uOXED, oxed base unit
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uOXED;

INTERFACE

   USES
      uStd, uLog, udvars, uApp, appuPaths, StringUtils,
      {ox}
      oxuRunRoutines, oxuEntity,
      {ui}
      uiuDockableWindow, uiuMessageBox, uiuTypes;

CONST
   {project main directory}
   oxPROJECT_DIRECTORY = '.oxproject';
   {project temporary directory}
   oxPROJECT_TEMP_DIRECTORY = '.oxtemp';
   {project session directory}
   oxPROJECT_SESSION_DIRECTORY = '.oxsession';
   {project main source name}
   oxPROJECT_MAIN_SOURCE = 'project.pas';
   {project library name}
   oxPROJECT_LIBRARY_NAME = 'project';
   {project library source name}
   oxPROJECT_LIB_SOURCE = 'project.pas';
   {editor library source name}
   oxPROJECT_EDITOR_LIB_SOURCE = 'editor.pas';

   {oxed project organization while running in the editor}
   oxedPROJECT_ORGANIZATION = 'oxed_projects';

   {app information include source name}
   oxPROJECT_APP_INFO_INCLUDE = 'appinfo.inc';

   {project main lpi name}
   oxPROJECT_MAIN_LPI = 'project.lpi';
   {project fpc config name}
   oxPROJECT_MAIN_FPC_CFG = 'project.fpc.cfg';
   {project library lpi name}
   oxPROJECT_LIB_LPI = 'project.lpi';
   {project lib fpc config name}
   oxPROJECT_LIB_FPC_CFG = 'project.fpc.cfg';
   {editor library lpi name}
   oxPROJECT_EDITOR_LIB_LPI =  'editor.lpi';

   {window title used when a project is loaded}
   oxedPROJECT_WINDOW_TITLE  = 'OXED';

TYPE
   {function that returns an entity}
   oxedTEntityFunction = function(): oxTEntity;
   {routine called when an entity is added or removed}
   oxedTEntityAddRemoveRoutine = procedure(parent, entity: oxTEntity);
   {list of routines to be called when an entity is added or removed}
   oxedTEntityAddRemoveList = specialize TSimpleList<oxedTEntityAddRemoveRoutine>;

   { oxedTEntityAddRemoveListHelper }

   oxedTEntityAddRemoveListHelper = record helper for oxedTEntityAddRemoveList
      procedure Call(current, entity: oxTEntity);
   end;

   { oxedTGlobal }

   oxedTGlobal = record
      {routines called when scene is changed}
      OnSceneChange: TProcedures;

      {initialization/deinitialization routines for OXED}
      Init,
      PostInit: oxTRunRoutines;
      {dockable area into which windows are created by default}
      DockableArea: uiTDockableWindow;

      Initialized,
      Deinitializing,
      {is heap trace used when building OXED}
      UseHeapTrace,
      {is cmem used when building OXED}
      UseCMEM: boolean;

      {show an error messsage}
      class procedure ErrorMessage(const title, message: string); static;
      class procedure OpenConfigDirectory(); static;
      class procedure OpenLogs(); static;
   end;

VAR
   oxed: oxedTGlobal;
   dvgOXED: TDvarGroup;

IMPLEMENTATION

class procedure oxedTGlobal.ErrorMessage(const title, message: string);
begin
   uiMessageBox.Show(title, message, uimbsWARNING, uimbcOK, uimbpSURFACE);
end;

class procedure oxedTGlobal.OpenConfigDirectory();
begin
   app.OpenFileManager(appPath.Configuration.Path);
end;

class procedure oxedTGlobal.OpenLogs();
begin
   app.OpenFileManager(ExtractFilePath(stdlog.FileName));
end;

{ oxedTEntityAddRemoveListHelper }

procedure oxedTEntityAddRemoveListHelper.Call(current, entity: oxTEntity);
var
   i: longint;

begin
   for i := 0 to (n - 1) do begin
      List[i](current, entity);
   end;
end;

INITIALIZATION
   dvar.Add('oxed', dvgOXED);

   oxTRunRoutines.Initialize(oxed.Init, 'oxed.Init');
   oxTRunRoutines.Initialize(oxed.PostInit, 'oxed.PostInit');

   TProcedures.InitializeValues(oxed.OnSceneChange);

END.
