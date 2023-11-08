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
      StartWithLastProject: wdgTCheckbox;
   end;

procedure saveCallback();
begin
   oxedSettings.ClearMessagesOnStart := wdg.ClearMessagesOnStart.Checked();
   oxedSettings.FocusGameViewOnStart := wdg.FocusGameViewOnStart.Checked();
   oxedSettings.BuildOnProjectOpen := wdg.BuildOnProjectOpen.Checked();
   oxedSettings.RequireRebuildOnOpen := wdg.RequireRebuildOnOpen.Checked();
   oxedSettings.HandleLibraryErrors := wdg.HandleLibraryErrors.Checked();
   oxedSettings.StartWithLastProject := wdg.StartWithLastProject.Checked();

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
end;

procedure InitSettings();
begin
   oxwndSettings.OnSave.Add(@saveCallback);
   oxwndSettings.OnRevert.Add(@revertCallback);
end;

procedure PreAddTabs();
begin
   oxwndSettings.Tabs.AddTab('Editor', 'editor');

   wdgDivisor.Add('Editor settings', oxPoint(wdgDEFAULT_SPACING, oxwndSettings.Tabs.GetHeight() - wdgDEFAULT_SPACING));

   wdg.UnixLineEndings := wdgCheckbox.Add('Unix (linux) line ending ', uiWidget.LastRect.BelowOf());
   wdg.ClearMessagesOnStart := wdgCheckbox.Add('Clear messages on start ', uiWidget.LastRect.BelowOf());
   wdg.FocusGameViewOnStart := wdgCheckbox.Add('Focus game view on start ', uiWidget.LastRect.BelowOf());

   wdg.BuildOnProjectOpen := wdgCheckbox.Add('Start build immediately on project open', uiWidget.LastRect.BelowOf());
   wdg.BuildOnProjectOpen.SetHint('Starts a rebuild immediately when a project is opened');

   wdg.RequireRebuildOnOpen := wdgCheckbox.Add('Require rebuild on project open', uiWidget.LastRect.BelowOf());
   wdg.RequireRebuildOnOpen.SetHint('To prevent any side-effects, a full rebuild is required when a project is opened to ensure built code matches editor/engine code.'#13'This can be skipped if you want to ensure this is the case yourself.');

   wdg.HandleLibraryErrors := wdgCheckbox.Add('Handle library errors', uiWidget.LastRect.BelowOf());
   wdg.HandleLibraryErrors.SetHint('Editor will handle run-time library errors. If you want to debug editor/project outside (in lazarus) you can disable this.');

   wdg.StartWithLastProject := wdgCheckbox.Add('Start with last opened project', uiWidget.LastRect.BelowOf());
   wdg.StartWithLastProject.SetHint('Starts editor with the last opened project.');
end;

procedure init();
begin
   oxwndSettings.OnInit.Add(@InitSettings);
   oxwndSettings.PreAddTabs.Add(@PreAddTabs);
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.iAdd(oxedInitRoutines, 'settings', @init);

END.

