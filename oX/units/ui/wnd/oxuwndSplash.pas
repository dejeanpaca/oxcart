{
   oxuwndSplash, oX splash Window
   Copyright (C) 2016. Dejan Boras

   Started On:    19.09.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSplash;

INTERFACE

USES
   uStd, uColors, udvars,
   {app}
   uAppInfo, appuEvents, appuMouse, appuMouseEvents,
   {oX}
   uOX, oxuTypes, oxuRenderer, {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF}
   oxuwndBase, oxuPaths, oxuRunRoutines,
   {ui}
   uiuWindowTypes, uiuWindow, uiWidgets, uiuWidget, uiuControl, uiuTypes,
   {widgets}
   wdguLabel, wdguImage, wdguCheckbox, wdguLink;

TYPE

   { oxTWindowSplash }

   uiTWindowSplash = class(oxuiTWindowBase)
      procedure OnDeactivate; override;
   end;

   { oxTSplashWindow }

   oxTSplashWindow = class(oxTWindowBase)
     {optional link}
     LinkCaption,
     Link,
     {filename of an image}
     ImageFileName,
     {build information to be shown if ShowBuildInformation is enabled}
     BuildInformation: string; static;

     {show splash window on app start}
     ShowOnStart,
     {always show on start, regardless of the ShowOnStart setting}
     AlwaysShowOnStart,
     {show build information}
     ShowBuildInformation,
     {show information over image}
     InformationOverImage: boolean; static;

     BackgroundColor: TColor4ub;

     {coordinates where the splash image ends on the splash window}
     SplashImageEnd: longint;

     {list of procedures called when splash window is initialized}
     OnInit: TProcedures; static;

     constructor Create(); override;

     protected
     procedure CreateWindow(); override;
     procedure AddWidgets(); override;
   end;

VAR
   oxwndSplash: oxTSplashWindow = nil;

IMPLEMENTATION

function controlShowOnStartCheckbox(wdg: TObject; {%H-}what: longword): longint;
begin
   result := -1;

   oxwndSplash.ShowOnStart := wdgpTRUE in wdgTCheckbox(wdg).Properties;
end;

procedure closeSplashWindow();
begin
   oxwndSplash.Close();
end;

{ oxTWindowSplash }

procedure uiTWindowSplash.OnDeactivate;
begin
   oxwndSplash.Close();
end;

procedure oxTSplashWindow.AddWidgets();
var
   splashHeight,
   top: loopint;
   wdg: uiTWidget;

begin
   splashHeight := round(oxwndSplash.Width * 0.5625);

   if(not oxTSplashWindow.InformationOverImage) then begin
      if(ShowBuildInformation) then
         top := window.Dimensions.h - 25
      else
         top := window.Dimensions.h - 35;
   end else
      top := window.Dimensions.h;

   wdg := wdgImage.Add(ImageFileName, oxPoint(0, top), oxDimensions(oxwndSplash.Width, splashHeight));
   Exclude(wdg.Properties, wdgpSELECTABLE);

   wdgLabel.Add(appInfo.GetVersionString(), oxPoint(wdgDEFAULT_SPACING, Window.Dimensions.h - 6), oxNullDimensions);

   SplashImageEnd := wdg.Position.y - wdg.Dimensions.h - wdgDEFAULT_SPACING;

   if(ShowBuildInformation) then begin
      wdg := wdgLabel.Add(BuildInformation, oxPoint(wdgDEFAULT_SPACING, Window.Dimensions.h - 20), oxNullDimensions);
      wdg.Color := wdg.Color.Darken(0.3);

      wdg := wdgLabel.Add({$I %Date%}, oxPoint(0, Window.Dimensions.h - 20), oxNullDimensions).SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);
      wdg.Color := wdg.Color.Darken(0.3);
   end;

   if(not AlwaysShowOnStart) then
      wdgCheckbox.Add('Show on start', oxPoint(wdgDEFAULT_SPACING, 15), oxwndSplash.ShowOnStart).
         SetControl(@controlShowOnStartCheckbox);

   if(Link <> '') and (LinkCaption = '') then
      LinkCaption := Link;

   if(Link <> '') then begin
      wdgLink.Add(oxwndSplash.LinkCaption, oxwndSplash.Link, oxPoint(5, Window.Dimensions.h - 10), oxNullDimensions).
         SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);
   end;
end;

function splashWndHandler({%H-}wnd: uiTControl; const event: appTEvent): longint;
var
   m: appTMouseEvent;

begin
   result := -1;

   if(event.IsEvent(appMouseEvents.evh, appMOUSE_EVENT)) then begin
      m := appTMouseEvent(event.GetData()^);

      if(m.Action.IsSet(appmcRELEASED) and m.Button.IsSet(appmcLEFT)) then begin
         oxwndSplash.Close();
         result := 0;
      end;
   end;
end;

constructor oxTSplashWindow.Create;
begin
   inherited Create;

   Width := 480;
   Height := 420;
   BackgroundColor := cBlack4ub;

   ID := uiControl.GetID('ox.splash');
end;

procedure oxTSplashWindow.CreateWindow();
begin
   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;
   uiWindow.Create.Properties := uiWindow.Create.Properties - [uiwndpRESIZABLE, uiwndpMOVABLE];
   uiWindow.Create.Instance := uiTWindowSplash;

   inherited;

   Window.wHandler := @splashWndHandler;
   Window.Background.Color := BackgroundColor;

   if(Window <> nil) then
      OnInit.Call();
end;

procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndSplash.Open();
end;

procedure initialize();
begin
   console.Selected^.AddCommand('splash', @consoleCallback);

   oxwndSplash := oxTSplashWindow.Create();
end;

procedure deinitialize();
begin
   console.Selected^.AddCommand('splash', @consoleCallback);
   FreeObject(oxwndSplash);
end;

procedure splashStart();
begin
   if((oxwndSplash.ShowOnStart) or (oxwndSplash.AlwaysShowOnStart)) then
      oxwndSplash.Open();
end;

VAR
   {splash dvar group}
   dvgSplash: TDVarGroup;
   {show on start dvar}
   dvSplashShowOnStart: TDVar;

   routine,
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxTSplashWindow.ShowOnStart := true;
   oxTSplashWindow.AlwaysShowOnStart := false;
   oxTSplashWindow.ImageFileName := oxPaths.Data + 'splash.png';
   oxTSplashWindow.Link := '';
   oxTSplashWindow.LinkCaption := '';
   oxTSplashWindow.BuildInformation := {$I %FPCTarget%} + ' (fpc ' + {$INCLUDE %FPCVersion%} + ')';
   oxTSplashWindow.InformationOverImage := true;

   TProcedures.Initialize(oxTSplashWindow.OnInit, 8);

   { set dvars }
   ox.dvar.Add('splash', dvgSplash);
   dvgSplash.Add(dvSplashShowOnStart, 'showOnStart', dtcBOOL, @oxTSplashWindow.ShowOnStart);

   { set init }
   ox.Init.Add(initRoutines, 'ox.splash', @initialize, @deinitialize);

   ox.OnStart.Add(routine, 'ox.splash', @splashStart);
END.
