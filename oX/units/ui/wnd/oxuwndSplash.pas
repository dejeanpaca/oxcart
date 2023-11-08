{
   oxuwndSplash, oX splash Window
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSplash;

INTERFACE

USES
   uStd, uColors, udvars,
   {app}
   uAppInfo, appuEvents, appuMouse, appuMouseEvents,
   {oX}
   uOX, oxuTypes, oxuRenderer,
   oxuwndBase, oxuPaths, oxuRunRoutines,
   {ui}
   uiuWindowTypes, uiuWindow, uiWidgets, uiuWidget, uiuControl, uiuTypes,
   {widgets}
   wdguLabel, wdguImage, wdguCheckbox, wdguLink;

TYPE

   { uiTWindowSplash }

   uiTWindowSplash = class(oxuiTWindowBase)
      procedure OnDeactivate(); override;
      procedure ParentSizeChange(); override;
   end;

   { oxTSplashWindow }

   oxTSplashWindow = object(oxTWindowBase)
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
     OnOpen: TProcedures; static;

     constructor Create();

     protected
     procedure CreateWindow(); virtual;
     procedure AddWidgets(); virtual;
   end;

VAR
   oxwndSplash: oxTSplashWindow;

IMPLEMENTATION

function controlShowOnStartCheckbox(wdg: uiTControl; {%H-}what: loopint): loopint;
begin
   Result := -1;

   oxwndSplash.ShowOnStart := wdgpTRUE in wdgTCheckbox(wdg).Properties;
end;

procedure closeSplashWindow();
begin
   oxwndSplash.Close();
end;

{ uiTWindowSplash }

procedure uiTWindowSplash.OnDeactivate();
begin
   oxwndSplash.Close();
end;

procedure uiTWindowSplash.ParentSizeChange();
begin
   AutoCenter();
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

   if(not AlwaysShowOnStart) then begin
      wdg := wdgCheckbox.Add('Show on start', oxPoint(wdgDEFAULT_SPACING, 15), oxwndSplash.ShowOnStart).
         SetControl(@controlShowOnStartCheckbox);
      wdg.SetPosition(wdgPOSITION_VERTICAL_BOTTOM);
   end;

   if(Link <> '') and (LinkCaption = '') then
      LinkCaption := Link;

   if(Link <> '') then begin
      wdgLink.Add(oxwndSplash.LinkCaption, oxwndSplash.Link, oxPoint(5, Window.Dimensions.h - 10), oxNullDimensions).
         SetPosition(wdgPOSITION_HORIZONTAL_RIGHT);
   end;
end;

function splashWndHandler({%H-}wnd: uiTWindow; const event: appTEvent): loopint;
var
   m: appTMouseEvent;

begin
   Result := -1;

   if(event.IsEvent(appMouseEvents.evh, appMOUSE_EVENT)) then begin
      m := appTMouseEvent(event.GetData()^);

      if(m.Action.IsSet(appmcRELEASED) and m.Button.IsSet(appmcLEFT)) then begin
         oxwndSplash.Close();
         Result := 0;
      end;
   end;
end;

constructor oxTSplashWindow.Create;
begin
   {$IFDEF OX_FEATURE_CONSOLE}
   ConsoleOpenCommand := 'wnd:splash';
   {$ENDIF}

   Width := 480;
   Height := 420;
   BackgroundColor.Assign(32, 32, 42, 242);

   ID := uiControl.GetID('ox.splash');
   Instance := uiTWindowSplash;

   inherited Create;
end;

procedure oxTSplashWindow.CreateWindow();
begin
   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;
   uiWindow.Create.Properties := uiWindow.Create.Properties - [uiwndpRESIZABLE, uiwndpMOVABLE];

   inherited;

   Window.SetHandler(@splashWndHandler);
   Window.Background.Color := BackgroundColor;

   if(Window <> nil) then
      OnOpen.Call();
end;

procedure initialize();
begin
   oxwndSplash.Create();
end;

procedure deinitialize();
begin
   oxwndSplash.Destroy();
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

INITIALIZATION
   oxTSplashWindow.ShowOnStart := true;
   oxTSplashWindow.AlwaysShowOnStart := false;
   oxTSplashWindow.ImageFileName := oxPaths.Data + 'splash.png';
   oxTSplashWindow.Link := '';
   oxTSplashWindow.LinkCaption := '';
   oxTSplashWindow.BuildInformation := {$I %FPCTarget%} + ' (fpc ' + {$INCLUDE %FPCVersion%} + ')';
   oxTSplashWindow.InformationOverImage := true;

   TProcedures.Initialize(oxTSplashWindow.OnOpen, 8);

   { set dvars }
   ox.dvar.Add('splash', dvgSplash);
   dvgSplash.Add(dvSplashShowOnStart, 'showOnStart', dtcBOOL, @oxTSplashWindow.ShowOnStart);

   { set init }
   ox.Init.Add('ox.splash', @initialize, @deinitialize);

   ox.OnStart.Add('ox.splash', @splashStart);
END.
