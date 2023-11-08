{
   oxuglRendererWin, gl renderer windows platform component
   Copyright (c) 2016. Dejan Boras

   Started On:    05.01.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglRendererWin;

INTERFACE

	USES uStd, uLog, StringUtils,
     {$INCLUDE usesglext.inc},
     windows, oxuWindowsOS, oxuRenderer,
     oxuOGL, oxuglExtensions, oxuWGL;

TYPE
   { oxwglTGlobal }

   oxwglTGlobal = record
      function PreInitWIndow(wnd: oglTWindow): boolean;

      function GetContext(wnd: oglTWindow; shareContext: HGLRC): HGLRC;
   end;

VAR
   oxwgl: oxwglTGlobal;

IMPLEMENTATION

function buildPFD(wnd: oglTWindow; out pfd: PIXELFORMATDESCRIPTOR): boolean;
var
   objType,
   dwFlags: dword;

begin
   {build required pixel format}
   ZeroOut(pfd, SizeOf(pfd));

   pfd.nSize         := sizeof(pfd);
   pfd.nVersion      := 1;

   objType := GetObjectType(wnd.wd.dc);

   if(winos.LogError('Failed to get dc object type') <> 0) then begin
      winosTWindow(wnd).wd.LastError := winos.LastError;
      wnd.ErrorDescription.Add(winos.LastErrorDescription);
      exit(false);
   end;

   dwFlags        := PFD_SUPPORT_OPENGL;
   if(objType in oxwinMemoryDCs) then
      dwFlags     := dwFlags or PFD_DRAW_TO_BITMAP
   else
      dwFlags     := dwFlags or PFD_DRAW_TO_WINDOW;

   if(wnd.gl.DoubleBuffer) then
      dwFlags     := dwFlags or PFD_DOUBLEBUFFER;
   if(wnd.gl.Software) then
      dwFlags     := dwFlags or PFD_SUPPORT_GDI;
   if(wnd.gl.Stereo) then
      dwFlags     := dwFlags or PFD_STEREO;

   pfd.dwFlags       := dwFlags;
   pfd.iPixelType    := PFD_TYPE_RGBA;
   pfd.cColorBits    := wnd.gl.ColorBits;
   pfd.cDepthBits    := wnd.gl.DepthBits;
   pfd.iLayerType    := PFD_MAIN_PLANE;
   pfd.cStencilBits  := wnd.gl.StencilBits;

   if(wnd.gl.Layer = 0) then
      pfd.iLayerType := PFD_MAIN_PLANE
   else begin
      if(wnd.gl.Layer > 0) then
         pfd.iLayerType := PFD_OVERLAY_PLANE
      else
         pfd.iLayerType := Byte(PFD_UNDERLAY_PLANE);
   end;

   Result := true;
end;

function setPF(wnd: oglTWindow; pFormat: longint; const pfd: PIXELFORMATDESCRIPTOR): boolean;
begin
   Result := SetPixelFormat(wnd.wd.dc, pFormat, @pfd);
   if(not Result) then
      log.e('Failed to SetPixelFormat with format ' + sf(pFormat));

   wnd.wd.LastError := winos.GetLastError();
   if(wnd.wd.LastError <> 0) then begin
      log.e('SetPixelFormat returned error: ' + winos.FormatMessage(wnd.wd.LastError));
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
   wnd.wd.LastError := winos.GetLastError();

   {Ignore any windows error if we got a pixel format.
   Because this is a standard behavior with some driver/windows combinations.}
   if(pFormat <> 0) and (wnd.wd.LastError <> 0) then begin
      log.w('Pixel format chosen(' + sf(pFormat) + '), but ChoosePixelFormat still returned an error: ' +
         winos.FormatMessage(wnd.wd.LastError));

      wnd.wd.LastError := 0;
   end;

   Result := pFormat;
end;

function getPFARB(wnd: oglTWindow; var pfd: PIXELFORMATDESCRIPTOR): longint;
var
   vals: specialize TPreallocatedArrayList<GLint>;
   pixelFormats: array[0..1023] of longint;
   nFormats: dword = 0;

begin
   vals.Initialize(vals);

   vals.Add(WGL_DRAW_TO_WINDOW_ARB, 1);
   vals.Add(WGL_SUPPORT_OPENGL_ARB, 1);
   vals.Add(WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB);

   if(wnd.gl.DoubleBuffer) then
      vals.Add(WGL_DOUBLE_BUFFER_ARB, 1);

   vals.Add(WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB);

   vals.Add(WGL_COLOR_BITS_ARB, wnd.gl.ColorBits);
   vals.Add(WGL_DEPTH_BITS_ARB, wnd.gl.DepthBits);

   vals.Add(WGL_STENCIL_BITS_ARB, wnd.gl.StencilBits);
   vals.Add(WGL_ACCUM_BITS_ARB, wnd.gl.AccumBits);

   if(wnd.gl.ColorBits = 32) or (wnd.gl.ColorBits = 24) then begin
      vals.Add(WGL_RED_BITS_ARB, 8);
      vals.Add(WGL_GREEN_BITS_ARB, 8);
      vals.Add(WGL_BLUE_BITS_ARB, 8);

      if(wnd.gl.ColorBits = 32) then
         vals.Add(WGL_ALPHA_BITS_ARB, 8)
      else
         vals.Add(WGL_ALPHA_BITS_ARB, 0);
   end else if(wnd.gl.ColorBits = 16) then begin
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

function winGetContext(wnd: oglTWindow; sharedContext: HGLRC = 0): HGLRC;
var
   vals: specialize TPreallocatedArrayList<GLint>;
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

   vals.Add(WGL_CONTEXT_MAJOR_VERSION_ARB,   wnd.glSettings.Version.Major);
   vals.Add(WGL_CONTEXT_MINOR_VERSION_ARB,   wnd.glSettings.Version.Minor);

   contextFlags := 0;
   {$IFDEF OX_DEBUG}
   contextFlags := contextFlags or WGL_CONTEXT_DEBUG_BIT_ARB;
   log.v('gl > Using debug context');
   {$ENDIF}

   if(contextFlags <> 0) then
      vals.add(WGL_CONTEXT_FLAGS_ARB, contextFlags);

   if(extContextProfile) then begin
      if(wnd.glSettings.Version.Profile = oglPROFILE_ANY) then begin
         log.v('gl > Using any profile');
         vals.Add(WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB or WGL_CONTEXT_CORE_PROFILE_BIT_ARB);
      end else if(wnd.glSettings.Version.Profile = oglPROFILE_COMPATIBILITY) then begin
         log.v('gl > Using compatibility profile');
         vals.Add(WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB);
      end else if(wnd.glSettings.Version.Profile = oglPROFILE_CORE) then begin
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

      log.e('wglCreateContextAttribs failed for version ' + wnd.glSettings.GetString() + ': ' + message);
   end else
      log.v('gl > Created rendering context: ' + sf(Result));

   vals.Dispose();
end;

function oxwglTGlobal.PreInitWIndow(wnd: oglTWindow): boolean;
var
   pFormat: longint;

   extPixelFormat: boolean       = false;

   pfMethod: string;
   pfd: PIXELFORMATDESCRIPTOR;

begin
   ogl.InitializePre();
   extPixelFormat := oglExtensions.PlatformSupported(cWGL_ARB_pixel_format);

   buildPFD(wnd, pfd);

   {get a pixel format}
   if(not extPixelFormat) then
      pFormat     := getPF(wnd, pfd)
   else
      pFormat     := getPFARB(wnd, pfd);

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

function oxwglTGlobal.GetContext(wnd: oglTWindow; shareContext: HGLRC): HGLRC;
var
   extContext: boolean           = false;
   requiresContext: boolean      = false;
   method: string = '';

begin
   extContext := oglExtensions.PlatformSupported(cWGL_ARB_create_context);

   {requires new context creation for opengl 3.0 and higher}
   requiresContext := ogl.ContextRequired(oglTWindow(wnd).DefaultSettings);

   if(extContext) and (requiresContext) then begin
      {do it the modern gl way}
      method := 'wglCreateContextAttribs';
      Result := winGetContext(wnd, shareContext);
   end else begin
      { ye olde way }
      method := 'wglCreateContext';

      {create the OpenGL rendering context}
      Result := wglCreateContext(wnd.wd.dc);
      wnd.wd.LastError := winos.GetLastError();

      if(wnd.wd.LastError = 0) and (not wnd.oxProperties.Context) and (shareContext <> 0) then begin
         wglShareLists(Result, shareContext);
         wnd.wd.LastError := winos.GetLastError();

         if(wnd.wd.LastError <> 0) then
            log.w('gl > (' + method + ') Failed to share lists with context ' + sf(shareContext));
      end;
   end;

   if(wnd.wd.LastError <> 0) then
      log.e('gl > (' + method + ') Failed getting rendering context ' + winos.FormatMessage(wnd.wd.LastError));
end;

END.
