{
   oxeduwndAndroidSettings, oxed android settings window
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndAndroidSettings;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {widgets}
      uiWidgets, uiuWidget,
      wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel, wdguButton,
      {oxed}
      uOXED, oxeduPlatform, oxeduProject,
      oxeduAndroidPlatform,  oxeduAndroidSettings, oxeduAndroidProjectFiles,
      oxeduProjectSettingsWindow;

IMPLEMENTATION

VAR
   wdg: record
      PackageName,
      ProjectFilesPath: wdgTInputBox;
      Enabled,
      ManualFileManagement: wdgTCheckbox;
      DeployTemplate: wdgTButton;
   end;

procedure deployTemplate();
var
   path: StdString;

begin
   path := '';

   if(wdg.ManualFileManagement.Checked()) then begin
      path := wdg.ProjectFilesPath.GetText();
   end;

   if(path = '') then begin
      path := oxedProject.Path + 'android';
      wdg.ProjectFilesPath.SetText('android');
   end;

   oxedAndroidProjectFiles.Deploy(path);
end;

procedure saveCallback();
var
   p: oxedTAndroidPlatform;

begin
   p := oxedTAndroidPlatform(oxedPlatforms.FindById('android'));

   if(p <> nil) then
      p.Enabled := wdg.Enabled.Checked();

   oxedAndroidSettings.Project.PackageName := wdg.PackageName.GetText();
   oxedAndroidSettings.Project.ManualFileManagement := wdg.ManualFileManagement.Checked();
   oxedAndroidSettings.Project.ProjectFilesPath := wdg.ProjectFilesPath.GetText();
end;

procedure revertCallback();
var
   p: oxedTAndroidPlatform;

begin
   p := oxedTAndroidPlatform(oxedPlatforms.FindById('android'));

   if(p <> nil) then
      wdg.Enabled.Check(p.Enabled);

   wdg.PackageName.SetText(oxedAndroidSettings.Project.PackageName);
   wdg.ManualFileManagement.Check(oxedAndroidSettings.Project.ManualFileManagement);
   wdg.ProjectFilesPath.SetText(oxedAndroidSettings.Project.ProjectFilesPath);
   wdg.ProjectFilesPath.Enable(wdg.ManualFileManagement.Checked());
end;

procedure InitSettings();
begin
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
end;

function manualFileManagementControl(cb: uiTWidget; what: loopint): loopint;
var
   enabled: boolean;

begin
   Result := -1;

   if(what = wdgcCHECKBOX_TOGGLE) then begin
      enabled := wdgTCheckbox(cb).Checked();

      wdg.ProjectFilesPath.Enable(enabled);
      wdg.DeployTemplate.Enable(enabled);
   end;
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
      Check(oxedAndroidSettings.Project.ManualFileManagement);
   wdg.ManualFileManagement.SetControlMethod(@manualFileManagementControl);

   wdgLabel.Add('Path for the android project files (only if manual file management is enabled)');
   wdg.ProjectFilesPath := wdgInputBox.Add('');

   wdg.DeployTemplate := wdgButton.Add('Add android files to project').UseCallback(@deployTemplate);

   revertCallback();
end;

procedure init();
begin
   oxedwndProjectSettings.OnInit.Add(@InitSettings);
   oxedwndProjectSettings.PostAddTabs.Add(@PreAddTabs);
end;

INITIALIZATION
   oxed.Init.Add('android.settings', @init);

END.
