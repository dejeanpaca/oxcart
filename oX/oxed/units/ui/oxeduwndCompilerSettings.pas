{
   oxeduwndCompilerSettings, oxed compiler settings window
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduwndCompilerSettings;

INTERFACE

   USES
      uStd,
      {ox}
      oxuwndSettings, oxuRunRoutines,
      {widgets}
      uiWidgets,
      wdguCheckbox, wdguDivisor,
      {oxed}
      uOXED, oxeduSettings,
      oxeduwndProjectSettings;

IMPLEMENTATION

procedure saveCallback();
begin
end;

procedure revertCallback();
begin
end;

procedure AddTabs();
begin
   oxedwndProjectSettings.Tabs.AddTab('Compiler', 'compiler');

   wdgDivisor.Add('Compiler settings');
end;

procedure init();
begin
   oxedwndProjectSettings.OnSave.Add(@saveCallback);
   oxedwndProjectSettings.OnRevert.Add(@revertCallback);
   oxedwndProjectSettings.OnAddTabs.Add(@addTabs);
end;

INITIALIZATION
   oxed.Init.Add('compiler_settings', @init);

END.
