{
   oxeduwndAndroidGeneralSettings, oxed android general settings window
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndAndroidGeneralSettings;

INTERFACE

   USES
      uStd, StringUtils,
      {ox}
      oxuRunRoutines,
      {widgets}
      oxuwndSettings, oxuwndFileDialog,
      uiWidgets, wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel, wdguButton,
      {oxed}
      uOXED,
      oxeduAndroidSettings;

IMPLEMENTATION

VAR
   wdg: record
      SDKPath,
      NDKPath: wdgTInputBox;
   end;

   dlgSDKPath,
   dlgNDKPath: oxTFileDialog;

procedure openSDKPathCallback(var dialog: oxTFileDialog);
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
   dlgSDKPath.Open();
end;

procedure openNDKPathCallback(var dialog: oxTFileDialog);
var
   path: StdString;

begin
   if(not dialog.Canceled) then begin
      path := IncludeTrailingPathDelimiterNonEmpty(dialog.SelectedFile);

      wdg.NDKPath.SetText(path);
   end;
end;

procedure openNDKPath();
begin
   dlgNDKPath.Open();

   if(oxedAndroidSettings.SDKPath <> '') then
      dlgNDKPath.SetPath(oxedAndroidSettings.SDKPath);
end;

procedure saveCallback();
begin
   oxedAndroidSettings.SDKPath := wdg.SDKPath.GetText();
end;

procedure revertCallback();
begin
   wdg.SDKPath.SetText(oxedAndroidSettings.SDKPath);
end;

procedure PreAddTabs();
begin
   oxwndSettings.Tabs.AddTab('Android', 'android');

   wdgDivisor.Add('SDK Path');
   wdg.SDKPath := wdgInputBox.Add('');
   wdg.SDKPath.SetPlaceholder('SDK Path');

   wdgButton.Add('Find SDK').Callback.Use(@openSDKPath);

   wdgDivisor.Add('NDK Path');
   wdg.NDKPath := wdgInputBox.Add('');
   wdg.NDKPath.SetPlaceholder('NDK Path');

   wdgButton.Add('Find NDK').Callback.Use(@openNDKPath);
end;

procedure init();
begin
   oxwndSettings.OnSave.Add(@saveCallback);
   oxwndSettings.OnRevert.Add(@revertCallback);
   oxwndSettings.PostAddTabs.Add(@PreAddTabs);
end;

INITIALIZATION
   oxed.Init.Add('android.general_settings', @init);

   dlgSDKPath := oxFileDialog.OpenDirectories();
   dlgSDKPath.SetTitle('Find SDK Path');
   dlgSDKPath.Callback := @openSDKPathCallback;

   dlgNDKPath := oxFileDialog.OpenDirectories();
   dlgNDKPath.SetTitle('Find NDK Path');
   dlgNDKPath.Callback := @openNDKPathCallback;

END.
