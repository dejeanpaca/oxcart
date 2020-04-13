{
   oxeduInitialize, oxed initialization
   Copyright (C) 2017. Dejan Boras
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
      uOXED, oxeduSettings, oxeduEntities,
      {build}
      oxeduBuild,
      oxeduPlatform,
      oxeduProjectPlatforms,
      {$IFNDEF OXED_BUILD}
      oxeduProjectRunner, oxeduSceneClone,
      {$ENDIF}
      oxeduProjectScanner, oxeduPasScanner, oxeduStatisticsScanner,
      oxeduProjectPackages, oxeduProjectPackagesConfiguration,
      {additional}
      oxeduBuildEvents, oxeduLazarus, oxeduConsole, oxeduProjectManagement,
      {components}
      oxeduCameraComponent, oxeduLightComponent, oxeduUIComponent,
      {platforms}
      oxeduEditorPlatform,
      oxeduWindowsPlatform,
      oxeduLinuxPlatform,
      {android}
      oxeduAndroidPlatform,
      oxeduAndroidSettingsFile,
      {$IFNDEF NO_UI}
      {base ui}
      oxeduRecents, oxeduSplash, oxeduSplashScreen, oxeduIcons,
      {windows}
      oxuwndBuildSettings, oxuwndAbout,
      oxeduMenubar, oxeduMenubarBuild,
      oxeduToolbar, oxeduWorkbar, oxeduStatusbar, oxeduDockableArea, oxeduMenuToolbar,
      oxeduTasksUI, oxeduProjectContextMenu,
      oxeduProjectSettingsWindow, oxeduwndPackagesSettings,
      oxeduViewScene, oxeduSceneView, oxeduProjectDialog, oxeduSceneEditTools,
      oxeduRunButtons, oxeduStatusInfo, oxeduSettingsWindow,
      oxeduProjectFeaturesWindow, oxeduProjectStatisticsWindow,
      oxeduProjectActions, oxeduEntityMenubar,
      {initialize keys last}
      oxeduKeys,
      {ui}
      oxeduWindowTitle, oxeduProjectNotification,
      oxuStandardFilePreviewers, oxeduSceneScreenshot, oxeduPreviewGenerator,
      oxeduiBuildOutput,
      oxeduPluginsUI,
      oxeduProjectTerminal,
      {platforms}
      oxeduwndAndroidSettings, oxeduwndAndroidGeneralSettings,
      oxeduAndroidMenu,
      {$ENDIF}
      {plugins}
      {$INCLUDE ../plugins/oxed_plugins.inc};

procedure oxedInitialize();
procedure oxedDeinitialize();

IMPLEMENTATION

{$IFNDEF NO_UI}
procedure SetupWorkspace();
begin
   oxedSettings.OnLoad();
   oxedKeyMappings.Initialize();

   oxedMenubar.Initialize();
   oxedWorkbar.Initialize();
   oxedStatusbar.Initialize();
   oxedToolbar.Initialize();
   oxedDockableArea.Initialize();
end;
{$ENDIF}

procedure oxedInitialize();
begin
   {$IFNDEF NO_UI}
   oxwndAbout.ShowBuiltWith := true;

   oxedMenubar.Deinitialize();
   {$ENDIF}

   oxed.Init.iCall();
   oxedPlatforms.Initialize();

   {$IFNDEF NO_UI}
   {setup default workspace}
   SetupWorkspace();
   {$ENDIF}

   oxed.PostInit.iCall();

   if(oxPaths.List.n = 0) then
      oxedConsole.w('oX asset path doesn''t seem set (set ' + OX_ASSET_PATH_ENV + ' environment variable or config)');

  oxed.Initialized := true;
end;

procedure oxedDeInitialize();
begin
   oxed.Deinitializing := true;

   {$IFNDEF OXED_BUILD}
   oxedProjectRunner.Stop();
   {$ENDIF}

   oxedProjectManagement.Destroy();

   oxedPlatforms.DeInitialize();
   oxed.PostInit.dCall();
   oxed.Init.dCall();
end;

procedure onStart();
begin
   {$IFNDEF NO_UI}
   {open a project}
   if(oxedSettings.StartWithLastProject) and (oxedRecents.LastOpen <> '') then begin
      log.v('project > Opening last opened project: ' + oxedRecents.LastOpen);

      if(not oxedProjectManagement.Open(oxedRecents.LastOpen)) then
         {failed to open last open project, so clear it}
         oxedRecents.LastOpen := '';
   end;
   {$ENDIF}
end;

INITIALIZATION
   ox.OnInitialize.Add('oxed.init', @oxedInitialize, @oxedDeInitialize);
   ox.OnStart.Add('oxed.start', @onStart);

END.
