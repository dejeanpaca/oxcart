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
      oxuTypes, oxuRunRoutines,
      {widgets}
      uiWidgets, uiuWidget,
      wdguCheckbox, wdguDivisor, wdguInputBox, wdguLabel, wdguButton, wdguDropDownList,
      {oxed}
      uOXED, oxeduPlatform, oxeduProject, oxeduwndProjectSettings,
      oxeduAndroidPlatform,  oxeduAndroidSettings, oxeduAndroidProjectFiles, oxeduAndroid;

IMPLEMENTATION

VAR
   wdg: record
      EmulatorCPUType: wdgTDropDownList;
      PackageName,
      ProjectFilesPath: wdgTInputBox;
      Enabled,
      ManualFileManagement: wdgTCheckbox;
      DeployTemplate: wdgTButton;
   end;

procedure enableAndroidDeployWidgets(enabled: boolean);
begin
   wdg.ProjectFilesPath.Enable(enabled);
   wdg.DeployTemplate.Enable(enabled);
end;

procedure enableAndroidWidgets(enabled: boolean);
begin
   wdg.EmulatorCPUType.Enable(enabled);
   wdg.PackageName.Enable(enabled);
   wdg.ManualFileManagement.Enable(enabled);
   enableAndroidDeployWidgets(enabled and wdg.ManualFileManagement.Checked());
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
   oxedAndroidProjectFiles.UpdateValues(path);
end;

procedure saveCallback();
begin
   oxedAndroidSettings.Project.PackageName := wdg.PackageName.GetText();
   oxedAndroidSettings.Project.ManualFileManagement := wdg.ManualFileManagement.Checked();
   oxedAndroidSettings.Project.ProjectFilesPath := wdg.ProjectFilesPath.GetText();

   oxedPlatforms.Enable(oxedAndroidPlatform, wdg.Enabled.Checked());
end;

procedure revertCallback();
begin
   wdg.Enabled.Check(oxedAndroidPlatform.Enabled);

   wdg.PackageName.SetText(oxedAndroidSettings.Project.PackageName);
   wdg.ManualFileManagement.Check(oxedAndroidSettings.Project.ManualFileManagement);
   wdg.ProjectFilesPath.SetText(oxedAndroidSettings.Project.ProjectFilesPath);
   wdg.ProjectFilesPath.Enable(wdg.ManualFileManagement.Checked());
end;

function enableControl(cb: uiTWidget; what: loopint): loopint;
begin
   Result := -1;

   if(what = wdgcCHECKBOX_TOGGLE) then
      enableAndroidWidgets(wdgTCheckbox(cb).Checked());
end;

function manualFileManagementControl(cb: uiTWidget; what: loopint): loopint;
begin
   Result := -1;

   if(what = wdgcCHECKBOX_TOGGLE) then
      enableAndroidDeployWidgets(wdgTCheckbox(cb).Checked());
end;

procedure addTabs();
var
   i: loopint;

begin
   oxedwndProjectSettings.Tabs.AddTab('Android', 'android');

   wdg.Enabled := wdgCheckbox.Add('Enabled').Check(oxedAndroidPlatform.Enabled);
   wdg.Enabled.SetControlMethod(@enableControl);

   wdgDivisor.Add('Android settings');

   wdgLabel.Add('Package name');
   wdg.PackageName := wdgInputBox.Add('');

   wdgDivisor.Add('Editor build settings');

   wdgLabel.Add('Emulator CPU Type');
   wdg.EmulatorCPUType := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxNullDimensions);

   for i := 0 to high(oxedAndroidCPUTypes) do
      wdg.EmulatorCPUType.Add(oxedAndroidCPUTypes[i]);

   wdg.EmulatorCPUType.AutoSetDimensions(true);

   uiWidget.LastRect.GoBelow();
   uiWidget.LastRect.GoLeft();

   wdgDivisor.Add('File management');

   wdg.ManualFileManagement := wdgCheckbox.Add('Manual file management (aka do it yourself)').
      Check(oxedAndroidSettings.Project.ManualFileManagement);
   wdg.ManualFileManagement.SetControlMethod(@manualFileManagementControl);

   wdgLabel.Add('Path for the android project files (only if manual file management is enabled)');
   wdg.ProjectFilesPath := wdgInputBox.Add('');

   wdg.DeployTemplate := wdgButton.Add('Add android files to project').UseCallback(@deployTemplate);

   enableAndroidWidgets(oxedAndroidPlatform.Enabled);
end;

procedure init();
begin
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
   oxedwndProjectSettings.PostAddTabs.Add(@addTabs);
end;

INITIALIZATION
   oxed.Init.Add('android.settings', @init);

END.
