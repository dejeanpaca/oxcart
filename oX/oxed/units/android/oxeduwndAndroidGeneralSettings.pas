{
   oxeduwndAndroidGeneralSettings, oxed android general settings window
   Copyright (C) 2020. Dejan Boras

   Started On:    21.02.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndAndroidGeneralSettings;

INTERFACE

   USES
      {ox}
      oxuRunRoutines,
      {widgets}
      uiWidgets, wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel,
      {oxed}
      uOXED,
      oxeduAndroidSettings, oxuwndSettings;

IMPLEMENTATION

VAR
   wdg: record
      SDKPath: wdgTInputBox;
   end;


procedure saveCallback();
begin
   oxedAndroidSettings.SDKPath := wdg.SDKPath.GetText();
end;

procedure revertCallback();
begin
   wdg.SDKPath.SetText(oxedAndroidSettings.SDKPath);
end;

procedure InitSettings();
begin
   oxwndSettings.OnSave.Add(@saveCallback);
   oxwndSettings.OnRevert.Add(@revertCallback);
end;

procedure PreAddTabs();
begin
   oxwndSettings.Tabs.AddTab('Android', 'android');

   wdgDivisor.Add('Android settings');

   wdgLabel.Add('SDK Path');
   wdg.SDKPath := wdgInputBox.Add('');
   wdg.SDKPath.SetPlaceholder('SDK Path');
end;

procedure init();
begin
   oxwndSettings.OnInit.Add(@InitSettings);
   oxwndSettings.PostAddTabs.Add(@PreAddTabs);
end;

INITIALIZATION
   oxed.Init.Add('android.general_settings', @init);

END.
