{
   oxuglRendererEGL, gl egl renderer
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererEGL;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      egl,
      {ox}
      oxuTypes, oxuRenderer,
      {ox.gl}
      oxuOGL, oxuglWindow, oxuglRendererPlatform, oxuglRenderer,
      {android}
      oxuAndroidPlatform;

TYPE
   { oxglTEGL }

   oxglTEGL = object(oxglTPlatform)
      Major,
      Minor: longint;

      constructor Create();

      function RaiseError(): loopint; virtual;
      function GetErrorDescription(error: loopint): StdString; virtual;

      function PreInitWindow(wnd: oglTWindow): boolean; virtual;
      function OnDeInitWindow(wnd: oglTWindow): boolean; virtual;
      function GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext; virtual;
      function ContextCurrent(const context: oxTRenderTargetContext): boolean; virtual;
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

function oxglTEGL.GetErrorDescription(error: loopint): StdString;
begin
   Result := '$' + HexStr(error, 4);
end;

constructor oxglTEGL.Create();
begin
   Name := 'egl';
end;

function oxglTEGL.PreInitWindow(wnd: oglTWindow): boolean;
var
   attribs: array[0..12] of EGLint = (
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_BLUE_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_RED_SIZE, 8,
      EGL_DEPTH_SIZE, 24,
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES_BIT,
      EGL_NONE
   );

   i: longint;
   w,
   h,
   format: EGLint;
   numConfigs: EGLint;
   cfg,
   config: EGLConfig;
   supportedConfigs: array of EGLConfig;

   r, g, b, d: EGLint;

   eglMajor,
   eglMinor: EGLint;

begin
   Result := false;

   oxRenderer.logtv('egl > initialize');

   if(wnd.wd.Display = nil) then begin
      wnd.wd.Display := eglGetDisplay(EGL_DEFAULT_DISPLAY);

      if(wnd.wd.Display <> nil) then begin
         eglInitialize(wnd.wd.Display, @eglMajor, @eglMinor);
         oxRenderer.logtv('egl > Initialized display');

         if(not wnd.oxProperties.Created) then begin
            log.v('EGL Vendor: ' + eglQueryString(wnd.wd.Display, EGL_VENDOR));
            log.v('EGL Version: ' + sf(eglMajor) + '.' + sf(eglMinor) + ' / ' + eglQueryString(wnd.wd.Display, EGL_VERSION));
         end;
      end;
   end;

   if(wnd.wd.Display = nil) then begin
      oxRenderer.logte('egl > Failed to get default EGL display');
      exit(false);
   end;

   if(wnd.wd.Config = nil) then begin
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
      oxRenderer.logtv('egl > Found a config');
   end;

   if(wnd.wd.Surface = nil) then begin
      wnd.wd.Surface := eglCreateWindowSurface(wnd.wd.Display, config, AndroidApp^.window, nil);

      if(wnd.wd.Surface = nil) then begin
         wnd.RaiseError('Failed to create window surface, egl error: ' + HexStr(RaiseError(), 4));
         exit(false);
      end;

      oxRenderer.logtv('egl > Created window surface');
      wnd.wd.ValidSurface := true;
   end;

   eglQuerySurface(wnd.wd.Display, wnd.wd.Surface, EGL_WIDTH, @w);
   eglQuerySurface(wnd.wd.Display, wnd.wd.Surface, EGL_HEIGHT, @h);
   oxRenderer.logtv('egl > Surface dimensions: ' + sf(w) + 'x' + sf(h));

   wnd.Dimensions.Assign(w, h);

   Result := true;
end;

function oxglTEGL.OnDeInitWindow(wnd: oglTWindow): boolean;
begin
   oxRenderer.logtv('egl > deinitialize');

   if(wnd.wd.Surface <> EGL_NO_SURFACE) then begin
      eglDestroySurface(wnd.wd.Display, wnd.wd.Surface);
      wnd.wd.Surface := EGL_NO_SURFACE;
      oxRenderer.logtv('egl > Destroyed surface');
   end;

   if(not oxglRenderer.PreserveRCs) then begin
      if(wnd.wd.Display <> EGL_NO_DISPLAY) then begin
         eglTerminate(wnd.wd.Display);
         wnd.wd.Display := EGL_NO_DISPLAY;
         oxRenderer.logtv('egl > Terminated display');
      end;
   end;

   Result := true;
end;

function oxglTEGL.GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext;
var
   attribs: array[0..2] of EGLenum = (
      EGL_CONTEXT_CLIENT_VERSION, 1,
      EGL_NONE
   );

begin
   if(wnd.wd.Display <> nil) and (wnd.wd.Config <> nil) then
      Result := eglCreateContext(wnd.wd.Display, wnd.wd.Config, shareContext, @attribs)
   else
      Result := nil;
end;

function oxglTEGL.ContextCurrent(const context: oxTRenderTargetContext): boolean;
var
   wnd: oglTWindow;
   glrc: oglTRenderingContext;

begin
   if(context.Target^.Typ = oxRENDER_TARGET_WINDOW) then begin
      wnd := oglTWindow(context.Target^.Target);

      if(wnd.wd.Display = EGL_NO_DISPLAY) then
         exit;

      glrc := oxglRenderer.glRenderingContexts[context.RenderContext];

      Result := eglMakeCurrent(wnd.wd.Display, wnd.wd.Surface, wnd.wd.Surface, glrc) <> EGL_FALSE;
   end;
end;

function oxglTEGL.ClearContext(wnd: oglTWindow): boolean;
begin
   if(wnd.wd.Display <> EGL_NO_DISPLAY) then
      Result := eglMakeCurrent(wnd.wd.Display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT) <> EGL_FALSE
   else
      Result := true;
end;

function oxglTEGL.DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   if(wnd.wd.Display <> EGL_NO_DISPLAY) then
      Result := eglDestroyContext(wnd.wd.Display, context) <> EGL_FALSE
   else
      Result := true;
end;

procedure oxglTEGL.SwapBuffers(wnd: oglTWindow);
var
   error: EGLenum;

begin
   if(wnd.wd.Display <> nil) and (wnd.wd.Surface <> nil) and (wnd.wd.ValidSurface) then begin
      if(eglSwapBuffers(wnd.wd.Display, wnd.wd.Surface) <> EGL_TRUE) then begin
         error := RaiseError();
         wnd.wd.ValidSurface := false;
         oxRenderer.logte('egl > Cannot swap buffers on surface ' + sf(wnd.wd.Surface) + ', egl error: ' + HexStr(error, 4));
      end;
   end;
end;

INITIALIZATION
   oxglEGL.Create();
   oxglTRenderer.glPlatform := @oxglEGL;

END.
