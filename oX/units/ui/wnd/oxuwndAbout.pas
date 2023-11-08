{
   oxuwndAbout, oX About Window
   Copyright (C) 2010. Dejan Boras

   Started On:    20.04.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndAbout;

INTERFACE

USES
   uStd,
   {app}
   uAppInfo, appuSysInfoBase,
   {oX}
   uOX, oxuTypes, {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF} oxuRenderer,
   oxuWindowTypes, oxuwndBase,
   {ui}
   uiuControl, uiuWindowTypes, uiuWindow, uiWidgets, uiuWidget,
   {widgets}
   wdguLabel, wdguButton, wdguDivisor;

TYPE

   { oxTAboutWindow }

   oxTAboutWindow = class(oxTWindowBase)
      constructor Create(); override;

      protected
      procedure CreateWindow(); override;
      procedure AddWidgets(); override;
   end;

VAR
   oxwndAbout: oxTAboutWindow;

IMPLEMENTATION

procedure showInformation();
begin

end;

procedure oxTAboutWindow.AddWidgets();
begin
   {add the label}
   wdgLabel.Add(appInfo.GetVersionString(0));
   wdgLabel.Add(ox.GetVersionString(0));
   wdgLabel.Add('Copyright (c) Dejan Boras');

   wdgDivisor.Add('Information', uiWidget.LastRect.BelowOf());

   wdgLabel.Add('CPU: ' + appSI.GetProcessorName());
   wdgLabel.Add('Memory: ' + appSI.GetMemorySize());

   wdgDivisor.Add('Renderer Information', uiWidget.LastRect.BelowOf());
   wdgLabel.Add(oxRenderer.GetSummary(oxTWindow(Window.oxwParent)),
      uiWidget.LastRect.BelowOf(), oxNullDimensions);

   {add a cancel button}
   wdgButton.Add('Ok', oxNullPoint, oxDimensions(80, 20), @Close).
      SetPosition( wdgPOSITION_HORIZONTAL_RIGHT or wdgPOSITION_VERTICAL_BOTTOM);
   wdgButton.Add('More Information', oxNullPoint, oxDimensions(200, 20), @showInformation).
      SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_BOTTOM);
end;

constructor oxTAboutWindow.Create;
begin
   ID := uiControl.GetID('ox.about');
   Width := 450;
   Height := 200;
   Title := 'About';

   inherited Create;
end;

procedure oxTAboutWindow.CreateWindow();
begin
   Exclude(uiWindow.Create.Properties, uiwndpRESIZABLE);

   inherited;
end;

procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndAbout.Open();
end;

procedure Initialize();
begin
   oxwndAbout := oxTAboutWindow.Create();
   console.Selected^.AddCommand('about', @consoleCallback);
end;

procedure deinitialize();
begin
   FreeObject(oxwndAbout);
end;

INITIALIZATION
   ox.Init.Add('ox.about', @initialize, @deinitialize);

END.
