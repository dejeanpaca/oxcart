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
      wdguLabel, wdguButton, wdguDivisor, wdguControllerInputState;

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

   buttonsPerRow,
   i: loopint;

begin
   wdgLabel.Add('Controller: ' + controller.GetName() +
      ' (' + appPControllerHandler(Controller.Handler)^.GetName() + ')');

   wdgDivisor.Add('');

   wdgLabel.Add('Buttons: ' + sf(controller.ButtonCount) + ' / Axes: ' + sf(controller.AxisCount) +
      ' / Triggers: ' + sf(controller.TriggerCount) + ' / Hats: ' + sf(controller.HatCount));

   uiWidget.LastRect.NextLine();

   buttonsPerRow := 8;
   if(Controller.ButtonCount > 16) then
      buttonsPerRow := 10;

   ZeroOut(wdg.Buttons, SizeOf(wdg.Buttons));

   for i := 0 to Controller.ButtonCount - 1 do begin
      btnWidget := wdgControllerButtonState.Add(uiWidget.LastRect.RightOf());
      btnWidget.ButtonName := sf(i);
      btnWidget.ButtonIndex := i;

      wdg.Buttons[i] := btnWidget;

      if(i mod buttonsPerRow = 0) and (i > 0) then begin
         uiWidget.LastRect.NextLine();
      end;
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
      if(wdg.Buttons[i] <> nil) then begin
         if(Controller.GetButtonPressure(i) > 0) then
            writeln('pressed: ', i);

         wdg.Buttons[i].SetPressure(Controller.GetButtonPressure(i));
      end;
   end;
end;

constructor oxTControllerInfoWindow.Create();
begin
   ID := uiControl.GetID('ox.controller_info');
   Width := 540;
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
