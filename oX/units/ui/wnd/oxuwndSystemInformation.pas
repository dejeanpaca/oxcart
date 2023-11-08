{
   oxuwndSystemInformation, oX System Information window
   Copyright (C) 2010. Dejan Boras

   Started On:    20.04.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSystemInformation;

INTERFACE

USES
   uStd,
   {app}
   uAppInfo, appuSysInfoBase,
   {oX}
   uOX, oxuTypes, oxuRunRoutines, oxuRenderer,
   {$IFDEF OX_FEATURE_CONSOLE}
   oxuConsoleBackend,
   {$ENDIF}
   oxuWindowTypes, oxuwndBase,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget,
   {widgets}
   wdguLabel, wdguButton, wdguDivisor;

TYPE

   { oxTSystemInformationWindow }

   oxTSystemInformationWindow = class(oxTWindowBase)
      constructor Create(); override;

      protected
      procedure AddWidgets(); override;
   end;

VAR
   oxwndSystemInformation: oxTSystemInformationWindow;

IMPLEMENTATION

procedure oxTSystemInformationWindow.AddWidgets();
var
   btnClose: wdgTButton;

begin
   wdgDivisor.Add('OS Information');
   wdgLabel.Add('OS: ' + appSI.SystemName);

   if(appSI.SystemDeviceName <> '') then
      wdgLabel.Add('System: ' + appSI.SystemDeviceName);

   if(appSI.KernelVersion <> '') then
      wdgLabel.Add('Kernel: ' + appSI.KernelVersion);

   wdgDivisor.Add('Hardware Information');

   if(appSI.HasProcessorInfo) then begin
      wdgLabel.Add('CPU: ' + appSI.GetProcessorName());
      wdgLabel.Add('CPU Vendor: ' + appSI.GetProcessorVendor());
      wdgLabel.Add('CPU Model: ' + appSI.GetProcessorModel());
   end;

   if(appSI.HasMemoryInfo) then begin
      wdgLabel.Add('Memory: ' + appSI.GetMemorySize());
   end;

   wdgDivisor.Add('Renderer Information');
   wdgLabel.Add(oxRenderer.GetSummary(oxTWindow(Window.oxwParent)),
      uiWidget.LastRect.BelowOf(), oxNullDimensions);

   btnClose := wdgButton.Add('Close', uiWidget.LastRect.BelowOf(), oxDimensions(80, 20), @Close);

   Window.ContentAutoSize();
   Window.AutoCenter();

   btnClose.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);
end;

constructor oxTSystemInformationWindow.Create;
begin
   ID := uiControl.GetID('ox.system_information');
   Width := 450;
   Height := 200;
   Title := 'System Information';

   inherited;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndSystemInformation.Open();
end;
{$ENDIF}

procedure Initialize();
begin
   oxwndSystemInformation := oxTSystemInformationWindow.Create();

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:sysinfo', @consoleCallback);
   {$ENDIF}
end;

procedure deinitialize();
begin
   FreeObject(oxwndSystemInformation);
end;

INITIALIZATION
   ox.Init.Add('ox.system_information', @initialize, @deinitialize);

END.
