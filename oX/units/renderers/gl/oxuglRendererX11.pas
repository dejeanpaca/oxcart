{
   oxuglRendererX11, gl renderer X11 (linux/unix) platform component
   Copyright (c) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglRendererX11;

INTERFACE

   USES
      x, xlib, xutil, GLX,
      uStd, uLog, StringUtils,
      oxuRenderer, oxuWindowTypes,
      {renderer.gl}
      oxuOGL, oxuglExtensions, oxuglRendererPlatform, oxuglRenderer,
      oxuX11Platform, oxuGLX;

CONST
   glxSupported: boolean      = false;

TYPE
   { oxglxTGlobal }

   oxglxTGlobal = object(oxglTPlatform)
      Major,
      Minor: longint;

      procedure OnInitialize(); virtual;
      function PreInitWindow(wnd: oglTWindow): boolean; virtual;
      procedure SwapBuffers(wnd: oglTWindow); virtual;

      function GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext = default(oglTRenderingContext)): oglTRenderingContext; virtual;
      function ContextCurrent(wnd: oglTWindow; context: oglTRenderingContext): boolean; virtual;
      function ClearContext(wnd: oglTWindow): boolean; virtual;
      function DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean; virtual;
   end;

VAR
   oxglx: oxglxTGlobal;

IMPLEMENTATION

procedure ExpandAttributes(wnd: oglTWindow; var attr: TXAttrIntSimpleList; fb: boolean = false);
begin
   if(wnd.RenderSettings.ColorBits >= 24) then begin
      attr.Add(GLX_RED_SIZE, 8);
      attr.Add(GLX_GREEN_SIZE, 8);
      attr.Add(GLX_BLUE_SIZE, 8);

      if(wnd.RenderSettings.ColorBits = 32) then
         attr.Add(GLX_ALPHA_SIZE, 8);
   end else if(wnd.RenderSettings.ColorBits = 16) then begin
      attr.Add(GLX_RED_SIZE, 4);
      attr.Add(GLX_GREEN_SIZE, 5);
      attr.Add(GLX_BLUE_SIZE, 4);
   end else begin
      attr.Add(GLX_RED_SIZE, 1);
      attr.Add(GLX_GREEN_SIZE, 1);
      attr.Add(GLX_BLUE_SIZE, 1);
   end;

   if(wnd.RenderSettings.DepthBits > 0) then
      attr.Add(GLX_DEPTH_SIZE, wnd.RenderSettings.DepthBits);

   if(wnd.RenderSettings.StencilBits > 0) then
      attr.Add(GLX_STENCIL_SIZE, wnd.RenderSettings.StencilBits);

   if(wnd.RenderSettings.DoubleBuffer) then begin
      if(fb) then
         attr.Add(GLX_DOUBLEBUFFER, 1)
      else
         attr.Add(GLX_DOUBLEBUFFER);
   end;

   if(wnd.RenderSettings.AccumBits > 0) then begin
      attr.Add(GLX_ACCUM_RED_SIZE, wnd.RenderSettings.AccumBits);
      attr.Add(GLX_ACCUM_GREEN_SIZE, wnd.RenderSettings.AccumBits);
      attr.Add(GLX_ACCUM_BLUE_SIZE, wnd.RenderSettings.AccumBits);
      attr.Add(GLX_ACCUM_ALPHA_SIZE, wnd.RenderSettings.AccumBits);
   end;
end;

function chooseVisual(wnd: oglTWindow): boolean;
var
   attr: TXAttrIntSimpleList;

begin
   attr.Initialize(attr);

   attr.Add(GLX_RGBA);
   ExpandAttributes(wnd, attr);
   attr.Add(None);

   {get a glx visual}
   wnd.wd.VisInfo := glXChooseVisual(x11.DPY, DefaultScreen(x11.DPY), @attr.List[0]);
   if(wnd.wd.VisInfo = nil) then begin
      wnd.CreateFail('glx > Error: Unable to find visual.');
      exit(false);
   end;

   Result := true;
end;

function chooseVisualFB(wnd: oglTWindow): boolean;
var
   i: loopint;

   fbcount,
   bestFbc,
   worstFbc,
   bestNumSamples,
   worstNumSamples,
   sampleBuffers,
   samples: LongInt;
   fbc: PGLXFBConfig;

   vi: PXVisualInfo;

begin
   wnd.glxAttribs.Add(GLX_X_RENDERABLE, 1);
   wnd.glxAttribs.Add(GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT);
   wnd.glxAttribs.Add(GLX_RENDER_TYPE, GLX_RGBA_BIT);
   wnd.glxAttribs.Add(GLX_X_VISUAL_TYPE, GLX_TRUE_COLOR);

   ExpandAttributes(wnd, wnd.glxAttribs, true);

   wnd.glxAttribs.Add(None);

   fbcount := 0;
   fbc := glXChooseFBConfig(x11.DPY, DefaultScreen(x11.DPY), @wnd.glxAttribs.List[0], fbcount);
   wnd.wd.LastError := x11.GetError();

   // Pick the FB config/visual with the most samples per pixel
   bestFbc := -1;
   worstFbc := -1;
   bestNumSamples := -1;
   worstNumSamples := 9999;
   sampleBuffers := 0;
   samples := 0;

   if(fbc <> nil) then begin
      log.v('Found ' + sf(fbcount) + ' fb configs');

      for i := 0 to fbcount - 1 do begin
         vi := glXGetVisualFromFBConfig(x11.DPY, fbc[i]);

         if(vi <> nil) then begin
            glXGetFBConfigAttrib(x11.DPY, fbc[i], GLX_SAMPLE_BUFFERS, sampleBuffers);
            glXGetFBConfigAttrib(x11.DPY, fbc[i], GLX_SAMPLES, samples);

            if(bestFbc < 0) or (sampleBuffers > 0) and (samples > bestNumSamples) then begin
               bestFbc := i;
               bestNumSamples := samples;
            end;

            if(worstFbc < 0) or (sampleBuffers = 0) or (samples < worstNumSamples) then begin
               worstFbc := i;
               worstNumSamples := samples;
            end;
         end;

         XFree(vi);
      end;

      wnd.fbConfig := fbc[bestFbc];

      XFree(fbc);

      vi := glXGetVisualFromFBConfig(x11.DPY, wnd.fbConfig);
      wnd.wd.LastError := x11.GetError();
      if(vi <> nil) then begin
         wnd.wd.VisInfo := vi;

         log.v('Chose visual config: ' + sf(vi^.visualid));
         exit(true);
      end else
         wnd.CreateFail('glx > Error: Failed to get chosen fb config (' + sf(bestFbc) + ')');
   end else
      wnd.CreateFail('glx > Error: Unable to find fb config');

   Result := false;
end;

procedure oxglxTGlobal.OnInitialize();
var
   errorBase: longint      = 0;
   eventBase: longint      = 0;

begin
   {$IFDEF OX_LIBRARY}
   glxSupported := true;
   exit;
   {$ENDIF}

   {check for the GLX extension}
   if(glXQueryExtension(x11.DPY, errorBase, eventBase)) then begin
      glxSupported := true;
   end else begin
      log.e('glx extension is not supported.');
      exit;
   end;

   { query GLX version }
   if(glXQueryVersion(x11.DPY, Major, Minor)) then
      log.i('glx > Version: ' + sf(major) + '.' + sf(minor))
   else
      log.e('glx > Failed to retrieve version: ' + sf(major) + '.' + sf(minor));
end;

function oxglxTGlobal.PreInitWindow(wnd: oglTWindow): boolean;
var
   requiresContext: Boolean;

begin
   requiresContext := ogl.ContextRequired(wnd.glDefault);

   if(not requiresContext) then
      Result := chooseVisual(wnd)
   else
      Result := chooseVisualFB(wnd);
end;

procedure oxglxTGlobal.SwapBuffers(wnd: oglTWindow);
begin
   if(x11.DPY <> nil) then begin
      if(wnd.wd.h <> 0) and (x11.DPY <> nil) then begin
         glXSwapBuffers(x11.DPY, wnd.wd.h);
         wnd.wd.LastError := x11.GetError();
      end;
   end;
end;

function getContextAttribs(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext;
var
   attr: TXAttrIntSimpleList;
   extContext: boolean;
   contextFlags: LongInt;

begin
   attr.Initialize(attr);

   extContext := oglExtensions.PlatformSupported(cGLX_ARB_create_context);

   if(not extContext) then begin
      if(not oglTWindow(wnd).Downgrade32()) then
         exit(nil);
   end;

   attr.Add(GLX_CONTEXT_MAJOR_VERSION_ARB,   wnd.gl.Version.Major);
   attr.Add(GLX_CONTEXT_MINOR_VERSION_ARB,   wnd.gl.Version.Minor);

   contextFlags := 0;
   {$IFDEF OX_DEBUG}
   contextFlags := contextFlags or GLX_CONTEXT_DEBUG_BIT_ARB;
   log.v('gl > Using debug context');
   {$ENDIF}

   if(contextFlags <> 0) then
      attr.add(GLX_CONTEXT_FLAGS_ARB, contextFlags);

   if(extContext) then begin
      if(wnd.gl.Version.Profile = oglPROFILE_ANY) then begin
         log.v('gl > Using any profile');
         attr.Add(GLX_CONTEXT_PROFILE_MASK_ARB, GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB or GLX_CONTEXT_CORE_PROFILE_BIT_ARB);
      end else if(wnd.gl.Version.Profile = oglPROFILE_COMPATIBILITY) then begin
         log.v('gl > Using compatibility profile');
         attr.Add(GLX_CONTEXT_PROFILE_MASK_ARB, GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB);
      end else if(wnd.gl.Version.Profile = oglPROFILE_CORE) then begin
         log.v('gl > Using core profile');
         attr.Add(GLX_CONTEXT_PROFILE_MASK_ARB, GLX_CONTEXT_CORE_PROFILE_BIT_ARB);
      end;
   end;

   attr.Add(None);

   Result := glXCreateContextAttribsARB(x11.DPY, wnd.fbConfig, shareContext, true, @attr.List[0])
end;

function oxglxTGlobal.GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext;
var
   method: string;
   extContextProfile,
   requiresContext: boolean;

begin
   {requires new context creation for opengl 3.0 and higher}
   requiresContext := ogl.ContextRequired(wnd.glDefault);
   extContextProfile := oglExtensions.PlatformSupported(cGLX_ARB_create_context_profile);

   if(requiresContext) and (extContextProfile) then begin
      method := 'CreateContextAttribs';
      Result := getContextAttribs(wnd, shareContext);
   end else begin
      method := 'CreateContext';
      Result := glXCreateContext(x11.DPY, wnd.wd.VisInfo, shareContext, true);
   end;

   wnd.wd.LastError := x11.GetError();

   if(Result = nil) then
      log.e('gl > (' + method + ') Failed getting rendering context ' + x11.LastErrorDescription)
   else
      log.v('gl > (' + method + ') Got rendering context');
end;

function oxglxTGlobal.ContextCurrent(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   glXMakeCurrent(x11.DPY, wnd.wd.h, context);
   wnd.wd.LastError := x11.GetError();
   Result := wnd.wd.LastError = 0;
end;

function oxglxTGlobal.ClearContext(wnd: oglTWindow): boolean;
begin
   glXMakeCurrent(x11.DPY, 0, nil);
   wnd.wd.LastError := x11.GetError();
   Result := wnd.wd.LastError = 0;
end;

function oxglxTGlobal.DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   glXDestroyContext(x11.DPY, context);
   wnd.wd.LastError := x11.GetError();
   Result := wnd.wd.LastError = 0;
end;


INITIALIZATION
   oxglx.Create();
   oxglTRenderer.glPlatform := @oxglx;

END.
