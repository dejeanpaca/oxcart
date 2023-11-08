{
   oxuAndroidPlatform, android platform
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidPlatform;

INTERFACE

   USES
      ctypes, looper, input, android_native_app_glue, android_keycodes, android_log_helper,
      uStd,
      {app}
      uApp, appuMouse, appuActionEvents,
      {oX}
      uOX, oxuRun, oxuInit,
      oxuWindow, uiuWindow,
      oxuPlatform, oxuPlatforms, oxuWindowTypes, oxuRenderer;

TYPE
   { oxTAndroidPlatform }

   oxTAndroidPlatform = class(oxTPlatform)
      constructor Create(); override;
      function Initialize(): boolean; override;

      function MakeWindow({%H-}wnd: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;

      procedure ProcessEvents(); override;
   end;

   { TAndroidPointerDriver }

   TAndroidPointerDriver = class(appTPointerDriver)
      LastX,
      LastY: loopint;

      constructor Create();

      procedure getXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure setXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure hide(devID: longint; {%H-}wnd: pointer); override;
      procedure show(devID: longint; {%H-}wnd: pointer); override;
   end;

VAR
   AndroidApp: Pandroid_app;

procedure AndroidHandleCommand(app: Pandroid_app; cmd: cint32);
function AndroidHandleInput(app: Pandroid_app; event: PAInputEvent): cint32;
procedure AndroidProcessEvents();

IMPLEMENTATION

procedure AndroidHandleCommand(app: Pandroid_app; cmd: cint32);
begin
   if(cmd = APP_CMD_INIT_WINDOW) then begin
      if(not ox.Initialized) and (not ox.Started) then
         oxRun.Initialize()
      else begin
         if(ox.Started) then begin
            oxTRenderer(oxWindow.Current.Renderer).PreInitWindow(oxWindow.Current);
            oxTRenderer(oxWindow.Current.Renderer).InitWindow(oxWindow.Current);
            oxTRenderer(oxWindow.Current.Renderer).SetupWindow(oxWindow.Current);
         end;
      end;
   end else if(cmd = APP_CMD_TERM_WINDOW) then begin
      if(ox.Started) then begin
         oxTRenderer(oxWindow.Current.Renderer).DestroyContext(oxWindow.Current.RenderingContext);
         oxTRenderer(oxWindow.Current.Renderer).DestroyContext(oxWindow.Current.ThreadRenderingContext);
         oxWindow.Current.RenderingContext := -1;
         oxWindow.Current.ThreadRenderingContext := -1;
         oxTRenderer(oxWindow.Current.Renderer).DeInitWindow(oxWindow.Current);
      end;
   end else if(cmd = APP_CMD_GAINED_FOCUS) then begin
      if(oxWindow.Current <> nil) then
         oxWindow.Current.Select();
   end else if(cmd = APP_CMD_LOST_FOCUS) then begin
      if(oxWindow.Current <> nil) then
         oxWindow.Current.Deselect();
   end else if(cmd = APP_CMD_DESTROY) then begin
      oxRun.Done();
      oxInitialization.Deinitialize();
   end;
end;

function AndroidHandleInput(app: Pandroid_app; event: PAInputEvent): cint32;
var
   kc,
   action,
   etype: cint32;

begin
   etype := AInputEvent_getType(event);

   kc := AKeyEvent_getKeyCode(event);
   action := AKeyEvent_getAction(event);

   if(etype = AINPUT_EVENT_TYPE_KEY) then begin
      if(kc = AKEYCODE_BACK) then begin
         if(action = AKEY_STATE_UP) then
            appActionEvents.QueueQuitEvent();
      end;
   end;

   Result := 0;
end;

procedure AndroidProcessEvents();
var
   ident,
   nEvents: cint;
   pSource: Pandroid_poll_source;

begin
   nEvents := 0;
   pSource := nil;

   ident := ALooper_pollAll(0, nil, @nEvents, @pSource);

   if(ident >= 0) then begin
      if(pSource <> nil) then begin
         pSource^.process(AndroidApp, pSource);
      end;
   end;
end;

{ TAndroidPointerDriver }

constructor TAndroidPointerDriver.Create();
begin
   Name := 'android';
end;

procedure TAndroidPointerDriver.getXY(devID: longint; wnd: pointer; out x, y: single);
begin
   inherited getXY(devID, wnd, x, y);
end;

procedure TAndroidPointerDriver.setXY(devID: longint; wnd: pointer; x, y: single);
begin
   inherited setXY(devID, wnd, x, y);
end;

procedure TAndroidPointerDriver.hide(devID: longint; wnd: pointer);
begin
   inherited hide(devID, wnd);
end;

procedure TAndroidPointerDriver.show(devID: longint; wnd: pointer);
begin
   inherited show(devID, wnd);
end;

{ oxTAndroidPlatform }

constructor oxTAndroidPlatform.Create();
begin
   Name := 'android';
end;

function oxTAndroidPlatform.Initialize(): boolean;
begin
   { pointer driver }
   PointerDriver := TAndroidPointerDriver.Create();

   Result := true;
end;

function oxTAndroidPlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   Result := false;

   {don't render when window has no focus}
   wnd.oxProperties.RenderUnfocused := false;

   {initialize gl for window}
   if(not oxTRenderer(wnd.Renderer).PreInitWindow(wnd)) then begin
      wnd.RaiseError('Preinit failed');
      exit;
   end;

   {initialize window}
   if(not oxTRenderer(wnd.Renderer).InitWindow(wnd)) then begin
      wnd.RaiseError('Renderer window create failed.');
      exit;
   end;

   Result := true;
end;

function oxTAndroidPlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   Result := true;

   if(wnd.Renderer <> nil) then
      Result := oxTRenderer(wnd.Renderer).DeInitWindow(wnd);
end;

procedure oxTAndroidPlatform.ProcessEvents();
begin
   AndroidProcessEvents();
end;

INITIALIZATION
   oxPlatforms.Register(oxTAndroidPlatform);

END.
