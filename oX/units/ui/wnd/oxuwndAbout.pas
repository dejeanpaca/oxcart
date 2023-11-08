{
   oxuwndAbout, oX About Window
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndAbout;

INTERFACE

USES
   uStd,
   {app}
   uAppInfo, appuSysInfoBase, appuActionEvents,
   {oX}
   uOX, oxuTypes, oxuRunRoutines,
   {$IFDEF OX_FEATURE_CONSOLE}
   oxuConsoleBackend,
   {$ENDIF}
   oxuRenderer,
   oxuWindowTypes, oxuwndBase,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget, uiuTypes,
   oxuwndSystemInformation,
   {widgets}
   wdguLabel, wdguButton, wdguDivisor, wdguLink;

TYPE

   { oxTAboutWindow }

   oxTAboutWindow = object(oxTWindowBase)
      Copyright: string;
      ShowBuiltWith: boolean;
      Links: array[0..3] of uiTLink;

      constructor Create();

      protected
      procedure AddWidgets(); virtual;
   end;

VAR
   oxwndAbout: oxTAboutWindow;

IMPLEMENTATION

procedure showInformation();
begin
   oxwndAbout.Close();
   appActionEvents.Queue(oxwndSystemInformation.OpenWindowAction);
end;

procedure oxTAboutWindow.AddWidgets();
var
   btnMI,
   btnOk: wdgTButton;
   i: loopint;

begin
   {add the label}
   wdgLabel.Add(appInfo.GetVersionString(0));
   wdgLabel.Add(ox.GetVersionString(0));

   if(Copyright <> '') then
      wdgLabel.Add(Copyright);

   for i := 0 to high(Links) do begin
      if(Links[i].Link <> '')  then
         wdgLink.Add(Links[i]);
   end;

   if(ShowBuiltWith) then begin
      wdgDivisor.Add('Built with');
      wdgLabel.Add('Free Pascal ' + {$I %FPCVERSION%} + ' ' + {$I %FPCTARGETCPU%} + '-' + {$I %FPCTARGETOS%} );
   end;

   wdgDivisor.Add('Information');

   wdgLabel.Add('CPU: ' + appSI.GetProcessorName());
   wdgLabel.Add('Memory: ' + appSI.GetMemorySize());

   wdgDivisor.Add('Renderer Information');
   wdgLabel.Add(oxRenderer.GetSummary(oxTWindow(Window.oxwParent)),
      uiWidget.LastRect.BelowOf(), oxNullDimensions);

   {add a cancel button}
   btnOk := wdgButton.Add('Ok', uiWidget.LastRect.BelowOf(), oxDimensions(80, 20), @Close);
   btnMI := wdgButton.Add('More Information', uiWidget.LastRect.RightOf(), oxDimensions(200, 20), @showInformation);

   Window.ContentAutoSize();
   Window.AutoCenter();

   btnOk.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);
   btnMI.SetPosition(wdgPOSITION_HORIZONTAL_LEFT);
end;

constructor oxTAboutWindow.Create();
begin
   ID := uiControl.GetID('ox.about');
   Width := 450;
   Height := 200;
   Title := 'About';

   Copyright := 'Copyright (c) Dejan Boras';

   Links[0].Caption := '=> Github';
   Links[0].Link := 'https://github.com/dejeanpaca/oxcart';

   Links[1].Caption := '=> Site';
   Links[1].Link := 'https://dbx7.net/';

   inherited;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndAbout.Open();
end;
{$ENDIF}

procedure Initialize();
begin
   oxwndAbout.Create();

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:about', @consoleCallback);
   {$ENDIF}
end;

procedure deinitialize();
begin
   oxwndAbout.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.about', @initialize, @deinitialize);

END.
