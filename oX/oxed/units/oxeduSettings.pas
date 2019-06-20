{
   oxeduSettings, oxed settings
   Copyright (C) 2017. Dejan Boras

   Started On:    23.01.2017.
}

{$INCLUDE oxdefines.inc}
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
      CameraAngleSpeed: single;
      {enable centering the pointer when moving the pointer}
      PointerCenterEnable,
      {clear messages on project start}
      ClearMessagesOnStart,
      {focus game view on start}
      FocusGameViewOnStart,
      {run a build on project open}
      BuildOnProjectOpen,
      {require rebuild when a project is opened}
      RequireRebuildOnOpen,
      {handle library errors}
      HandleLibraryErrors,
      {start OXED with last open project}
      StartWithLastProject: boolean;

      {line ending type}
      LineEndings: string;

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
   dvPointerCenterEnable,
   dvClearMessagesOnStart,
   dvFocusGameViewOnStart,
   dvLineEndings,
   dvBuildOnProjectOpen,
   dvRequireRebuildOnOpen,
   dvHandleLibraryErrors,
   dvStartWithLastProject: TDVar;

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
   oxedSettings.StartWithLastProject := true;
   oxedSettings.PointerCenterEnable := true;
   oxedSettings.ClearMessagesOnStart := true;
   oxedSettings.FocusGameViewOnStart := true;
   oxedSettings.RequireRebuildOnOpen := true;
   oxedSettings.HandleLibraryErrors := true;
   oxedSettings.StartWithLastProject := true;

   dvgOXED.Add(dvCameraSpeed, 'camera_speed', dtcSINGLE, @oxedSettings.CameraSpeed);
   dvgOXED.Add(dvCameraAngleSpeed, 'camera_angle_speed', dtcSINGLE, @oxedSettings.CameraAngleSpeed);
   dvgOXED.Add(dvPointerCenterEnable, 'pointer_center_enable', dtcBOOL, @oxedSettings.PointerCenterEnable);
   dvgOXED.Add(dvClearMessagesOnStart, 'clear_messages_on_start', dtcBOOL, @oxedSettings.ClearMessagesOnStart);
   dvgOXED.Add(dvFocusGameViewOnStart, 'focus_game_view_on_start', dtcBOOL, @oxedSettings.FocusGameViewOnStart);
   dvgOXED.Add(dvLineEndings, 'line_endings', dtcSTRING, @oxedSettings.LineEndings);
   dvgOXED.Add(dvBuildOnProjectOpen, 'build_on_project_open', dtcBOOL, @oxedSettings.BuildOnProjectOpen);
   dvgOXED.Add(dvRequireRebuildOnOpen, 'require_rebuild_on_open', dtcBOOL, @oxedSettings.RequireRebuildOnOpen);
   dvgOXED.Add(dvHandleLibraryErrors, 'handle_library_errors', dtcBOOL, @oxedSettings.HandleLibraryErrors);
   dvgOXED.Add(dvStartWithLastProject, 'start_with_last_open_project', dtcBOOL, @oxedSettings.StartWithLastProject);

   dvgOXED.Add('debug', dvgDebug);
   dvgDebug.Add(dvDebugRenderSelectorBBox, 'render_selector_bbox', dtcBOOL, @oxedSettings.Debug.RenderSelectorBBox);

   oxedSettings.LineEndings := 'lf';

END.
