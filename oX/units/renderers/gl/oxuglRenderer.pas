{
   oxuglRenderer, oX OpenGL renderer base
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_GL}
   {$FATAL Included gl renderer, with no OX_RENDERER_GL defined}
{$ENDIF}

UNIT oxuglRenderer;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uLog, uStd, uColors, StringUtils, uImage, vmVector,
      {ox}
      uOX, oxuRunRoutines, oxuWindowTypes, oxuTypes, oxuRenderer, oxuRenderers, oxuWindows,
      {renderer.gl}
      oxuOGL, oxuglExtensions, oxuglInfo, oxuglRendererPlatform
      {platform specific}
      {$IFDEF X11}, GLX, oxuX11Platform, oxuglRendererX11{$ENDIF}
      {$IFDEF COCOA}, oxuglCocoa, oxuCocoaPlatform, oxuglRendererCocoa{$ENDIF};

TYPE
   { oxglTRenderer }

   oxglTRenderer = class(oxTRenderer)
      glPlatform: oxglPPlatform; static;
      glSystemPlatform: TClass; static;

      glRenderingContexts: array[0..oxMAXIMUM_RENDER_CONTEXT] of oglTRenderingContext;
      {$IFDEF OX_LIBRARY_SUPPORT}
      pExtensions: oglPExtensions;
      {$ENDIF}

      procedure AfterInitialize(); override;

      procedure OnInitialize(); override;
      procedure OnDeInitialize(); override;

      {windows}
      procedure SetupData(wnd: oxTWindow); override;
      function SetupWindow(wnd: oxTWindow): boolean; override;
      function PreInitWindow({%H-}wnd: oxTWindow): boolean; override;
      function InitWindow(wnd: oxTWindow): boolean; override;
      {$IFDEF OX_LIBRARY}
      function InitWindowLibrary(wnd: oxTWindow): boolean; override;
      {$ENDIF}
      procedure LogWindow(window: oxTWindow); override;
      function ContextWindowRequired(): boolean; override;

      {rendering}
      procedure SwapBuffers(wnd: oxTWindow); override;

      function GetContext(wnd: oxTWindow; shareContext: loopint=0): loopint; override;
      function GetContextString(index: loopint=0): StdString; override;
      procedure ContextCurrent(context: loopint); override;
      procedure ClearContext(context: loopint); override;
      function DestroyContext(context: loopint): boolean; override;

      procedure StartThread(wnd: oxTWindow); override;
      procedure StopThread(wnd: oxTWindow); override;

      procedure SetProjectionMatrix(const m: vmVector.TMatrix4f); override;

      procedure Viewport(x, y, w, h: longint); override;
      procedure Clear(clearBits: longword); override;
      procedure ClearColor(c: TColor4f); override;

      constructor Create(); override;

      function GetSummary(wnd: oxTWindow): TStringArray; override;

      procedure Screenshot({%H-}wnd: oxTWindow; {%H-}image: imgTImage; x, y: loopint; w, h: loopint); override;
  end;

VAR
   oxglRenderer: oxglTRenderer;

IMPLEMENTATION

{ oxglTRenderer }

procedure oxglTRenderer.AfterInitialize();
begin
   log.Collapsed('OpenGL');

   inherited AfterInitialize();

   oglLogInformation(oglTWindow(oxWindows.w[0]));

   log.Leave();
end;

procedure oxglTRenderer.OnInitialize();
begin
   {$IFDEF OX_LIBRARY_SUPPORT}
   if(not ox.LibraryMode) then
      pExtensions := @oglExtensions
   else
      pExtensions := oxglTRenderer(ExternalRenderer).pExtensions;
   {$ENDIF}

   {initialize opengl}
   ogl.InitializePre();

   {$IFDEF X11}
   oxglx.InitGLX();
   {$ENDIF}
   {$IFDEF COCOA}
   oxglCocoa.InitGL();
   {$ENDIF}
end;

procedure oxglTRenderer.OnDeInitialize();
begin
   inherited OnDeInitialize();

   oglExtensions.DeInitialize();
end;

function oxglTRenderer.InitWindow(wnd: oxTWindow): boolean;
begin
   wnd.RenderingContext := GetContext(wnd);

   if(wnd.RenderingContext = -1) or (wnd.ErrorCode <> 0) then begin
      if(wnd.ErrorCode = 0) then
         wnd.CreateFail('gl > Failed to get a rendering context')
      else
         wnd.CreateFail('gl > No rendering context');

      exit(False);
   end;

   {$IFDEF OX_LIBRARY}
   if(wnd.ExternalWindow <> nil) then
      oglTWindow(wnd).Info := oglTWindow(wnd.ExternalWindow).Info;
   {$ENDIF}

   {bind rendering context to the window}
   ContextCurrent(wnd.RenderingContext);
   ogl.ActivateRenderingContext();

   {$IF DEFINED(WINDOWS) AND (NOT DEFINED(GLES))}
   wglChoosePixelFormatARB := TwglChoosePixelFormatARB(wglGetProcAddress('wglChoosePixelFormatARB'));
   {$ENDIF}

   Result := true;
end;

{$IFDEF OX_LIBRARY}
function oxglTRenderer.InitWindowLibrary(wnd: oxTWindow): boolean;
var
   glwnd,
   xglwnd: oglTWindow;

begin
   if(wnd.ExternalWindow <> nil) then begin
      xglwnd := oglTWindow(wnd.ExternalWindow.oxwParent);
      glwnd := oglTWindow(wnd);

      glwnd.Info := xglwnd.Info;
      glwnd.gl := xglwnd.gl;
      glwnd.glDefault := xglwnd.glDefault;
      glwnd.glRequired := xglwnd.glRequired;
      glwnd.glProperties := xglwnd.glProperties;
      glwnd.Limits := xglwnd.Limits;
   end;

   Result := true;
end;
{$ENDIF}

procedure oxglTRenderer.SetupData(wnd: oxTWindow);
begin
   if(not wnd.oxProperties.Context) then begin
      oglTWindow(wnd).glDefault := oglDefaultSettings;
      oglTWindow(wnd).glRequired := oglRequiredSettings;
   end else begin
      oglTWindow(wnd).glDefault := oglContextSettings;
      oglTWindow(wnd).glRequired := oglContextSettings;
   end;

   oglTWindow(wnd).gl := oglTWindow(wnd).glDefault;
end;

function oxglTRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   {$IFDEF OX_LIBRARY_SUPPORT}
   oglExtensions.pExternal := pExtensions;
   {$ENDIF}

   if(ox.LibraryMode) then begin
      {in library mode, we haven't done any of this as the window was not created}
      ogl.InitializePre();
      ogl.ActivateRenderingContext();

      {no need to call ogl.InitState(), as we share state with the parent window}
   end else
      ogl.InitState();

   if(ogl.eRaise() <> 0) then
      log.w('gl > Errors while setting up state');

   {get information from OpenGL}
   oglGetInformation(oglTWindow(wnd));
   if(ogl.eRaise() <> 0) then begin
      log.w('gl > Errors while getting information');
      exit(false);
   end;

   if(not ox.LibraryMode) then begin
      {check if versions match}
      if(oglVersionCheck(oglTWindow(wnd)) = ogleVERSION_UNSUPPORTED) then begin
         wnd.RaiseError(eUNSUPPORTED, 'Got OpenGL version ' +
            oglTWindow(wnd).gl.GetString() + ' which is unsupported, minimum required ' +
            oglTWindow(wnd).glRequired.GetString());
      end;
   end;

   Result := wnd.ErrorCode = 0;
end;

function oxglTRenderer.PreInitWindow(wnd: oxTWindow): boolean;
begin
   Result := glPlatform^.PreInitWindow(oglTWindow(wnd));
end;

procedure oxglTRenderer.LogWindow(window: oxTWindow);
begin
   log.i('OpenGL Target: ' + oglTWindow(window).gl.GetString());
end;

function oxglTRenderer.ContextWindowRequired(): boolean;
begin
   Result := ogl.ContextRequired(oglDefaultSettings);
end;

procedure oxglTRenderer.SwapBuffers(wnd: oxTWindow);
begin
   glPlatform^.SwapBuffers(oglTWindow(wnd));
end;

function oxglTRenderer.GetContext(wnd: oxTWindow; shareContext: loopint): loopint;
var
   rc,
   shareRC: oglTRenderingContext;

begin
   Result := -1;

   rc := oglRenderingContextNull;
   shareRC := oglRenderingContextNull;

   if(shareContext > -1) then
      shareRC := glRenderingContexts[shareContext];

   rc := glPlatform^.GetContext(oglTWindow(wnd), shareRC);

   if(ogl.ValidRC(rc)) then begin
      Result := AddRenderingContext(wnd);
      glRenderingContexts[Result] := rc;
   end else begin
      wnd.RaiseError(eFAIL, 'Not a valid rendering context');
      Result := -1;
   end;
end;

function oxglTRenderer.GetContextString(index: loopint): StdString;
begin
   Result := sf(glRenderingContexts[index]);
end;

procedure oxglTRenderer.ContextCurrent(context: loopint);
var
   wnd: oglTWindow;

begin
   if(context >= 0) then begin
      wnd := oglTWindow(RenderingContexts[context].Window);
      log.v('gl > Set render context ' + sf(context) +  ' current');

      glPlatform^.ContextCurrent(wnd, glRenderingContexts[context]);

      {$IFDEF X11}
      glXMakeCurrent(x11.DPY, wnd.wd.h, glRenderingContexts[context]);
      wnd.wd.LastError := x11.GetError();
      {$ENDIF}
      {$IFDEF COCOA}
      {TODO: Implement}
      {$ENDIF}

      RenderingContexts[context].Used := true;
   end;
end;

procedure oxglTRenderer.ClearContext(context: loopint);
var
   wnd: oglTWindow;

begin
   if(context >= 0) then begin
      wnd := oglTWindow(RenderingContexts[context].Window);

      glPlatform^.ClearContext(wnd);

      {$IFDEF X11}
      glXMakeCurrent(x11.DPY, 0, nil);
      wnd.wd.LastError := x11.GetError();
      {$ENDIF}

      {$IFDEF COCOA}
      {TODO: Implement}
      {$ENDIF}

      RenderingContexts[context].Used := false;
   end;
end;

function oxglTRenderer.DestroyContext(context: loopint): boolean;
var
   rc: oglTRenderingContext;
   wnd: oglTWindow;

begin
   if(context < 0) then
      exit(true);

   Result := true;

   rc := glRenderingContexts[context];
   wnd := oglTWindow(RenderingContexts[context].Window);

   RemoveContext(context);

   if(ogl.ValidRC(rc)) then begin
      glPlatform^.DestroyContext(wnd, rc);

      {$IFDEF X11}
      glXDestroyContext(x11.DPY, rc);
      wnd.wd.LastError := x11.GetError();
      {$ENDIF}

      {$IFDEF COCOA}
      {TODO: Implement}
      {$ENDIF}

      Result := wnd.wd.LastError = 0;

      glRenderingContexts[context] := oglRenderingContextNull;
   end;
end;

procedure oxglTRenderer.StartThread(wnd: oxTWindow);
begin
   ContextCurrent(wnd.ThreadRenderingContext);
   ogl.InitState();
end;

procedure oxglTRenderer.StopThread(wnd: oxTWindow);
begin
   ClearContext(wnd.ThreadRenderingContext);
end;

procedure oxglTRenderer.SetProjectionMatrix(const m: vmVector.TMatrix4f);
var
   transposed: TMatrix4f;

begin
   transposed := m.Transposed();

   glMatrixMode(GL_PROJECTION);
   glLoadMatrixf(@transposed[0][0]);
   glMatrixMode(GL_MODELVIEW);
   glLoadMatrixf(@vmmUnit4);
end;

procedure oxglTRenderer.Viewport(x, y, w, h: longint);
begin
   glViewport(x, y, w, h);
end;

procedure oxglTRenderer.Clear(clearBits: longword);
var
   glClearBits: GLbitfield = 0;

begin
   if(clearBits and oxrBUFFER_CLEAR_COLOR > 0) then
      glClearBits := glClearBits or GL_COLOR_BUFFER_BIT;
   if(clearBits and oxrBUFFER_CLEAR_DEPTH > 0) then
      glClearBits := glClearBits or GL_DEPTH_BUFFER_BIT;
   if(clearBits and oxrBUFFER_CLEAR_STENCIL > 0) then
      glClearBits := glClearBits or GL_STENCIL_BUFFER_BIT;
   {$IFNDEF GLES}
   if(clearBits and oxrBUFFER_CLEAR_ACCUM > 0) then
      glClearBits := glClearBits or GL_ACCUM_BUFFER_BIT;
   {$ENDIF}

   glClear(glClearBits);
end;

procedure oxglTRenderer.ClearColor(c: TColor4f);
begin
   glClearColor(c[0], c[1], c[2], c[3]);
end;

constructor oxglTRenderer.Create();
begin
   inherited;

   {$IFDEF GLES}
      Name := 'OpenGL ES';
   {$ELSE}
      Name := 'OpenGL';
   {$ENDIF}

   WindowInstance := oglTWindow;
   PlatformInstance := glSystemPlatform;

   Id := 'gl';
end;

function oxglTRenderer.GetSummary(wnd: oxTWindow): TStringArray;
var
   list: array[0..3] of StdString;

begin
   list[0] := 'Vendor: ' + oglTWindow(wnd).Info.Vendor;
   list[1] := 'Renderer: ' + oglTWindow(wnd).Info.Renderer;
   list[2] := 'OpenGL: ' + oglTWindow(wnd).Info.Version;
   list[3] := 'GLSL Version: ' + oglTWindow(wnd).Info.GLSL.Version;

   Result := list;
end;

procedure oxglTRenderer.Screenshot(wnd: oxTWindow; image: imgTImage; x, y: loopint; w, h: loopint);
begin
   {get the image data}
   glPixelStorei(GL_PACK_ALIGNMENT, 1);
   glReadPixels(x, y, w, h, GL_RGB, GL_UNSIGNED_BYTE, image.Image);
   ogl.eRaise();
end;

procedure init();
begin
   oxglRenderer := oxglTRenderer.Create();

   oxRenderers.Register(oxglRenderer);
end;

procedure deinit();
begin
   FreeObject(oxglRenderer);
end;

INITIALIZATION
   ox.PreInit.Add('renderer.gl', @init, @deinit);

END.
