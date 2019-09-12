{
   oxuwndInputSettings, input settings window
   Copyright (C) 2019. Dejan Boras

   Started On:    12.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndInputSettings;

INTERFACE

   USES
      uStd,
      {app}
      uApp, appuController,
      {ox}
      uOX, oxuTypes, oxuRunRoutines, oxuwndSettings,
      {ui}
      uiWidgets, wdguLabel, wdguDivisor;


IMPLEMENTATION

VAR
   wdg: record
   end;

procedure revertSettings();
begin
end;

procedure addTabs();
var
   i: loopint;

begin
   oxwndSettings.Tabs.AddTab('Input', 'input');

   wdgDivisor.Add('Keyboard');
   wdgLabel.Add('We assume you have a keyboard attached');

   wdgDivisor.Add('Mouse / Pointer');
   wdgLabel.Add('We also assume you have a mouse/pointer attached');

   wdgDivisor.Add('Controllers');

   if(appControllers.List.n > 0) then begin
      for i := 0 to appControllers.List.n - 1 do begin
         wdgLabel.Add(appControllers.List[i].GetName());
      end;
   end else
      wdgLabel.Add('No controllers detected/supported');
end;

procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.PostAddTabs.Add(@addTabs);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.iAdd(initRoutines, 'ox.wnd:settings.input', @init);

END.
