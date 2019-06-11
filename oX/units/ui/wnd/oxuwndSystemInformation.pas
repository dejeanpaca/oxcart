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
   uOX, oxuTypes, oxuRunRoutines,
   {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF} oxuRenderer,
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
   {add the label}
   wdgDivisor.Add('Information', uiWidget.LastRect.BelowOf());

   wdgLabel.Add('CPU: ' + appSI.GetProcessorName());
   wdgLabel.Add('Memory: ' + appSI.GetMemorySize());

   wdgDivisor.Add('Renderer Information', uiWidget.LastRect.BelowOf());
   wdgLabel.Add(oxRenderer.GetSummary(oxTWindow(Window.oxwParent)),
      uiWidget.LastRect.BelowOf(), oxNullDimensions);

   {add a cancel button}
   btnClose := wdgButton.Add('Close', uiWidget.LastRect.BelowOf(), oxDimensions(80, 20), @Close);

   Window.ContentAutoSize();

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

procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndSystemInformation.Open();
end;

procedure Initialize();
begin
   oxwndSystemInformation := oxTSystemInformationWindow.Create();
   console.Selected^.AddCommand('sysinfo', @consoleCallback);
end;

procedure deinitialize();
begin
   FreeObject(oxwndSystemInformation);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'ox.system_information', @initialize, @deinitialize);

END.
