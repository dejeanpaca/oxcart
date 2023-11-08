{
   oxgluRenderer, oX OpenGL renderer base
   Copyright (C) 2013. Dejan Boras

   Started On:    29.12.2013.
}

{$IFDEF OX_NO_GL_RENDERER}
   {$FATAL Included gl renderer, with OX_NO_GL_RENDERER defined}
{$ENDIF}

{$INCLUDE oxdefines.inc}
UNIT oxuglRenderer;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uLog, uStd, uColors, StringUtils, uImage, vmVector,
      {ox}
      uOX, oxuWindowTypes, oxuTypes, oxuRenderer, oxuRenderers, oxuOGL, oxuglExtensions,
      oxuglInfo,
      {platform specific}
      {$IFDEF WINDOWS}windows, oxuglRendererWin, oxuWindowsPlatform, oxuWindowsOS{$ENDIF}
      {$IFDEF X11}GLX, oxuX11Platform, oxuglRendererX11{$ENDIF};

TYPE
   { oxglTRenderer }

   oxglTRenderer = class(oxTRenderer)
      glRenderingContexts: array[0..oxMAXIMUM_RENDER_CONTEXT] of oglTRenderingContext;
      pExtensions: oglPExtensions;

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

procedure oxglTRenderer.OnInitialize();
begin
   pExtensions := @oglExtensions;
   {$IFDEF OX_LIBRARY}
   oglExtensions.pExternal := oxglTRenderer(ExternalRenderer).pExtensions;
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
   wnd.RenderingContext := oxTRenderer(wnd.Renderer).GetContext(wnd);

   if(wnd.ErrorCode = 0) and (not wnd.oxProperties.Context)  then begin
      wnd.ThreadRenderingContext := oxTRenderer(wnd.Renderer).GetContext(wnd, wnd.RenderingContext);

      if(wnd.ErrorCode = 0) then
         log.v('gl > Created thread render context');
   end;

   if(wnd.RenderingContext = -1) or (wnd.ErrorCode <> 0) then begin
      if(wnd.ErrorCode = 0) then
         wnd.CreateFail('gl > Failed to get a rendering context');

      exit(False);
   end;

   {$IFDEF OX_LIBRARY}
   if(wnd.ExternalWindow <> nil) then
      oglTWindow(wnd).Info := oglTWindow(wnd.ExternalWindow).Info;
   log.w('INITIALOZED');
   {$ENDIF}

   {bind rendering context to the window}
   oxTRenderer(wnd.Renderer).ContextCurrent(wnd.RenderingContext);
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
      glwnd.glSettings := xglwnd.glSettings;
      glwnd.DefaultSettings := xglwnd.DefaultSettings;
      glwnd.RequiredSettings := xglwnd.RequiredSettings;
      glwnd.glProperties := xglwnd.glProperties;
      glwnd.Limits := xglwnd.Limits;
   end;

   Result := true;
end;
{$ENDIF}

procedure oxglTRenderer.SetupData(wnd: oxTWindow);
begin
   if(not wnd.oxProperties.Context) then begin
      oglTWindow(wnd).DefaultSettings := oglDefaultSettings;
      oglTWindow(wnd).RequiredSettings := oglRequiredSettings;
   end else begin
      oglTWindow(wnd).DefaultSettings := oglContextSettings;
      oglTWindow(wnd).RequiredSettings := oglContextSettings;
   end;

   oglTWindow(wnd).glSettings := oglTWindow(wnd).DefaultSettings;
end;

function oxglTRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   errorCode := 0;

   if(ox.LibraryMode) then begin
      {in library mode, we haven't done any of this as the window was not created}
      ogl.InitializePre();
      ogl.ActivateRenderingContext();

      {no need to call ogl.InitState(), as we share state with the parent window}
   end else
      ogl.InitState();

   if(ogl.eRaise() <> 0) then
      log.w('gl > Errors while setting up state');

   if(not ox.LibraryMode) then begin
      {get information from OpenGL}
      oglGetInformation(oglTWindow(wnd));
      if(ogl.eRaise() <> 0) then
         log.w('gl > Errors while getting information');

      {check if versions match}
      if(oglVersionCheck(oglTWindow(wnd)) = ogleVERSION_UNSUPPORTED) then begin
         wnd.errorDescription := 'Got OpenGL version ' + oglTWindow(wnd).glSettings.GetString() + ' which is unsupported, minimum required ' + oglTWindow(wnd).RequiredSettings.GetString();
         errorCode := eUNSUPPORTED;
      end;
   end;

   Result := errorCode = 0;
end;

function oxglTRenderer.PreInitWindow(wnd: oxTWindow): boolean;
begin
   {$IF defined(WINDOWS)}
   Result := oxwgl.PreInitWindow(oglTWindow(wnd));
   {$ELSEIF defined(X11)}
   Result := oxglx.PreInitWindow(oglTWindow(wnd));
   {$ELSEIF defined(COCOA)}
   Result := oxglCocoa.PreInitWIndow(oglTWindow(wnd));
   {$ELSE}
   Result := false;
   {$ENDIF}
end;

procedure oxglTRenderer.LogWindow(window: oxTWindow);
begin
   log.i('OpenGL Target: ' + oglTWindow(window).glSettings.GetString());
end;

function oxglTRenderer.ContextWindowRequired(): boolean;
begin
   Result := ogl.ContextRequired(oglDefaultSettings);
end;

procedure oxglTRenderer.SwapBuffers(wnd: oxTWindow);
begin
   {$IFDEF WINDOWS}
   oxwgl.SwapBuffers(oglTWindow(wnd));
   {$ENDIF}

   {$IFDEF X11}
   oxglx.SwapBuffers(oglTWindow(wnd));
   {$ENDIF}

   {$IFDEF COCOA}
   oxglCocoa.SwapBuffers(oglTWindow(wnd));
   {$ENDIF}
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

   {$IFDEF WINDOWS}
   rc := oxwgl.GetContext(oglTWindow(wnd), shareRC);
   {$ENDIF}

   {$IFDEF X11}
   rc := oxglx.GetContext(oglTWindow(wnd), shareRC);
   {$ENDIF}

   {$IFDEF COCOA}
   rc := oxglCocoa.GetContext(oglTWindow(wnd), shareRC);
   {$ENDIF}

   if(ogl.ValidRC(rc)) then begin
      Result := AddRenderingContext(wnd);
      glRenderingContexts[Result] := rc;
   end else begin
      wnd.ErrorCode := eFAIL;
      Result := -1;
   end;
end;

procedure oxglTRenderer.ContextCurrent(context: loopint);
var
   wnd: oglTWindow;

begin
   if(context >= 0) then begin
      wnd := oglTWindow(RenderingContexts[context].Window);
      log.v('gl > Set render context ' + sf(context) +  ' current');

      {$IFDEF WINDOWS}
      wglMakeCurrent(wnd.wd.dc, glRenderingContexts[context]);
      wnd.wd.LastError := winos.LogError('wglMakeCurrent');
      {$ENDIF}
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

      {$IFDEF WINDOWS}
      if(not wglMakeCurrent(0, 0)) then
         wnd.wd.LastError := winos.LogError('wglMakeCurrent');
      {$ENDIF}

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
      {$IFDEF WINDOWS}
      Result := wglDeleteContext(rc);
      if(not Result) then
         wnd.wd.LastError := winos.LogError('wglDeleteContext');
      {$ENDIF}

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

   {$INCLUDE ../../ox_default_platform_instance.inc}

   Id := 'renderer.gl';
   Init.Init(Id);
end;

function oxglTRenderer.GetSummary(wnd: oxTWindow): TStringArray;
var
   list: array[0..3] of string;

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
   ox.PreInit.Add('ox.gl.renderer', @init, @deinit);

END.
