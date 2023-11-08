{
   oxuAndroidPlatform, android platform
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidPlatform;

INTERFACE

   USES
      ctypes, looper, input, android_native_app_glue, android_keycodes, native_window,
      uStd, uLog, StringUtils,
      {egl}
      egl, oxuglWindow,
      {app}
      uApp, appuEvents, appuKeys, appuKeyEvents, appuMouse, appuMouseEvents, appuActionEvents,
      {oX}
      uOX, oxuInitialize, oxuViewport,
      oxuWindow, oxuWindowHelper,
      oxuPlatform, oxuPlatforms, oxuWindowTypes,
      oxuRenderer, oxuRenderThread, oxuRenderingContext,
      {ui}
      uiuTypes, uiuWindowTypes, uiuWindow;

TYPE
   { oxTAndroidPlatform }

   oxTAndroidPlatform = class(oxTPlatform)
      constructor Create(); override;
      function Initialize(): boolean; override;

      function MakeWindow({%H-}wnd: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;
      function SetupBuffer(wnd: oxTWindow): boolean;

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

   { oxTAndroidPlatformGlobal }

   oxTAndroidPlatformGlobal = record
      {recreate the surface}
      fRecreateSurface,
      fHaveFocus,
      fLostFocus,
      fRegainedFocus,
      fInitWindow,
      fLostWindow,
      fStarted,
      fDone: boolean;

      {signal hide the navbar}
      HideNavbar,
      {if true, will automatically hide the navbar}
      AutoHideNavBar: boolean;

      {platform object}
      Platform: oxTAndroidPlatform;

      procedure RecreateSurface();
      procedure RegainedFocus();
      procedure DestroyWindow();
   end;

VAR
   AndroidApp: Pandroid_app;
   {android platform global}
   oxAndroidPlatform: oxTAndroidPlatformGlobal;

procedure AndroidHandleCommand(app: Pandroid_app; cmd: cint32);
function AndroidHandleInput(app: Pandroid_app; event: PAInputEvent): cint32;
procedure AndroidProcessEvents();

IMPLEMENTATION

procedure AndroidHandleCommand(app: Pandroid_app; cmd: cint32);
begin
   if(cmd = APP_CMD_INIT_WINDOW) then begin
      oxAndroidPlatform.fInitWindow := true;
   end else if(cmd = APP_CMD_TERM_WINDOW) then begin
      if(ox.Started) then begin
         oxRenderingContext.CanRender := false;
         oxAndroidPlatform.fLostWindow := true;
      end;
   end else if(cmd = APP_CMD_GAINED_FOCUS) then begin
      log.v('android > Gained focus');

      if(oxWindow.Current <> nil) then begin
         oxWindow.Current.Select();
         oxAndroidPlatform.fRegainedFocus := true;
         oxAndroidPlatform.fHaveFocus := true;
         oxAndroidPlatform.fLostFocus := false;

         if(oxAndroidPlatform.AutoHideNavBar) then
            oxAndroidPlatform.hideNavbar := true;
      end;
   end else if(cmd = APP_CMD_LOST_FOCUS) then begin
      log.v('android > Lost focus');

      if(oxWindow.Current <> nil) then
         oxWindow.Current.Deselect();

      oxAndroidPlatform.fHaveFocus := false;
      oxAndroidPlatform.fLostFocus := true;
      oxAndroidPlatform.fRegainedFocus := false;
      oxRenderingContext.CanRender := false;

      if(oxAndroidPlatform.fStarted) then
         oxAndroidPlatform.fStarted := false;
   end else if(cmd = APP_CMD_DESTROY) then begin
      oxAndroidPlatform.fDone := true;
   end;
end;

procedure getKeyEvent(kc, action, etype: cint32);
var
   k: appTKey;
   e: appPEvent;

begin
   if(kc = AKEYCODE_BACK) then begin
      if(action = AKEY_STATE_UP) then
         appActionEvents.QueueQuitEvent();
   end;

   k.Code := 0;
   k.State := 0;

   {translate key code}
   if(kc <= 255) then
      k.Code := appkRemapCodes[kc];

   {set key state}
   if(action <> AKEY_STATE_UP) then
      k.State.Prop(kmDOWN);

   e := appKeyEvents.Queue(k);
   e^.wnd := oxWindow.Current;
end;

procedure getMotionEvent(kc, action, etype: cint32; event: PAInputEvent);
var
   pointerCount: csize_t;
   i: loopint;
   x, y: single;

   m: appTMouseEvent;
   e: appPEvent;

begin
   pointerCount := AMotionEvent_getPointerCount(event);

   for i := 0 to pointerCount - 1 do begin
      appm.Init(m);

      x := AMotionEvent_getX(event, i);
      y := AMotionEvent_getY(event, i);

      m.x := x;
      m.y := oxWindow.Current.Dimensions.h - 1 - y;

      m.Button := appmcLEFT;

      if(action = AKEY_EVENT_ACTION_UP) then
         m.Action := appmcRELEASED
      else
         m.Action := appmcPRESSED;

      e := appMouseEvents.Queue(m);
      e^.wnd := oxWindow.Current;
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
      getKeyEvent(kc, action, etype);
   end else if(etype = AINPUT_EVENT_TYPE_MOTION) then begin
      getMotionEvent(kc, action, etype, event);
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

{ oxTAndroidPlatformGlobal }

procedure oxTAndroidPlatformGlobal.RecreateSurface();
var
   renderer: oxTRenderer;
   wnd: oxTWindow;

begin
   if(not fRecreateSurface) then
      exit;

   wnd := oxWindow.Current;
   renderer := oxTRenderer(wnd.Renderer);

   renderer.PreserveRCs := true;
   renderer.PreInitWindow(wnd);
   oxTAndroidPlatform(wnd.Platform).SetupBuffer(wnd);
   renderer.InitWindow(wnd);
   renderer.SetupWindow(wnd);

   if(wnd.ErrorCode <> 0) then
      log.e('Failed to restore window: ' + sf(wnd.ErrorCode) + '/' + wnd.ErrorDescription);

   fRecreateSurface := false;
   fRegainedFocus := true;
end;

procedure oxTAndroidPlatformGlobal.RegainedFocus();
begin
   if(not fRegainedFocus) then
      exit;

   oxWindow.Current.Viewport.Apply();
   oxRenderThread.StartThread(oxWindow.Current, oxWindow.Current.RenderingContext);
   oxRenderingContext.CanRender := true;

   fRegainedFocus := false;
end;

procedure oxTAndroidPlatformGlobal.DestroyWindow();
var
   renderer: oxTRenderer;

begin
   renderer := oxTRenderer(oxWindow.Current.Renderer);

   renderer.PreserveRCs := true;
   renderer.DeInitWindow(oxWindow.Current);

   fLostWindow := false;
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
   oxAndroidPlatform.Platform := Self;
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
   wnd.Properties := wnd.Properties - [uiwndpRESIZABLE, uiwndpMOVABLE];
   Include(wnd.Properties, uiwndpMAXIMIZED);

   {initialize gl for window}
   if(not oxTRenderer(wnd.Renderer).PreInitWindow(wnd)) then begin
      wnd.RaiseError('android > egl preinit failed');
      exit(false);
   end;

   if(not SetupBuffer(wnd)) then begin
      wnd.RaiseError('android > failed to setup window buffer');
      exit(false);
   end;

   {initialize window}
   if(not oxTRenderer(wnd.Renderer).InitWindow(wnd)) then begin
      wnd.RaiseError('android > egl window create failed.');
      exit(false);
   end;

   wnd.SetPosition(0, wnd.Dimensions.h - 1, false);
   wnd.SetDimensions(wnd.Dimensions.w, wnd.Dimensions.h, false);

   Result := true;
end;

function oxTAndroidPlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   Result := true;

   if(wnd.Renderer <> nil) then
      Result := oxTRenderer(wnd.Renderer).DeInitWindow(wnd);
end;

function oxTAndroidPlatform.SetupBuffer(wnd: oxTWindow): boolean;
var
   glwnd: oglTWindow;
   format: EGLint;

begin
   Result := false;
   glwnd := oglTWindow(wnd);

   if eglGetConfigAttrib(glwnd.wd.Display, glwnd.wd.Config, EGL_NATIVE_VISUAL_ID, @format) = EGL_FALSE then begin
      wnd.RaiseError('egl > Failed to get EGL_NATIVE_VISUAL_ID');
      exit(false);
   end;

   if(ANativeWindow_setBuffersGeometry(AndroidApp^.window, 0, 0, format) <> 0) then begin
      wnd.RaiseError('egl > Failed to set window buffers geometry');
      exit(false);
   end;

   Result := true;
end;

procedure oxTAndroidPlatform.ProcessEvents();
begin
   AndroidProcessEvents();
end;

INITIALIZATION
//   oxAndroidPlatform.AutoHideNavBar := true;
   oxPlatforms.Register(oxTAndroidPlatform);

END.
