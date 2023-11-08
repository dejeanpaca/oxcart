{
   oxeduInitialize, oxed initialization
   Copyright (C) 2017. Dejan Boras

   Started On:    11.04.2017.
}

{$INCLUDE ../plugins/oxed_default_plugins.inc}

{$INCLUDE oxdefines.inc}
UNIT oxeduInitialize;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      uOX, oxuPaths, oxuRunRoutines,
      {oxed}
      uOXED, oxeduSettings, oxeduRecents,
      oxeduWindow, oxeduSplash, oxeduSplashScreen, oxeduIcons,
      oxeduEntities,
      {build}
      oxeduBuild,
      oxeduPlatform,
      oxeduProjectPlatforms,
      oxeduProjectRunner, oxeduSceneClone,
      oxeduProjectScanner, oxeduPasScanner, oxeduStatisticsScanner,
      {additional}
      oxeduBuildEvents, oxeduLazarus,
      {windows}
      oxeduMenubar, oxeduProjectManagement, oxeduMessages,
      oxuwndBuildSettings,
      oxeduToolbar, oxeduWorkbar, oxeduStatusbar, oxeduDockableArea, oxeduMenuToolbar,
      oxeduTasksUI, oxeduProjectContextMenu, oxeduProjectSettingsWindow,
      oxeduViewScene, oxeduSceneView, oxeduProjectDialog, oxeduSceneEditTools,
      oxeduRunButtons, oxeduStatusInfo, oxeduSettingsWindow,
      oxeduProjectFeaturesWindow, oxeduProjectStatisticsWindow,
      {components}
      oxeduCameraComponent, oxeduLightComponent,
      {initialize keys last}
      oxeduKeys,
      {ui}
      oxeduWindowTitle, oxeduProjectNotification,
      oxuStandardFilePreviewers, oxeduSceneScreenshot, oxeduPreviewGenerator,
      oxeduiBuildOutput,
      {editor}
      oxeduEditorPlatform,
      {windows}
      oxeduWindowsPlatform,
      {linux}
      oxeduLinuxPlatform,
      {android}
      oxeduAndroidPlatform, oxeduAndroidSettingsWindow,
      {plugins}
      oxeduPluginsUI
      {$INCLUDE ../plugins/oxed_plugins.inc};

procedure oxedInitialize();
procedure oxedDeinitialize();

IMPLEMENTATION

procedure SetupWorkspace();
begin
   oxedSettings.OnLoad();
   oxedKeyMappings.Initialize();

   oxedMenubar.Initialize();
   oxedWorkbar.Initialize();
   oxedStatusbar.Initialize();
   oxedToolbar.Initialize();
   oxedDockableArea.Initialize();

   if(oxPaths.List.n = 0) then
      oxedMessages.w('oX asset path doesn''t seem set (set ' + OX_ASSET_PATH_ENV + ' environment variable or config)');

   {open a project}
   if(oxedSettings.StartWithLastProject) and (oxedRecents.LastOpen <> '') then begin
      log.v('project > Opening last opened project: ' + oxedRecents.LastOpen);

      if(not oxedProjectManagement.Open(oxedRecents.LastOpen)) then
         {failed to open last open project, so clear it}
         oxedRecents.LastOpen := '';
   end;

   oxed.Initialized := true;
end;

procedure oxedInitialize();
begin
   oxedMenubar.Deinitialize();
   oxed.Init.iCall();
   oxedPlatforms.Initialize();

   {setup default workspace}
   SetupWorkspace();

   oxed.PostInit.iCall();
end;

procedure oxedDeInitialize();
begin
   oxed.Deinitializing := true;

   oxedProjectRunner.Stop();

   oxedProjectManagement.Destroy();

   oxedPlatforms.DeInitialize();
   oxed.PostInit.dCall();
   oxed.Init.dCall();
end;

INITIALIZATION
   ox.OnInitialize.Add('oxed.init', @oxedInitialize, @oxedDeInitialize);

END.
