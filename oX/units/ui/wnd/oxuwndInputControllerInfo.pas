{
   oxuwndInputControllerInfo, controller information/test window
   Copyright (C) 2019. Dejan Boras

   TODO: Close window if controller disconnected
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndInputControllerInfo;

INTERFACE

   USES
      uStd, StringUtils,
      {app}
      uApp, appuController,
      {ox}
      uOX, oxuTypes,
      {$IFDEF OX_FEATURE_CONSOLE}
      oxuConsoleBackend,
      {$ENDIF}
      oxuwndBase,
      {ui}
      uiuControl, uiuWindow,
      uiuWidget, uiWidgets,
      wdguLabel, wdguButton, wdguDivisor, wdguControllerInputState, wdguProgressBar;

TYPE

   { oxuiTControllerInfoWindow }

   oxuiTControllerInfoWindow = class(oxuiTWindowBase)
      procedure Update(); override;
   end;

   { oxTControllerInfoWindow }

   oxTControllerInfoWindow = object(oxTWindowBase)
      public
      Controller: appTControllerDevice;

      wdg: record
         Buttons: array[0..appMAX_CONTROLLER_BUTTONS - 1] of wdgTControllerButtonState;
         Axes: array[0..appMAX_CONTROLLER_AXES - 1] of wdgTProgressBar;
         Triggers: array[0..appMAX_CONTROLLER_TRIGGERS - 1] of wdgTProgressBar;
      end;

      constructor Create();
      procedure Open(); virtual;

      protected
      procedure AddWidgets(); virtual;

      {update controller representation}
      procedure Update();
   end;

VAR
   oxwndControllerInfo: oxTControllerInfoWindow;

IMPLEMENTATION

{ oxuiTControllerInfoWindow }

procedure oxuiTControllerInfoWindow.Update();
begin
   if(oxwndControllerInfo.Window <> nil) then
      oxwndControllerInfo.Update();
end;

{ oxTControllerInfoWindow }

procedure oxTControllerInfoWindow.AddWidgets();
var
   btnOk: wdgTButton;
   btnWidget: wdgTControllerButtonState;
   triggerWidget,
   axisWidget: wdgTProgressBar;

   buttonsPerRow,
   i: loopint;

begin
   wdgLabel.Add('Controller: ' + controller.GetName() +
      ' (' + appPControllerHandler(Controller.Handler)^.GetName() + ')');

   wdgDivisor.Add('');

   wdgLabel.Add('Buttons: ' + sf(controller.ButtonCount) + ' / Axes: ' + sf(controller.AxisCount) +
      ' / Triggers: ' + sf(controller.TriggerCount) + ' / DPad: ' + sf(controller.DPadPresent));

   uiWidget.LastRect.NextLine();

   buttonsPerRow := 8;
   if(Controller.ButtonCount > 16) then
      buttonsPerRow := 10;

   ZeroOut(wdg.Buttons, SizeOf(wdg.Buttons));
   ZeroOut(wdg.Axes, SizeOf(wdg.Axes));
   ZeroOut(wdg.Triggers, SizeOf(wdg.Triggers));

   for i := 0 to Controller.ButtonCount - 1 do begin
      if(i mod buttonsPerRow = 0) and (i >= buttonsPerRow) then
         uiWidget.LastRect.NextLine();

      btnWidget := wdgControllerButtonState.Add(uiWidget.LastRect.RightOf());
      btnWidget.ButtonName := sf(i);
      btnWidget.ButtonIndex := i;
      btnWidget.SetPressure(Controller.GetButtonPressure(i));

      wdg.Buttons[i] := btnWidget;
   end;

   if(Controller.AxisCount > 0) then
      uiWidget.LastRect.NextLine();

   for i := 0 to Controller.AxisCount - 1 do begin
      if(i mod 2 = 0) and (i > 0) then
         uiWidget.LastRect.NextLine();

      axisWidget := wdgProgressBar.Add(uiWidget.LastRect.RightOf(), oxDimensions(60, 25));
      axisWidget.SetCaption(sf(i));
      axisWidget.Progress.PercentageInText := false;
      axisWidget.SetRatio(Controller.GetUnitAxisValue(i));

      wdg.Axes[i] := axisWidget;
   end;

   if(Controller.TriggerCount > 0) then
      uiWidget.LastRect.NextLine();

   for i := 0 to Controller.TriggerCount - 1 do begin
      if(i mod 2 = 0) and (i > 0) then
         uiWidget.LastRect.NextLine();

      triggerWidget := wdgProgressBar.Add(uiWidget.LastRect.RightOf(), oxDimensions(60, 25));
      triggerWidget.SetCaption(sf(i));
      triggerWidget.Progress.PercentageInText := false;
      triggerWidget.SetRatio(Controller.GetNormalizedTriggerValue(i));

      wdg.Triggers[i] := triggerWidget;
   end;

   {add a cancel button}
   btnOk := wdgButton.Add('Close', uiWidget.LastRect.BelowOf(), oxNullDimensions, @Close);
   btnOk.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);

   Window.ContentAutoSize();
   Window.AutoCenter();
end;

procedure oxTControllerInfoWindow.Update();
var
   i: loopint;

begin
   if(Controller = nil) or (not Controller.Updated) then
      exit;

   for i := 0 to Controller.ButtonCount - 1 do begin
      if(wdg.Buttons[i] <> nil) then
         wdg.Buttons[i].SetPressure(Controller.GetButtonPressure(i));
   end;

   for i := 0 to Controller.AxisCount - 1 do begin
      if(wdg.Axes[i] <> nil) then
         wdg.Axes[i].SetRatio(Controller.GetUnitAxisValue(i));
   end;

   for i := 0 to Controller.TriggerCount - 1 do begin
      if(wdg.Triggers[i] <> nil) then
         wdg.Triggers[i].SetRatio(Controller.GetTriggerValue(i));
   end;
end;

constructor oxTControllerInfoWindow.Create();
begin
   ID := uiControl.GetID('ox.controller_info');
   Width := 380;
   Height := 200;
   Title := 'Controller Info';
   Instance := oxuiTControllerInfoWindow;

   inherited;
end;

procedure oxTControllerInfoWindow.Open();
begin
   if(Controller <> nil) then
      inherited;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndControllerInfo.Open();
end;
{$ENDIF}

procedure initialize();
begin
   oxwndControllerInfo.Create();

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:controller_info', @consoleCallback);
   {$ENDIF}
end;

procedure deinitialize();
begin
   oxwndControllerInfo.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.controller_info', @initialize, @deinitialize);

END.
