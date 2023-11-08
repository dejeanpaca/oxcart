{
   oxeduwndAndroidGeneralSettings, oxed android general settings window
   Copyright (C) 2020. Dejan Boras

   Started On:    21.02.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndAndroidGeneralSettings;

INTERFACE

   USES
      uStd, StringUtils,
      {ox}
      oxuRunRoutines, oxuTypes,
      {widgets}
      oxuwndSettings, oxuwndFileDialog,
      uiWidgets, wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel, wdguButton,
      {oxed}
      uOXED,
      oxeduAndroidSettings;

IMPLEMENTATION

VAR
   wdg: record
      SDKPath: wdgTInputBox;
   end;

   dlgSDKPath: oxTFileDialog;

procedure openSDKPathCallback(dialog: oxTFileDialog);
var
   path: StdString;

begin
   if(not dialog.Canceled) then begin
      path := IncludeTrailingPathDelimiterNonEmpty(dialog.SelectedFile);

      wdg.SDKPath.SetText(path);
   end;
end;

procedure openSDKPath();
begin
   if(dlgSDKPath = nil) then begin
      dlgSDKPath := oxFileDialog.OpenDirectories();
      dlgSDKPath.SetTitle('Find SDK Path');
      dlgSDKPath.Callback := @openSDKPathCallback;
   end;

   dlgSDKPath.Open();
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

   wdgButton.Add('Find SDK', uiWidget.LastRect.RightOf(), oxNullDimensions, 0).Callback.Use(@openSDKPath);
end;

procedure init();
begin
   oxwndSettings.OnInit.Add(@InitSettings);
   oxwndSettings.PostAddTabs.Add(@PreAddTabs);
end;

INITIALIZATION
   oxed.Init.Add('android.general_settings', @init);

END.
