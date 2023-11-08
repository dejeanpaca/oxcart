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
      uOX, oxuRunRoutines, oxuWindowTypes, oxuTypes, oxuRenderer, oxuRenderers, oxuWindow,
      {renderer.gl}
      oxuOGL, oxuglExtensions, oxuglInfo, oxuglRendererPlatform, oxuglRendererInfo, oxuglWindow
      {$IFNDEF OX_LIBRARY}, oxuglLog{$ENDIF};

TYPE
   { oxglTRenderer }

   oxglTRenderer = class(oxTRenderer)
      glPlatform: oxglPPlatform; static;
      glSystemPlatform: TClass; static;

      glRenderingContexts: array[0..oxMAXIMUM_RENDER_CONTEXT] of oglTRenderingContext;
      {$IFDEF OX_LIBRARY_SUPPORT}
      pExtensions: oglPExtensions;
      pInfo: oxglPRendererInfo;
      {$ENDIF}

      constructor Create(); override;

      procedure AfterInitialize(); override;

      procedure OnInitialize(); override;
      procedure OnDeInitialize(); override;

      {windows}
      function SetupWindow(wnd: oxTWindow): boolean; override;
      function PreInitWindow({%H-}wnd: oxTWindow): boolean; override;
      function InitWindow(wnd: oxTWindow): boolean; override;
      function DeInitWindow({%H-}wnd: oxTWindow): boolean; override;
      function ContextWindowRequired(): boolean; override;

      {rendering}
      procedure SwapBuffers(wnd: oxTWindow); override;

      function GetContext(wnd: oxTWindow; shareContext: loopint=-1): loopint; override;
      function GetContextString(index: loopint=0): StdString; override;
      procedure ContextCurrent(const context: oxTRenderTargetContext); override;
      procedure ClearContext(context: loopint); override;
      function DestroyContext(context: loopint): boolean; override;

      procedure StartThread({%H-}wnd: oxTWindow); override;
      procedure StopThread({%H-}wnd: oxTWindow); override;

      procedure SetProjectionMatrix(const m: vmVector.TMatrix4f); override;

      procedure Viewport(x, y, w, h: longint); override;
      procedure Clear(clearBits: longword); override;
      procedure ClearColor(c: TColor4f); override;

      function GetSummary(): TStringArray; override;
      function GetPlatformErrorDescription(error: loopint): StdString;
  end;

VAR
   oxglRenderer: oxglTRenderer;

IMPLEMENTATION

{ oxglTRenderer }

constructor oxglTRenderer.Create();
begin
   inherited;

   {$IFDEF GLES}
      Name := 'OpenGL ES';
   {$ELSE}
      Name := 'OpenGL';
   {$ENDIF}

   WindowInstance := oglTWindow;
   {$IFNDEF OX_LIBRARY}
   PlatformInstance := glSystemPlatform;
   {$ENDIF}

   Id := 'gl';
end;

procedure oxglTRenderer.AfterInitialize();
begin
   log.Collapsed('OpenGL');

   inherited AfterInitialize();

   {$IFNDEF OX_LIBRARY}
   if(oxWindow.Current.ErrorCode = 0) then
      oglLogInformation();
   {$ENDIF}

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

   glPlatform^.OnInitialize();

   log.i('Target version: ' + oglDefaultVersion.GetString());
end;

procedure oxglTRenderer.OnDeInitialize();
begin
   inherited OnDeInitialize();

   oglExtensions.DeInitialize();
end;

function oxglTRenderer.InitWindow(wnd: oxTWindow): boolean;
var
   rtc: oxTRenderTargetContext;

begin
   if(not glPlatform^.OnInitWindow(oglTWindow(wnd))) then
      exit(false);

   if(not PreserveRCs) or (wnd.RenderingContext = -1) then
      wnd.RenderingContext := GetRenderingContext(wnd);

   if(wnd.RenderingContext = -1) or (wnd.ErrorCode <> 0) then begin
      if(wnd.ErrorCode = 0) then
         wnd.CreateFail('gl > Failed to get a rendering context')
      else
         wnd.CreateFail('gl > No rendering context');

      exit(false);
   end;

   wnd.FromWindow(rtc);

   {bind rendering context to the window}
   ContextCurrent(rtc);
   ogl.ActivateRenderingContext();

   glPlatform^.AfterInitWindow(oglTWindow(wnd));

   Result := true;
end;

function oxglTRenderer.DeInitWindow(wnd: oxTWindow): boolean;
begin
   Result := glPlatform^.OnDeInitWindow(oglTWindow(wnd));
end;

function oxglTRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   {if window was already created just reset gl state}
   if wnd.oxProperties.Created then begin
      ogl.InitState();
      exit;
   end;

   {$IFDEF OX_LIBRARY_SUPPORT}
   oglExtensions.pExternal := pExtensions;
   pInfo := @oxglRendererInfo;
   {$ENDIF}

   if(ox.LibraryMode) then begin
      {in library mode, we haven't done any of this as the window was not created}
      ogl.InitializePre();
      ogl.ActivateRenderingContext();

      {no need to call ogl.InitState(), as we share state with the parent window}
   end else
      ogl.InitState();

   if(ogl.eRaise() <> 0) then
      logtw('Errors while setting up state');

   {get information from OpenGL}
   oglGetInformation();
   if(ogl.eRaise() <> 0) then begin
      logtw('Errors while getting information');
      exit(false);
   end;

   {$IFDEF OX_LIBRARY}
   oxglRendererInfo := pInfo^;
   {$ENDIF}

   if(not ox.LibraryMode) then begin
      {check if versions match}
      if(oglVersionCheck() = ogleVERSION_UNSUPPORTED) then begin
         wnd.RaiseError(eUNSUPPORTED, 'Got OpenGL version ' +
            oxglRendererInfo.Version.GetString() + ' (' + oxglRendererInfo.sVersion + ')  which is unsupported, minimum required ' +
            oxglRendererInfo.GetRequiredVersion().GetString());
      end;
   end;

   Result := wnd.ErrorCode = 0;
end;

function oxglTRenderer.PreInitWindow(wnd: oxTWindow): boolean;
begin
   Result := glPlatform^.PreInitWindow(oglTWindow(wnd));
end;

function oxglTRenderer.ContextWindowRequired(): boolean;
begin
   Result := ogl.ContextRequired(oglDefaultVersion);
end;

procedure oxglTRenderer.SwapBuffers(wnd: oxTWindow);
{$IFDEF OX_DEBUG}
var
   error: loopint;
{$ENDIF}

begin
   glPlatform^.SwapBuffers(oglTWindow(wnd));

   {$IFDEF OX_DEBUG}
   error := glPlatform^.RaiseError();

   if(error <> 0) then
      log.e('Failed to swap buffers (' + GetPlatformErrorDescription(error) + ')');
   {$ENDIF}
end;

function oxglTRenderer.GetContext(wnd: oxTWindow; shareContext: loopint): loopint;
var
   error: loopint;
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
      logtv('Created rendering context: glrc ' + sf(rc));
   end else begin
      error := glPlatform^.RaiseError();
      wnd.RaiseError(eFAIL, 'Not a valid rendering context ' + GetPlatformErrorDescription(error));
      Result := -1;
   end;
end;

function oxglTRenderer.GetContextString(index: loopint): StdString;
begin
   Result := sf(glRenderingContexts[index]);
end;

procedure oxglTRenderer.ContextCurrent(const context: oxTRenderTargetContext);
var
   error: loopint;
   rc: loopint;

begin
   rc := context.RenderContext;

   if(rc >= 0) then begin
      logtv('Set render context ' + sf(rc) +  ' (glrc: ' + sf(glRenderingContexts[rc]) + ') current');

      error := 0;

      if(not glPlatform^.ContextCurrent(context)) then
         error := glPlatform^.RaiseError();

      if(error <> 0) then
         logtw('Failed to set context ' + sf(rc) + ' current: ' + GetPlatformErrorDescription(error));

      RenderingContexts[rc].Used := true;

      if(context.Target^.Typ = oxRENDER_TARGET_WINDOW) then
         RenderingContexts[rc].Window := oxTWindow(context.Target^.Target)
      else
         RenderingContexts[rc].Window := nil;
   end;
end;

procedure oxglTRenderer.ClearContext(context: loopint);
var
   error: loopint;
   wnd: oglTWindow;

begin
   if(context >= 0) then begin
      wnd := oglTWindow(RenderingContexts[context].Window);

      error := 0;

      if(not glPlatform^.ClearContext(wnd)) then
         error := glPlatform^.RaiseError();

      if(error = 0) then
         logtv('Cleared context ' + sf(context))
      else
         logtw('Failed to clear context ' + sf(context) + ': ' + GetPlatformErrorDescription(error));

      RenderingContexts[context].Used := false;
   end;
end;

function oxglTRenderer.DestroyContext(context: loopint): boolean;
var
   error: loopint;
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
      Result := glPlatform^.DestroyContext(wnd, rc);

      error := 0;

      if(not Result) then
         error := glPlatform^.RaiseError();

      if(error <> 0) then
         logtw('Failed to destroy context ' + sf(context) + '  current: ' + GetPlatformErrorDescription(error));

      glRenderingContexts[context] := oglRenderingContextNull;
   end;
end;

procedure oxglTRenderer.StartThread(wnd: oxTWindow);
begin
   ogl.InitState();
end;

procedure oxglTRenderer.StopThread(wnd: oxTWindow);
begin
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

   {$IFDEF OX_DEBUG}
   ogl.eRaise();
   {$ENDIF}
end;

procedure oxglTRenderer.ClearColor(c: TColor4f);
begin
   glClearColor(c[0], c[1], c[2], c[3]);
end;

function oxglTRenderer.GetSummary(): TStringArray;
var
   list: array[0..3] of StdString;

begin
   list[0] := 'Vendor: ' + oxglRendererInfo.Vendor;
   list[1] := 'Renderer: ' + oxglRendererInfo.Renderer;
   list[2] := 'OpenGL: ' + oxglRendererInfo.sVersion;
   list[3] := 'GLSL Version: ' + oxglRendererInfo.GLSL.Version;

   Result := list;
end;

function oxglTRenderer.GetPlatformErrorDescription(error: loopint): StdString;
begin
   Result := glPlatform^.Name + ' error: ' + glPlatform^.GetErrorDescription(error);
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
