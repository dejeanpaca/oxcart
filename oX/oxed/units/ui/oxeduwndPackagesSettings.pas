{
   oxeduwndPackagesSettings, packages settings windows
   Copyright (C) 2020. Dejan Boras

   Started On:    06.02.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndPackagesSettings;

INTERFACE

   USES
      {app}
      uStd,
      {oX}
      oxuRunRoutines,
      {ui}
      uiuWindow, uiWidgets, uiuControl,
      {widgets}
      wdguLabel,
      {oxed}
      uOXED, oxeduProject, oxeduProjectPackages,
      oxeduProjectSettingsWindow;

IMPLEMENTATION

function validateCallback(): TAppendableString;
begin
   Result := '';
end;


procedure revertCallback();
begin
end;

procedure saveCallback();
begin
end;

{ oxedTSettingsWindow }

procedure Initialize();
begin
   oxedwndProjectSettings.Tabs.AddTab('Packages', 'packages');

   // TODO: Add Widgets
   wdgLabel.Add('Packages');

   revertCallback();
end;

procedure init();
begin
   oxedwndProjectSettings.PostAddTabs.Add(@Initialize);
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
   oxedwndProjectSettings.OnValidate.Add(@validateCallback);
end;

INITIALIZATION
   oxed.Init.Add('oxed.packages_settings_window', @init);

END.
