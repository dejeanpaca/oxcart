{
   oxuglRendererWin, gl renderer windows platform component
   Copyright (c) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererWin;

INTERFACE

	USES
     uStd, uLog, StringUtils,
     windows,
     {ox}
     oxuTypes, oxuWindowsOS, oxuRenderer,
     {gl}
     {$INCLUDE usesglext.inc},
     oxuOGL, oxuglExtensions, oxuglRendererPlatform, oxuglRenderer, oxuglWindow
     {$IFNDEF GLES}
     ,oxuWGL
     {$ENDIF};

TYPE
   { oxglTPlatformWGL }

   oxglTPlatformWGL = object(oxglTPlatform)
      constructor Create();
      function RaiseError(): loopint; virtual;
      function PreInitWindow(wnd: oglTWindow): boolean; virtual;
      procedure OnInitWindow({%H-}wnd: oglTWindow); virtual;
      procedure SwapBuffers(wnd: oglTWindow); virtual;
      function GetContext(wnd: oglTWindow; shareContext: HGLRC): HGLRC; virtual;
      function ContextCurrent(var target: oxTRenderTarget; context: oglTRenderingContext): boolean; virtual;
      function ClearContext({%H-}wnd: oglTWindow): boolean; virtual;
      function DestroyContext({%H-}wnd: oglTWindow; context: oglTRenderingContext): boolean; virtual;
   end;

VAR
   oxwgl: oxglTPlatformWGL;

IMPLEMENTATION

function buildPFD(wnd: oglTWindow; out pfd: PIXELFORMATDESCRIPTOR): boolean;
var
   objType,
   dwFlags: dword;
   renderer: oxTRenderer;

begin
   {build required pixel format}
   ZeroOut(pfd, SizeOf(pfd));

   pfd.nSize    := sizeof(pfd);
   pfd.nVersion := 1;

   objType := GetObjectType(wnd.wd.dc);

   renderer := oxTRenderer(wnd.Renderer);

   if(objType = 0) then begin
      if(winos.LogError('Failed to get dc object type') <> 0) then begin
         winosTWindow(wnd).wd.LastError := winos.LastError;
         wnd.ErrorDescription.Add(winos.LastErrorDescription);
         exit(false);
      end;
   end;

   dwFlags := PFD_SUPPORT_OPENGL;
   if(objType in oxwinMemoryDCs) then
      dwFlags := dwFlags or PFD_DRAW_TO_BITMAP
   else
      dwFlags := dwFlags or PFD_DRAW_TO_WINDOW;

   if(renderer.Settings.DoubleBuffer) then
      dwFlags := dwFlags or PFD_DOUBLEBUFFER;

   if(renderer.Settings.Software) then
      dwFlags := dwFlags or PFD_SUPPORT_GDI;

   if(renderer.Settings.Stereo) then
      dwFlags := dwFlags or PFD_STEREO;

   pfd.dwFlags       := dwFlags;
   pfd.iPixelType    := PFD_TYPE_RGBA;
   pfd.cColorBits    := renderer.Settings.ColorBits;
   pfd.cDepthBits    := renderer.Settings.DepthBits;
   pfd.iLayerType    := PFD_MAIN_PLANE;
   pfd.cStencilBits  := renderer.Settings.StencilBits;

   if(renderer.Settings.Layer = 0) then
      pfd.iLayerType := PFD_MAIN_PLANE
   else begin
      if(renderer.Settings.Layer > 0) then
         pfd.iLayerType := PFD_OVERLAY_PLANE
      else
         pfd.iLayerType := Byte(PFD_UNDERLAY_PLANE);
   end;

   Result := true;
end;

function setPF(wnd: oglTWindow; pFormat: longint; const pfd: PIXELFORMATDESCRIPTOR): boolean;
begin
   Result := SetPixelFormat(wnd.wd.dc, pFormat, @pfd);

   if(not Result) then begin
      log.e('Failed to SetPixelFormat with format ' + sf(pFormat));

      wnd.wd.LastError := winos.GetLastError();
      if(wnd.wd.LastError <> 0) then begin
         log.e('SetPixelFormat returned error: ' + winos.FormatMessage(wnd.wd.LastError));
      end;
   end;
end;

function getPF(wnd: oglTWindow; var pfd: PIXELFORMATDESCRIPTOR): longint;
var
   pFormat: longint;

begin
   windows.SetLastError(0);
   Result := 0;

   {find a suitable pixel format}
   pFormat  := ChoosePixelFormat(wnd.wd.dc, @pfd);

   if(pFormat = 0) then begin
      wnd.wd.LastError := winos.GetLastError();

      {Ignore any windows error if we got a pixel format.
      Because this is a standard behavior with some driver/windows combinations.}
      if(wnd.wd.LastError <> 0) then
         log.w('Error choosing pixel format: ' + winos.FormatMessage(wnd.wd.LastError));
   end;

   Result := pFormat;
end;

{$IFNDEF GLES}
function getPFARB(wnd: oglTWindow; var pfd: PIXELFORMATDESCRIPTOR): longint;
var
   vals: specialize TSimpleList<GLint>;
   pixelFormats: array[0..1023] of longint;
   nFormats: dword = 0;
   renderer: oxTRenderer;

begin
   renderer := oxTRenderer(wnd.Renderer);
   vals.Initialize(vals);

   vals.Add(WGL_DRAW_TO_WINDOW_ARB, 1);
   vals.Add(WGL_SUPPORT_OPENGL_ARB, 1);
   vals.Add(WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB);

   if(renderer.Settings.DoubleBuffer) then
      vals.Add(WGL_DOUBLE_BUFFER_ARB, 1);

   vals.Add(WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB);

   vals.Add(WGL_COLOR_BITS_ARB, renderer.Settings.ColorBits);
   vals.Add(WGL_DEPTH_BITS_ARB, renderer.Settings.DepthBits);

   vals.Add(WGL_STENCIL_BITS_ARB, renderer.Settings.StencilBits);
   vals.Add(WGL_ACCUM_BITS_ARB, renderer.Settings.AccumBits);

   if(renderer.Settings.ColorBits = 32) or (renderer.Settings.ColorBits = 24) then begin
      vals.Add(WGL_RED_BITS_ARB, 8);
      vals.Add(WGL_GREEN_BITS_ARB, 8);
      vals.Add(WGL_BLUE_BITS_ARB, 8);

      if(renderer.Settings.ColorBits = 32) then
         vals.Add(WGL_ALPHA_BITS_ARB, 8)
      else
         vals.Add(WGL_ALPHA_BITS_ARB, 0);
   end else if(renderer.Settings.ColorBits = 16) then begin
      vals.Add(WGL_RED_BITS_ARB, 5);
      vals.Add(WGL_GREEN_BITS_ARB, 6);
      vals.Add(WGL_BLUE_BITS_ARB, 5);
      vals.Add(WGL_ALPHA_BITS_ARB, 0);
   end;

   vals.Add(WGL_SWAP_METHOD_ARB, WGL_SWAP_EXCHANGE_ARB);

   vals.Add(0);
   nFormats := 0;

   if(wglChoosePixelFormatARB(wnd.wd.dc, @vals.List[0], nil,
   Length(pixelFormats), @pixelFormats[0], @nFormats) = false) then begin
      wnd.wd.LastError := winos.GetLastError();

      if(wnd.wd.LastError <> 0) then begin
         vals.Dispose();

         if(nFormats > 0) then
            log.e('wglChoosePixelFormat errored out, but gave pixel formats')
         else
            log.e('wglChoosePixelFormat errored out with no pixel formats');

         exit(0);
      end;
   end;

   vals.Dispose();

   if(nFormats > 0) then begin
      Result := pixelFormats[0];

      {create a sane pfd}
      DescribePixelFormat(wnd.wd.dc, Result, sizeof(pfd), @pfd);
   end else begin
      log.e('wglChoosePixelFormat returned 0 formats');
      Result := 0;
   end;
end;
{$ENDIF}

{$IFNDEF GLES}
function winGetContext(wnd: oglTWindow; sharedContext: HGLRC = 0): HGLRC;
var
   vals: specialize TSimpleList<GLint>;
   extContextProfile: boolean = false;
   contextFlags: GLint;
   message: string;

begin
   Result := 0;

   extContextProfile := oglExtensions.PlatformSupported(cWGL_ARB_create_context_profile);
   vals.Initialize(vals);

   if(not extContextProfile) then begin
      if(not oglTWindow(wnd).Downgrade32()) then
         exit(0);
   end;

   vals.Add(WGL_CONTEXT_MAJOR_VERSION_ARB,   oglDefaultVersion.Major);
   vals.Add(WGL_CONTEXT_MINOR_VERSION_ARB,   oglDefaultVersion.Minor);

   contextFlags := 0;
   {$IFDEF OX_DEBUG}
   contextFlags := contextFlags or WGL_CONTEXT_DEBUG_BIT_ARB;
   log.v('gl > Using debug context');
   {$ENDIF}

   if(contextFlags <> 0) then
      vals.add(WGL_CONTEXT_FLAGS_ARB, contextFlags);

   if(extContextProfile) then begin
      if(oglDefaultVersion.Profile = oglPROFILE_ANY) then begin
         log.v('gl > Using any profile');
         vals.Add(WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB or WGL_CONTEXT_CORE_PROFILE_BIT_ARB);
      end else if(oglDefaultVersion.Profile = oglPROFILE_COMPATIBILITY) then begin
         log.v('gl > Using compatibility profile');
         vals.Add(WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB);
      end else if(oglDefaultVersion.Profile = oglPROFILE_CORE) then begin
         log.v('gl > Using core profile');
         vals.Add(WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB);
      end;
   end;

   vals.add(0);

   Result := wglCreateContextAttribsARB(wnd.wd.dc, sharedContext, @vals.List[0]);
   wnd.wd.LastError := winos.GetLastError();

   if(wnd.wd.LastError <> 0) then begin
      if(wnd.wd.LastError = ERROR_INVALID_VERSION_ARB) then
         message := 'Invalid version'
      else if(wnd.wd.LastError = ERROR_INVALID_PROFILE_ARB) then
         message := 'Invalid profile'
      else
         message := 'unknown';

      log.e('wglCreateContextAttribs failed for version ' + oglDefaultVersion.GetString() + ': ' + message);
   end else
      log.v('gl > Created rendering context: ' + sf(Result));

   vals.Dispose();
end;
{$ENDIF}

function winLegacyContext(wnd: oglTWindow; shareContext: HGLRC = 0): HGLRC;
begin
   {create the OpenGL rendering context}
   Result := wglCreateContext(wnd.wd.dc);

   if(Result <> 0) then begin
      if(not wnd.oxProperties.Context) and (shareContext <> 0) then begin
         if(not wglShareLists(Result, shareContext)) then begin
            wnd.wd.LastError := winos.LogError('gl > (wglCreateContext) Failed to share lists with context ' + sf(shareContext));
         end;
      end;
   end else
      wnd.wd.LastError := winos.GetLastError();
end;

{ oxglTPlatformWGL }

constructor oxglTPlatformWGL.Create();
begin
   Name := 'wgl';
end;

function oxglTPlatformWGL.RaiseError(): loopint;
begin
   Result := winos.GetLastError(true);
end;

function oxglTPlatformWGL.PreInitWindow(wnd: oglTWindow): boolean;
var
   pFormat: longint;

   extPixelFormat: boolean       = false;

   pfMethod: string;
   pfd: PIXELFORMATDESCRIPTOR;

begin
   ogl.InitializePre();
   {$IFNDEF GLES}
   extPixelFormat := oglExtensions.PlatformSupported(cWGL_ARB_pixel_format);
   {$ELSE}
   extPixelFormat := false;
   {$ENDIF}

   buildPFD(wnd, pfd);

   {get a pixel format}
   {$IFNDEF GLES}
   if(not extPixelFormat) then
      pFormat := getPF(wnd, pfd)
   else
      pFormat := getPFARB(wnd, pfd);
   {$ELSE}
      pFormat := getPF(wnd, pfd);
   {$ENDIF}

   if(pFormat = 0) or (wnd.wd.LastError <> 0) then begin
      if(not extPixelFormat) then
         pfMethod := 'getPF'
      else
         pfMethod := 'getPFARB';

      if(wnd.wd.LastError = 0) then
         wnd.CreateFail('No suitable pixel format found (' + pfMethod + ').')
      else
         wnd.CreateFail('Failed to find pixel format (' + pfMethod + '). Error: ' + winos.FormatMessage(wnd.wd.LastError));

      exit(false);
   end;

   {set the pixel format}
   if(not SetPF(wnd, pFormat, pfd)) then
      exit(false);

   Result := true;
end;

procedure oxglTPlatformWGL.OnInitWindow(wnd: oglTWindow);
begin
   {$IF NOT DEFINED(GLES)}
   wglChoosePixelFormatARB := TwglChoosePixelFormatARB(wglGetProcAddress('wglChoosePixelFormatARB'));
   {$ENDIF}
end;

procedure oxglTPlatformWGL.SwapBuffers(wnd: oglTWindow);
begin
   if(wnd.wd.dc <> 0) then
      windows.SwapBuffers(wnd.wd.dc);
end;

function oxglTPlatformWGL.GetContext(wnd: oglTWindow; shareContext: HGLRC): HGLRC;
var
   extContext: boolean = false;
   requiresContext: boolean = false;
   method: string = '';

begin
   {$IFNDEF GLES}
   extContext := oglExtensions.PlatformSupported(cWGL_ARB_create_context);

   {requires new context creation for opengl 3.0 and higher}
   requiresContext := ogl.ContextRequired(oglDefaultVersion);
   {$ENDIF}

   if(extContext) and (requiresContext) then begin
      method := 'wglCreateContextAttribs';
      {$IFNDEF GLES}
      {do it the modern gl way}
      Result := winGetContext(wnd, shareContext);
      {$ELSE}
      Result := 0;
      {$ENDIF}
   end else begin
      { ye olde way }
      method := 'wglCreateContext';

      Result := winLegacyContext(wnd, shareContext);
   end;

   if(wnd.wd.LastError <> 0) then
      log.e('gl > (' + method + ') Failed getting rendering context ' + winos.FormatMessage(wnd.wd.LastError));
end;

function oxglTPlatformWGL.ContextCurrent(var target: oxTRenderTarget; context: oglTRenderingContext): boolean;
begin
   if(target.Typ = oxRENDER_TARGET_WINDOW) then
      Result := wglMakeCurrent(winosTWindow(target.Target).wd.dc, context);
end;

function oxglTPlatformWGL.ClearContext(wnd: oglTWindow): boolean;
begin
   Result := wglMakeCurrent(0, 0);
end;

function oxglTPlatformWGL.DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   Result := wglDeleteContext(context);
end;

INITIALIZATION
   oxwgl.Create();
   oxglTRenderer.glPlatform := @oxwgl;

END.
