{
   oxeduSettingsWindow, oxed settings window
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSettingsWindow;

INTERFACE

   USES
      {ox}
      oxuTypes, oxuwndSettings, oxuRunRoutines,
      {widgets}
      uiuWidget, uiWidgets,
      wdguCheckbox, wdguDivisor,
      {oxed}
      uOXED, oxeduSettings;

IMPLEMENTATION

VAR
   wdg: record
      UnixLineEndings,
      ClearMessagesOnStart,
      FocusGameViewOnStart,
      BuildOnProjectOpen,
      RequireRebuildOnOpen,
      HandleLibraryErrors,
      StartWithLastProject,
      ShowBuildOutput,
      ShowNotifications: wdgTCheckbox;
   end;

procedure saveCallback();
begin
   oxedSettings.ClearMessagesOnStart := wdg.ClearMessagesOnStart.Checked();
   oxedSettings.FocusGameViewOnStart := wdg.FocusGameViewOnStart.Checked();
   oxedSettings.BuildOnProjectOpen := wdg.BuildOnProjectOpen.Checked();
   oxedSettings.RequireRebuildOnOpen := wdg.RequireRebuildOnOpen.Checked();
   oxedSettings.HandleLibraryErrors := wdg.HandleLibraryErrors.Checked();
   oxedSettings.StartWithLastProject := wdg.StartWithLastProject.Checked();
   oxedSettings.ShowBuildOutput := wdg.ShowBuildOutput.Checked();
   oxedSettings.ShowNotifications := wdg.ShowNotifications.Checked();

   if(wdg.UnixLineEndings.Checked()) then
      oxedSettings.LineEndings := 'lf'
   else
      oxedSettings.LineEndings := 'crlf';
end;

procedure revertCallback();
begin
   wdg.ClearMessagesOnStart.Check(oxedSettings.ClearMessagesOnStart);
   wdg.FocusGameViewOnStart.Check(oxedSettings.FocusGameViewOnStart);
   wdg.BuildOnProjectOpen.Check(oxedSettings.BuildOnProjectOpen);
   wdg.RequireRebuildOnOpen.Check(oxedSettings.RequireRebuildOnOpen);
   wdg.HandleLibraryErrors.Check(oxedSettings.HandleLibraryErrors);
   wdg.UnixLineEndings.Check(oxedSettings.LineEndings = 'lf');
   wdg.StartWithLastProject.Check(oxedSettings.StartWithLastProject);
   wdg.ShowBuildOutput.Check(oxedSettings.ShowBuildOutput);
   wdg.ShowNotifications.Check(oxedSettings.ShowNotifications);
end;

procedure InitSettings();
begin
   oxwndSettings.OnSave.Add(@saveCallback);
   oxwndSettings.OnRevert.Add(@revertCallback);
end;

procedure PreAddTabs();
begin
   oxwndSettings.Tabs.AddTab('Editor', 'editor');

   wdgDivisor.Add('Editor settings');

   wdg.UnixLineEndings := wdgCheckbox.Add('Unix (linux) line ending ');
   wdg.ClearMessagesOnStart := wdgCheckbox.Add('Clear messages on start ');
   wdg.FocusGameViewOnStart := wdgCheckbox.Add('Focus game view on start ');

   wdg.HandleLibraryErrors := wdgCheckbox.Add('Handle library errors');
   wdg.HandleLibraryErrors.
      SetHint('Editor will handle run-time library errors. If you want to debug editor/project outside (in lazarus) you can disable this.');

   wdg.StartWithLastProject := wdgCheckbox.Add('Start with last opened project');
   wdg.StartWithLastProject.SetHint('Starts editor with the last opened project.');

   wdg.ShowNotifications := wdgCheckbox.Add('Show notifications');
   wdg.ShowNotifications.SetHint('Show toast notifications such as Project Opened, Starting Lazarus ....');

   wdgDivisor.Add('Build');

   wdg.BuildOnProjectOpen := wdgCheckbox.Add('Start build immediately on project open');
   wdg.BuildOnProjectOpen.SetHint('Starts a rebuild immediately when a project is opened');

   wdg.RequireRebuildOnOpen := wdgCheckbox.Add('Require rebuild on project open');
   wdg.RequireRebuildOnOpen.SetHint('To prevent any side-effects, a full rebuild is required when a project is opened to ensure built code matches editor/engine code.'#13'This can be skipped if you want to ensure this is the case yourself.');

   wdg.ShowBuildOutput := wdgCheckbox.Add('Show build output in the messages window');
   wdg.ShowBuildOutput.SetHint('Show lazarus and fpc build output in the messages window');
end;

procedure init();
begin
   oxwndSettings.OnInit.Add(@InitSettings);
   oxwndSettings.PreAddTabs.Add(@PreAddTabs);
end;

INITIALIZATION
   oxed.Init.Add('settings', @init);

END.

