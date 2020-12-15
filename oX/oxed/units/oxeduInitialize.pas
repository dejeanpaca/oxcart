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
      {thingies}
      oxeduThingies,
      {build}
      oxeduBuild, oxeduBuildEditor,
      oxeduBuildAssetsCopy,
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
      {$IFDEF WINDOWS}
      oxeduWindowsPlatform,
      {$ENDIF}
      {$IFDEF LINUX}
      oxeduLinuxPlatform,
      {$ENDIF}
      {android}
      oxeduAndroidPlatform,
      oxeduAndroidSettingsFile,
      {$IFNDEF NO_UI}
      {base ui}
      oxeduRecents, oxeduwndSplash, oxeduSplashScreen, oxeduIcons,
      {windows}
      oxuwndBuildSettings, oxuwndAbout,
      oxeduMenubar, oxeduMenubarBuild,
      oxeduWorkbar, oxeduStatusbar, oxeduDockableArea, oxeduMenuToolbar,
      oxeduTasksUI, oxeduProjectContextMenu,
      oxeduwndProjectSettings, oxeduwndPackagesSettings,
      oxeduViewScene, oxeduSceneView, oxeduProjectDialog, oxeduSceneEditTools,
      oxeduRunButtons, oxeduStatusInfo, oxeduwndSettings,
      oxeduwndProjectFeatures, oxeduwndProjectStatistics,
      oxeduProjectActions, oxeduEntityMenubar,
      {ui}
      oxeduWindowTitle, oxeduProjectNotification,
      oxuStandardFilePreviewers, oxeduSceneScreenshot, oxeduPreviewGenerator,
      oxeduiBuildOutput,
      oxeduPluginsUI,
      oxeduProjectTerminal,
      oxeduwndCompilerSettings,
      {inspectors}
      oxeduGenericFileInspector,
      {platforms}
      oxeduwndAndroidSettings, oxeduwndAndroidGeneralSettings,
      oxeduAndroidMenu,
      {vcs}
      oxeduGit,
      {ypk}
      oxeduYPK,
      {initialize keys last}
      oxeduKeys,
      {$ENDIF}
      {plugins}
      {$INCLUDE ../plugins/oxed_plugins.inc};

IMPLEMENTATION

{$IFNDEF NO_UI}
procedure SetupWorkspace();
begin
   oxedSettings.OnLoad();

   oxedMenubar.Initialize();
   oxedWorkbar.Initialize();
   oxedStatusbar.Initialize();
   oxedDockableArea.Initialize();
end;
{$ENDIF}

procedure initialize();
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

procedure deinitialize();
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
   ox.OnInitialize.Add('oxed.init', @initialize, @deinitialize);
   ox.OnStart.Add('oxed.start', @onStart);

END.
