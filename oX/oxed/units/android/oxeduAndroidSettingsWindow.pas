{
   oxeduAndroidSettingsWindow, oxed android settings window
   Copyright (C) 2019. Dejan Boras

   Started On:    17.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettingsWindow;

INTERFACE

   USES
      {ox}
      oxuTypes, oxuRunRoutines,
      {widgets}
      uiuWidget, uiWidgets,
      wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel,
      {oxed}
      uOXED, oxeduAndroidSettings, oxeduProjectSettingsWindow;

IMPLEMENTATION

VAR
   wdg: record
      PackageName: wdgTInputBox;
   end;

procedure saveCallback();
begin
   oxedAndroidSettings.PackageName := wdg.PackageName.GetText();
end;

procedure revertCallback();
begin
   wdg.PackageName.SetText(oxedAndroidSettings.PackageName);
end;

procedure InitSettings();
begin
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
end;

procedure PreAddTabs();
begin
   oxedwndProjectSettings.Tabs.AddTab('Android', 'android');

   wdgDivisor.Add('Android settings', oxPoint(wdgDEFAULT_SPACING, oxedwndProjectSettings.Tabs.GetHeight() - wdgDEFAULT_SPACING));

   wdgLabel.Add('Package name');
   wdg.PackageName := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);
end;

procedure init();
begin
   oxedwndProjectSettings.OnInit.Add(@InitSettings);
   oxedwndProjectSettings.PostAddTabs.Add(@PreAddTabs);
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.iAdd(oxedInitRoutines, 'settings', @init);

END.
