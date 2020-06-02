{
   oxuwndSettingsInput, input settings window
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettingsInput;

INTERFACE

   USES
      uStd,
      {app}
      uApp, appuController,
      {ox}
      uOX, oxuTypes, oxuRunRoutines, oxuwndSettings, oxuwndInputControllerInfo,
      {ui}
      uiWidgets, uiuWidget, wdguLabel, wdguButton, wdguDivisor;


IMPLEMENTATION

TYPE
   wdgTControllerTestButton = class(wdgTButton)
      ControllerIndex: loopint;
   end;

procedure revertSettings();
begin
end;

procedure configureKeyboard();
begin

end;

procedure configurePointer();
begin
end;

procedure testController(wdg: uiTWidget);
begin
   if(wdgTControllerTestButton(wdg).ControllerIndex > -1) then begin
      oxwndControllerInfo.Controller :=
         appControllers.GetByIndex(wdgTControllerTestButton(wdg).ControllerIndex);

      oxwndControllerInfo.Open();
   end;
end;

procedure rescanControllers();
begin
   appControllers.Reset();
end;

procedure addTabs();
var
   i: loopint;
   btn: wdgTButton;

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
         uiWidget.Create.Instance := wdgTControllerTestButton;
         btn := wdgButton.Add('Information / Test', uiWidget.LastRect.RightOf(), oxNullDimensions, 0);
         wdgTControllerTestButton(btn).ControllerIndex := i;
         btn.UseCallback(@testController);
      end;
   end else
      wdgLabel.Add('No controllers detected/supported');

   uiWidget.LastRect.GoLeft();
   wdgButton.Add('Rescan').UseCallback(@rescanControllers);
end;

procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.OnAddTabs.Add(@addTabs);
end;

INITIALIZATION
   ox.Init.Add('ox.wnd:settings.input', @init);

END.
