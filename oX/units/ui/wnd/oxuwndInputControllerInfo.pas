{
   oxuwndInputControllerInfo, controller information/test window
   Copyright (C) 2019. Dejan Boras

   Started On:    25.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndInputControllerInfo;

INTERFACE

   USES
      uStd,
      {app}
      uApp, appuController,
      {ox}
      uOX, oxuTypes, oxuConsoleBackend, oxuwndBase,
      {ui}
      uiuControl, uiuWindow,
      uiuWidget, uiWidgets,
      wdguLabel, wdguButton, wdguDivisor;

TYPE

   { oxTControllerInfoWindow }

   oxTControllerInfoWindow = class(oxTWindowBase)
      constructor Create(); override;

      protected
      procedure AddWidgets(); override;
   end;

VAR
   oxwndControllerInfo: oxTControllerInfoWindow;

IMPLEMENTATION

procedure oxTControllerInfoWindow.AddWidgets();
var
   btnOk: wdgTButton;

begin
   {add a cancel button}
   btnOk := wdgButton.Add('Close', uiWidget.LastRect.BelowOf(), oxDimensions(80, 20), @Close);

   Window.ContentAutoSize();
   Window.AutoCenter();

   btnOk.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);
end;

constructor oxTControllerInfoWindow.Create;
begin
   ID := uiControl.GetID('ox.controller_info');
   Width := 540;
   Height := 200;
   Title := 'Controller Info';

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
   oxwndControllerInfo := oxTControllerInfoWindow.Create();

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:controller_info', @consoleCallback);
   {$ENDIF}
end;

procedure deinitialize();
begin
   FreeObject(oxwndControllerInfo);
end;

INITIALIZATION
   ox.Init.Add('ox.controller_info', @initialize, @deinitialize);

END.
