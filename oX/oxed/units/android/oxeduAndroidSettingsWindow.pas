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
      uiWidgets,
      wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel,
      {oxed}
      uOXED, oxeduAndroidSettings, oxeduProjectSettingsWindow;

IMPLEMENTATION

VAR
   wdg: record
      PackageName: wdgTInputBox;
      Enabled,
      ManualFileManagement: wdgTCheckbox;
   end;

procedure saveCallback();
begin
   oxedAndroidSettings.PackageName := wdg.PackageName.GetText();
   oxedAndroidSettings.Enabled := wdg.Enabled.Checked();
   oxedAndroidSettings.ManualFileManagement := wdg.ManualFileManagement.Checked();
end;

procedure revertCallback();
begin
   wdg.PackageName.SetText(oxedAndroidSettings.PackageName);
   wdg.Enabled.Check(oxedAndroidSettings.Enabled);
   wdg.ManualFileManagement.Check(oxedAndroidSettings.ManualFileManagement);
end;

procedure InitSettings();
begin
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
end;

procedure PreAddTabs();
begin
   oxedwndProjectSettings.Tabs.AddTab('Android', 'android');

   wdg.Enabled := wdgCheckbox.Add('Enabled').
      Check(oxedAndroidSettings.Enabled);

   wdgDivisor.Add('Android settings');

   wdgLabel.Add('Package name');
   wdg.PackageName := wdgInputBox.Add('');

   uiWidget.LastRect.GoBelow();

   wdg.ManualFileManagement := wdgCheckbox.Add('Manual file management (aka do it yourself)').
      Check(oxedAndroidSettings.ManualFileManagement);
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
