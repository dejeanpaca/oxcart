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
   uOX, oxuTypes, oxuRunRoutines, oxuRenderer,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget, uiuTypes,
   oxuwndBase, oxuwndSystemInformation,
   {widgets}
   wdguLabel, wdguButton, wdguDivisor, wdguLink;

TYPE

   { oxTAboutWindow }

   oxTAboutWindow = object(oxTWindowBase)
      Copyright,
      Description: StdString;
      ShowBuiltWith: boolean;

      LinkCount: loopint;
      Links: array[0..3] of uiTLink;

      constructor Create();
      destructor Destroy();

      procedure AddLink(caption, link: StdString);
      procedure ResetLinks();

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
   wdgl: wdgTLabel;
   btnMI,
   btnOk: wdgTButton;
   i: loopint;

begin
   {add the label}
   wdgLabel.Add(appInfo.GetVersionString(0));
   wdgDivisor.Add('');
   wdgLabel.Add(ox.GetVersionString(0));

   if(Copyright <> '') then begin
      wdgl := wdgLabel.Add(Copyright);
      wdgl.MultilineConditional();
   end;

   if(Description <> '') then begin
      wdgl := wdgLabel.Add(Description);
      wdgl.MultilineConditional();
   end;

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
   wdgLabel.Add(oxRenderer.GetSummary(), uiWidget.LastRect.BelowOf(), oxNullDimensions);

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

   AddLink('=> Site', 'https://dbx7.net/');
   AddLink('=> Github', 'https://github.com/dejeanpaca/oxcart');

   {$IFDEF OX_FEATURE_CONSOLE}
   ConsoleOpenCommand := 'wnd:about';
   {$ENDIF}

   inherited;
end;

destructor oxTAboutWindow.Destroy();
begin
   ResetLinks();
end;

procedure oxTAboutWindow.AddLink(caption, link: StdString);
begin
   if(LinkCount > High(Links)) then
      exit;

   Links[LinkCount].Caption := caption;
   Links[LinkCount].Link := link;

   inc(LinkCount);
end;

procedure oxTAboutWindow.ResetLinks();
var
   i: loopint;

begin
   LinkCount := 0;

   for i := 0 to High(Links) do begin
      Links[i].Caption := '';
      Links[i].Link := '';
   end;
end;

procedure Initialize();
begin
   oxwndAbout.Create();
end;

procedure deinitialize();
begin
   oxwndAbout.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.about', @initialize, @deinitialize);

END.
