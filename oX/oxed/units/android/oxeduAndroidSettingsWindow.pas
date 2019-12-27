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
      oxuRunRoutines,
      {widgets}
      uiWidgets,
      wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel,
      {oxed}
      uOXED,
      oxeduAndroidPlatform, oxeduPlatform,
      oxeduAndroidSettings, oxeduProjectSettingsWindow;

IMPLEMENTATION

VAR
   wdg: record
      PackageName: wdgTInputBox;
      Enabled,
      ManualFileManagement: wdgTCheckbox;
   end;



procedure saveCallback();
var
   p: oxedTAndroidPlatform;

begin
   p := oxedTAndroidPlatform(oxedPlatforms.FindById('android'));

   if(p <> nil) then
      p.Enabled := wdg.Enabled.Checked();

   oxedAndroidSettings.PackageName := wdg.PackageName.GetText();
   oxedAndroidSettings.ManualFileManagement := wdg.ManualFileManagement.Checked();
end;

procedure revertCallback();
var
   p: oxedTAndroidPlatform;

begin
   p := oxedTAndroidPlatform(oxedPlatforms.FindById('android'));

   if(p <> nil) then
      wdg.Enabled.Check(p.Enabled);

   wdg.PackageName.SetText(oxedAndroidSettings.PackageName);
   wdg.ManualFileManagement.Check(oxedAndroidSettings.ManualFileManagement);
end;

procedure InitSettings();
begin
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
end;

procedure PreAddTabs();
var
   p: oxedTAndroidPlatform;

begin
   p := oxedTAndroidPlatform(oxedPlatforms.FindById('android'));

   oxedwndProjectSettings.Tabs.AddTab('Android', 'android');

   wdg.Enabled := wdgCheckbox.Add('Enabled').Check(p.Enabled);

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

INITIALIZATION
   oxed.Init.Add('settings', @init);

END.
