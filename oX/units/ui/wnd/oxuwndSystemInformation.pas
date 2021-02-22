{
   oxuwndSystemInformation, oX System Information window
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSystemInformation;

INTERFACE

USES
   uStd,
   {app}
   uAppInfo, appuSysInfoBase,
   {oX}
   uOX, oxuTypes, oxuRunRoutines, oxuRenderer, oxuwndBase,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget,
   {widgets}
   wdguLabel, wdguButton, wdguDivisor;

TYPE

   { oxTSystemInformationWindow }

   oxTSystemInformationWindow = object(oxTWindowBase)
      constructor Create();

      protected
      procedure AddWidgets(); virtual;
   end;

VAR
   oxwndSystemInformation: oxTSystemInformationWindow;

IMPLEMENTATION

procedure oxTSystemInformationWindow.AddWidgets();
var
   btnClose: wdgTButton;

begin
   if appSI.HasSystemInformation() then begin
      wdgDivisor.Add('OS Information');

      if(appSI.System.Name <> '') then
         wdgLabel.Add('OS: ' + appSI.System.Name);

      if(appSI.System.DeviceName <> '') then
         wdgLabel.Add('System: ' + appSI.System.DeviceName);

      if(appSI.System.KernelVersion <> '') then
         wdgLabel.Add('Kernel: ' + appSI.System.KernelVersion);
   end;

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
   wdgLabel.Add(oxRenderer.GetSummary(), uiWidget.LastRect.BelowOf(), oxNullDimensions);

   btnClose := wdgButton.Add('Close', uiWidget.LastRect.BelowOf(), oxNullDimensions, @Close);

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

   {$IFDEF OX_FEATURE_CONSOLE}
   ConsoleOpenCommand := 'wnd:sysinfo';
   {$ENDIF}

   inherited;
end;

procedure Initialize();
begin
   oxwndSystemInformation.Create();
end;

procedure deinitialize();
begin
   oxwndSystemInformation.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.system_information', @initialize, @deinitialize);

END.
