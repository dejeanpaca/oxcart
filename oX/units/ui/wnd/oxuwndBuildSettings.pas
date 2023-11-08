{
   oxuwndBuildSettings, oX build settings window
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuwndBuildSettings;

INTERFACE

   USES
      uStd, StringUtils,
      {build}
      uFPCHelpers, uBuild, uBuildInstalls,
      {app}
      uApp,
      {ox}
      uOX, oxuTypes, oxuRunRoutines, oxuwndSettings,
      {ui}
      uiWidgets, wdguLabel, wdguInputBox, wdguButton, wdguDropDownList, wdguDivisor;


IMPLEMENTATION

VAR
   wdg: record
      ConfigPath: wdgTInputBox;
   end;

procedure reloadBuildConfiguration();
begin
   build.ReInitialize();
end;

procedure openBuildPath();
begin
   app.OpenFileManager(build.Tools.Build);
end;

procedure revertSettings();
begin
   wdg.ConfigPath.SetText(build.ConfigPath);
end;

procedure PreAddTabs();
var
   dropDown: wdgTDropDownList;
   i: loopint;
   platform: PBuildPlatform;
   laz: PBuildLazarusInstall;

begin
   oxwndSettings.Tabs.AddTab('Build', 'build');

   wdgLabel.Add('Configuration location');
   wdg.ConfigPath := wdgInputBox.Add('');

   wdgButton.Add('Reload Configuration').Callback.Use(@reloadBuildConfiguration);
   wdgButton.Add('Open build path', uiWidget.LastRect.RightOf(), oxNullDimensions, @openBuildPath);

   uiWidget.LastRect.GoLeft();
   uiWidget.LastRect.GoBelow();

   wdgDivisor.Add('Built with FPC');
   wdgLabel.Add('Version: ' + FPC_VERSION);
   wdgLabel.Add('OS: ' + FPC_TARGETOS);
   wdgLabel.Add('Target: ' + FPC_TARGET);
   wdgLabel.Add('CPU: ' + FPC_TARGETCPU);

   uiWidget.LastRect.GoBelow();

   wdgDivisor.Add('Configuration');
   wdgLabel.Add('Tools path:   ' + build.Tools.Path);
   wdgLabel.Add('Build system: ' + build.Tools.Build);

   wdgLabel.Add('FPC Used:     ' + BuildInstalls.GetPlatform()^.Name);
   wdgLabel.Add('Lazarus Used: ' + BuildInstalls.GetLazarus()^.Name);

   uiWidget.LastRect.GoBelow();

   for i := 0 to BuildInstalls.Platforms.n - 1 do begin
      platform := @BuildInstalls.Platforms.List[i];

      if(i = 0) then
         wdgDivisor.Add('FPC Platform: Default')
      else
         wdgDivisor.Add('FPC Platform: ' + platform^.Name);

      wdgLabel.Add('Version: ' + platform^.Version);
      wdgLabel.Add('Platform: ' + platform^.Platform);
      wdgLabel.Add('Path: ' + platform^.Path);
      wdgLabel.Add('Config Path: ' + platform^.ConfigPath);
   end;

   uiWidget.LastRect.GoBelow();

   for i := 0 to BuildInstalls.Lazarus.n - 1 do begin
      laz := @BuildInstalls.Lazarus.List[i];

      if(i = 0) then
         wdgDivisor.Add('Lazarus: Default')
      else
         wdgDivisor.Add('Lazarus: ' + laz^.Name);

      wdgLabel.Add('Lazarus Path: ' + laz^.Path);
      wdgLabel.Add('Lazarus Config Path: ' + laz^.ConfigPath);
      wdgLabel.Add('Use FPC: ' + laz^.GetFPCName() + ' (found: ' + sf(laz^.FPC <> nil) + ')');
   end;

   uiWidget.LastRect.GoBelow();

   wdgDivisor.Add('Preview');

   wdgLabel.Add('Units');

   dropDown := wdgDropDownList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(480, 20));

   for i := 0 to build.Units.n - 1 do begin
      dropDown.Add(build.Units.List[i]);
   end;

   wdgLabel.Add('Includes');

   dropDown := wdgDropDownList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(480, 20));
   for i := 0 to build.Includes.n - 1 do begin
      dropDown.Add(build.Includes.List[i]);
   end;
end;

procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.PreAddTabs.Add(@PreAddTabs);
end;

INITIALIZATION
   ox.Init.Add('settings', @init);

END.
