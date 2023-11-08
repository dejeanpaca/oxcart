{
   oxeduSettings, oxed settings
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduSettings;

INTERFACE

   USES
      uStd, udvars, uFile,
      uOXED;

TYPE

   { oxedTSettings }

   oxedTSettings = record
      {camera speed, units per second}
      CameraSpeed,
      {camera angle speed, degrees per pixel}
      CameraAngleSpeed,
      {camera scroll speed}
      CameraScrollSpeed: single;
      {enable centering the pointer when moving the pointer}
      PointerCenterEnable,
      {clear console on project start}
      ClearConsoleOnStart,
      {focus game view on start}
      FocusGameViewOnStart,
      {run a build on project open}
      BuildOnProjectOpen,
      {require rebuild when a project is opened}
      RequireRebuildOnOpen,
      {handle library errors}
      HandleLibraryErrors,
      {start OXED with last open project}
      StartWithLastProject,
      {show build output in the console window}
      ShowBuildOutput,
      {show various toast notifications}
      ShowNotifications,
      {focus console window when build starts}
      FocusConsoleOnBuild: boolean;

      {line ending type}
      LineEndings: StdString;

      Debug: record
         RenderSelectorBBox: boolean;
      end;

      procedure OnLoad();
   end;

VAR
   oxedSettings: oxedTSettings;

IMPLEMENTATION

VAR
   dvCameraSpeed,
   dvCameraAngleSpeed,
   dvCameraScrollSpeed,
   dvPointerCenterEnable,
   dvClearConsoleOnStart,
   dvFocusGameViewOnStart,
   dvLineEndings,
   dvBuildOnProjectOpen,
   dvRequireRebuildOnOpen,
   dvHandleLibraryErrors,
   dvStartWithLastProject,
   dvShowBuildOutput,
   dvShowNotifications,
   dvFocusConsoleOnBuild: TDVar;

   dvgDebug: TDVarGroup;
   dvDebugRenderSelectorBBox: TDvar;

{ oxedTSettings }

procedure oxedTSettings.OnLoad();
begin
   {fix unknown line ending setting}
   if(LineEndings <> 'crlf') and (LineEndings <> 'lf') then
      LineEndings := 'lf';

   LineEndings := lowercase(LineEndings);
   fFile.LineEndings := TLineEndingType.GetFromName(LineEndings);
end;

INITIALIZATION
   oxedSettings.CameraSpeed := 5;
   oxedSettings.CameraAngleSpeed := 5;
   oxedSettings.CameraScrollSpeed := 0.5;
   oxedSettings.StartWithLastProject := true;
   oxedSettings.PointerCenterEnable := true;
   oxedSettings.ClearConsoleOnStart := true;
   oxedSettings.FocusGameViewOnStart := true;
   oxedSettings.RequireRebuildOnOpen := true;
   oxedSettings.HandleLibraryErrors := true;
   oxedSettings.StartWithLastProject := true;
   oxedSettings.ShowBuildOutput := true;
   oxedSettings.ShowNotifications := true;
   oxedSettings.FocusConsoleOnBuild := true;

   dvgOXED.Add(dvCameraSpeed, 'camera_speed', dtcSINGLE, @oxedSettings.CameraSpeed);
   dvgOXED.Add(dvCameraAngleSpeed, 'camera_angle_speed', dtcSINGLE, @oxedSettings.CameraAngleSpeed);
   dvgOXED.Add(dvCameraScrollSpeed, 'camera_scroll_speed', dtcSINGLE, @oxedSettings.CameraScrollSpeed);
   dvgOXED.Add(dvPointerCenterEnable, 'pointer_center_enable', dtcBOOL, @oxedSettings.PointerCenterEnable);
   dvgOXED.Add(dvClearConsoleOnStart, 'clear_console_on_start', dtcBOOL, @oxedSettings.ClearConsoleOnStart);
   dvgOXED.Add(dvFocusGameViewOnStart, 'focus_game_view_on_start', dtcBOOL, @oxedSettings.FocusGameViewOnStart);
   dvgOXED.Add(dvLineEndings, 'line_endings', dtcSTRING, @oxedSettings.LineEndings);
   dvgOXED.Add(dvBuildOnProjectOpen, 'build_on_project_open', dtcBOOL, @oxedSettings.BuildOnProjectOpen);
   dvgOXED.Add(dvRequireRebuildOnOpen, 'require_rebuild_on_open', dtcBOOL, @oxedSettings.RequireRebuildOnOpen);
   dvgOXED.Add(dvHandleLibraryErrors, 'handle_library_errors', dtcBOOL, @oxedSettings.HandleLibraryErrors);
   dvgOXED.Add(dvStartWithLastProject, 'start_with_last_open_project', dtcBOOL, @oxedSettings.StartWithLastProject);
   dvgOXED.Add(dvShowBuildOutput, 'show_build_output', dtcBOOL, @oxedSettings.ShowBuildOutput);
   dvgOXED.Add(dvShowNotifications, 'show_notifications', dtcBOOL, @oxedSettings.ShowNotifications);
   dvgOXED.Add(dvFocusConsoleOnBuild, 'focus_console_on_build', dtcBOOL, @oxedSettings.FocusConsoleOnBuild);

   dvgOXED.Add('debug', dvgDebug);
   dvgDebug.Add(dvDebugRenderSelectorBBox, 'render_selector_bbox', dtcBOOL, @oxedSettings.Debug.RenderSelectorBBox);

   oxedSettings.LineEndings := 'lf';

END.
