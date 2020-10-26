{
   oxuglRendererEGL, gl egl renderer
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererEGL;

INTERFACE

   USES
      uStd, uLog,
      egl,
      {ox.gl}
      oxuOGL, oxuglWindow,
      oxuglRendererPlatform, oxuglRenderer,
      {android}
      oxuAndroidPlatform;

TYPE
   { oxglTEGL }

   oxglTEGL = object(oxglTPlatform)
      Major,
      Minor: longint;

      constructor Create();

      function RaiseError(): loopint; virtual;

      function PreInitWindow(wnd: oglTWindow): boolean; virtual;
      function OnDeInitWindow(wnd: oglTWindow): boolean; virtual;
      function GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext; virtual;
      function ContextCurrent(wnd: oglTWindow; context: oglTRenderingContext): boolean; virtual;
      function ClearContext(wnd: oglTWindow): boolean; virtual;
      function DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean; virtual;
      procedure SwapBuffers(wnd: oglTWindow); virtual;
   end;

VAR
   oxglEGL: oxglTEGL;

IMPLEMENTATION

{ oxglTEGL }

function oxglTEGL.RaiseError(): loopint;
begin
   Result := eglGetError();

   {we always set success as 0}
   if(Result = EGL_SUCCESS) then
      Result := 0;
end;

constructor oxglTEGL.Create();
begin
   Name := 'egl';
end;

function oxglTEGL.PreInitWindow(wnd: oglTWindow): boolean;
var
   attribs: array[0..8] of EGLint = (
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_BLUE_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_RED_SIZE, 8,
      EGL_NONE
   );

   i: longint;
   w,
   h,
   format: EGLint;
   numConfigs: EGLint;
   cfg,
   config: EGLConfig;
   surface: EGLSurface;
   supportedConfigs: array of EGLConfig;

   r, g, b, d: EGLint;

begin
   Result := false;
   wnd.wd.Display := eglGetDisplay(EGL_DEFAULT_DISPLAY);

   if(wnd.wd.Display <> nil) then
      eglInitialize(wnd.wd.Display, nil, nil)
   else begin
      log.e('Failed to get default EGL display');
      exit(false);
   end;

   supportedConfigs := nil;

   eglChooseConfig(wnd.wd.Display, attribs, nil, 0, @numConfigs);
   SetLength(supportedConfigs, numConfigs);
   eglChooseConfig(wnd.wd.Display, attribs, @supportedConfigs[0], numConfigs, @numConfigs);

   config := nil;

   for i := 0 to numConfigs do begin
       if(i = numConfigs) then
           break;

       cfg := supportedConfigs[i];

       if ((eglGetConfigAttrib(wnd.wd.Display, cfg, EGL_RED_SIZE, @r) <> 0) and
           (eglGetConfigAttrib(wnd.wd.Display, cfg, EGL_GREEN_SIZE, @g) <> 0) and
           (eglGetConfigAttrib(wnd.wd.Display, cfg, EGL_BLUE_SIZE,  @b) <> 0) and
           (eglGetConfigAttrib(wnd.wd.Display, cfg, EGL_DEPTH_SIZE, @d) <> 0) and
           (r = 8) and (g = 8) and (b = 8) and (d = 0) )  then begin
               config := supportedConfigs[i];
               break;
       end;
   end;

   if i = numConfigs then
      config := supportedConfigs[0];

   if config = nil then begin
      wnd.RaiseError('Unable to initialize EGLConfig');
      exit(false);
   end;

   if eglGetConfigAttrib(wnd.wd.Display, config, EGL_NATIVE_VISUAL_ID, @format) = EGL_FALSE then begin
      wnd.RaiseError('Failed to get EGL_NATIVE_VISUAL_ID');
      exit(false);
   end;

   wnd.wd.Config := config;

   surface := eglCreateWindowSurface(wnd.wd.Display, config, AndroidApp^.window, nil);

   if(surface = nil) then begin
      wnd.RaiseError('Failed to create window surface');
      exit(false);
   end;

   wnd.wd.Surface := surface;

   eglQuerySurface(wnd.wd.Display, surface, EGL_WIDTH, @w);
   eglQuerySurface(wnd.wd.Display, surface, EGL_HEIGHT, @h);

   wnd.Dimensions.Assign(w, h);

   Result := true;
end;

function oxglTEGL.OnDeInitWindow(wnd: oglTWindow): boolean;
begin
   if(wnd.wd.Surface <> EGL_NO_SURFACE) then
      eglDestroySurface(wnd.wd.display, wnd.wd.Surface);

   if(wnd.wd.Display <> EGL_NO_DISPLAY) then
      eglTerminate(wnd.wd.Display);

   wnd.wd.Display := EGL_NO_DISPLAY;
   wnd.wd.Surface := EGL_NO_SURFACE;
   Result := true;
end;

function oxglTEGL.GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext;
begin
   if(wnd.wd.Display <> nil) and (wnd.wd.Config <> nil) then
      Result := eglCreateContext(wnd.wd.Display, wnd.wd.Config, shareContext, nil)
   else
      Result := nil;
end;

function oxglTEGL.ContextCurrent(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   Result := eglMakeCurrent(wnd.wd.Display, wnd.wd.Surface, wnd.wd.Surface, context) <> EGL_FALSE;
end;

function oxglTEGL.ClearContext(wnd: oglTWindow): boolean;
begin
   Result := eglMakeCurrent(wnd.wd.Display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT) <> EGL_FALSE;
end;

function oxglTEGL.DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   Result := eglDestroyContext(wnd.wd.Display, context) <> EGL_FALSE;
end;

procedure oxglTEGL.SwapBuffers(wnd: oglTWindow);
begin
   if(wnd.wd.Display <> nil) and (wnd.wd.Surface <> nil) then
      eglSwapBuffers(wnd.wd.Display, wnd.wd.Surface);
end;

INITIALIZATION
   oxglEGL.Create();
   oxglTRenderer.glPlatform := @oxglEGL;

END.
