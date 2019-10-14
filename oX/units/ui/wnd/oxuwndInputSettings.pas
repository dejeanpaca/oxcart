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
      uOX, oxuTypes, oxuRunRoutines, oxuwndSettings, oxuwndInputControllerInfo,
      {ui}
      uiWidgets, wdguLabel, wdguButton, wdguDivisor;


IMPLEMENTATION

procedure revertSettings();
begin
end;

procedure configureKeyboard();
begin

end;

procedure configurePointer();
begin
end;

procedure testController();
begin

end;

procedure rescanControllers();
begin
   appControllers.Reset();
end;

procedure addTabs();
var
   i: loopint;

begin
   oxwndSettings.Tabs.AddTab('Input', 'input');

   wdgDivisor.Add('Keyboard');
   wdgLabel.Add('We assume you have a keyboard attached');
   wdgButton.Add('Configure').UseCallback(@configureKeyboard);

   wdgDivisor.Add('Mouse / Pointer');
   wdgLabel.Add('We also assume you have a mouse/pointer attached');
   wdgButton.Add('Configure').UseCallback(@configurePointer);

   wdgDivisor.Add('Controllers');

   if(appControllers.List.n > 0) then begin
      for i := 0 to appControllers.List.n - 1 do begin
         wdgButton.Add(appControllers.List[i].GetName());
         wdgButton.Add('Information / Test', uiWidget.LastRect.RightOf(), oxNullDimensions, @testController);
      end;
   end else begin
      wdgLabel.Add('No controllers detected/supported');
      wdgButton.Add('Rescan').UseCallback(@rescanControllers);
   end;
end;

procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.PostAddTabs.Add(@addTabs);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'ox.wnd:settings.input', @init);

END.
