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

   { oxTControllerInfoWindow }

   oxTControllerInfoWindow = object(oxTWindowBase)
      public
      Controller: appTControllerDevice;

      constructor Create();
      procedure Open(); virtual;

      protected
      procedure AddWidgets(); virtual;
   end;

VAR
   oxwndControllerInfo: oxTControllerInfoWindow;

IMPLEMENTATION

procedure oxTControllerInfoWindow.AddWidgets();
var
   btnOk: wdgTButton;

begin
   wdgLabel.Add('Controller: ' + controller.GetName() +
      ' (' + appPControllerHandler(Controller.Handler)^.GetName() + ')');

   wdgDivisor.Add('');

   wdgLabel.Add('Buttons: ' + sf(controller.ButtonCount) + ' / Axes: ' + sf(controller.AxisCount) +
      ' / Triggers: ' + sf(controller.TriggerCount) + ' / Hats: ' + sf(controller.HatCount));

   {add a cancel button}
   btnOk := wdgButton.Add('Close', uiWidget.LastRect.BelowOf(), oxNullDimensions, @Close);
   btnOk.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);

   Window.ContentAutoSize();
   Window.AutoCenter();
end;

constructor oxTControllerInfoWindow.Create();
begin
   ID := uiControl.GetID('ox.controller_info');
   Width := 540;
   Height := 200;
   Title := 'Controller Info';

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

procedure Initialize();
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
