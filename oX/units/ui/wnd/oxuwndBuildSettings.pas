{
   oxuwndBuildSettings, oX build settings window
   Copyright (C) 2017. Dejan Boras

   Started On:    15.05.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndBuildSettings;

INTERFACE

   USES
      uStd, uBuild, StringUtils,
      {ox}
      uOX, oxuTypes, oxuwndSettings, uApp,
      {ui}
      uiWidgets, wdguLabel, wdguInputBox, wdguButton, wdguDropDownList, wdguDivisor;


IMPLEMENTATION

VAR
   wdg: record
      ConfigPath: wdgTInputBox;
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
   wdg.ConfigPath := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);

   wdgButton.Add('Reload Configuration');
   wdgButton.Add('Open build path', uiWidget.LastRect.RightOf(), oxNullDimensions, @openBuildPath);

   uiWidget.LastRect.GoLeft();

   wdgDivisor.Add('Configuration', uiWidget.LastRect.BelowOf());
   wdgLabel.Add('Tools path:   ' + build.Tools.Path);
   wdgLabel.Add('Build system: ' + build.Tools.Build);
   wdgLabel.Add('Build mode:   ' + build.BuildMode);

   uiWidget.LastRect.GoBelow();

   for i := 0 to build.Platforms.n - 1 do begin
      platform := @build.Platforms.List[i];

      if(i = 0) then
         wdgDivisor.Add('Platform: Default', uiWidget.LastRect.BelowOf())
      else
         wdgDivisor.Add('Platform: ' + platform^.Name, uiWidget.LastRect.BelowOf());

      wdgLabel.Add('FPC Path: ' + platform^.Path);
      wdgLabel.Add('FPC Config Path: ' + platform^.ConfigPath);
   end;

   uiWidget.LastRect.GoBelow();

   for i := 0 to build.LazarusInstalls.n - 1 do begin
      laz := @build.LazarusInstalls.List[i];

      if(i = 0) then
         wdgDivisor.Add('Lazarus: Default', uiWidget.LastRect.BelowOf())
      else
         wdgDivisor.Add('Lazarus: ' + laz^.Name, uiWidget.LastRect.BelowOf());

      wdgLabel.Add('Lazarus Path: ' + laz^.Path);
      wdgLabel.Add('Lazarus Config Path: ' + laz^.ConfigPath);
      wdgLabel.Add('Use FPC: ' + laz^.UseFpc + ' (found: ' + sf(laz^.FPC <> nil) + ')');
   end;

   uiWidget.LastRect.GoBelow();

   wdgDivisor.Add('Preview', uiWidget.LastRect.BelowOf());

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
   ox.Init.iAdd('settings', @init);

END.
