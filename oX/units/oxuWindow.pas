{
   oxuWindow, oX window management
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindow;

INTERFACE

   USES
      uStd, uLog, StringUtils, uAppInfo,
      {oX}
      uOX, oxuTypes, oxuProjection, oxuGlobalInstances,
      oxuWindowTypes, oxuPlatform, oxuUIHooks, oxuRenderer, oxuRender,
      {ui}
      uiuWindowTypes, uiuTypes;

TYPE

   { oxTWindowGlobal }

   oxTWindowGlobal = class
      {currently selected window}
      Current: oxTWindow;

      {initialize a oxTWindow record}
      procedure Init(wnd: oxTWindow; contextWindow: boolean = false);

      {create a window}
      function CreateWindow(wnd: oxTWindow; externalWindow: TObject = nil): boolean;
      {destroy a window}
      procedure Dispose(wnd: oxTWindow);
      {destroy all rendering contexts associated with the given window}
      procedure DestroyRenderingContexts(wnd: oxTWindow);
   end;


   { oxTWindowHelper }

   oxTWindowHelper = class helper for oxTWindow
      {set position and dimensions of a window}
      procedure SetPosition(x, y: longint; system: boolean = true);
      procedure SetDimensions(w, h: longint; system: boolean = true);

      procedure SetupProjection();
      procedure SetProjectionOffset();

      procedure Maximize();
      procedure Minimize();
      procedure Restore();
      {set title of window}
      procedure SetTitle(const newTitle: string);

      {set a frame for the window}
      procedure SetFrame(fs: uiTWindowFrameStyle);

      procedure Fullscreen();
      procedure WindowedFullscreen();
      procedure LeaveFullscreen();
      procedure ToggleFullscreen();
      procedure ToggleWindowedFullscreen();
   end;

VAR
   oxWindow: oxTWindowGlobal;

IMPLEMENTATION

procedure oxTWindowGlobal.Init(wnd: oxTWindow; contextWindow: boolean = false);
var
   title: string;

begin
   title             := oxEngineName;
   if(appInfo.title <> '') then
      title          := appInfo.title
   else if(appInfo.name <> '') then
      title          := appInfo.name
   else if(appInfo.nameShort <> '') then
      title          := appInfo.nameShort;

   wnd.Renderer := oxRenderer;
   wnd.Platform := oxPlatform;

   wnd.Title := title;
   wnd.RenderSettings := oxRenderer.WindowSettings;

   if(not contextWindow) then
      oxUIHooks.InitializeWindow(wnd);

   wnd.SetPosition(wnd.Position.x, wnd.Position.y);
   wnd.SetDimensions(wnd.Dimensions.w, wnd.Dimensions.h);
end;

procedure windowCreateFinalize(wnd: oxTwindow);
begin
   oxTRenderer(wnd.Renderer).OnWindowInit.Call(wnd);

   {$IFDEF OX_LIBRARY}
   oxTRenderer(wnd.Renderer).InitWindowLibrary(wnd);
   {$ENDIF}
end;

procedure windowCreateCommon(wnd: oxTWindow);
begin
   oxProjection := @wnd.Projection;
   oxUIHooks.Select(wnd);

   if(wnd.oxProperties.Fullscreen) then begin
      wnd.oxProperties.Fullscreen := false;
      wnd.Fullscreen();
   end;

   if(not wnd.oxProperties.Context) then
      oxUIHooks.UpdatePosition(wnd);
end;

{create a window which is only part of an external window (e.g. running in a library)}
function windowCreateExternal(wnd: oxTWindow; externalWindow: uiTWindow): boolean;
var
   oxw: oXTWindow;
   renderer: oxTRenderer;
   rendererOk: boolean;

begin
   oxw := oxTWindow(externalWindow.oxwParent);

   wnd.ExternalWindow := uiTWindow(externalWindow);
   wnd.oxwExternal := oxw;

   renderer := oxTRenderer(wnd.Renderer);
   wnd.RenderSettings := oxw.RenderSettings;

   renderer.SetupData(wnd);

   wnd.oxProperties.Created := true;
   wnd.SetDimensions(externalWindow.Dimensions.w, externalWindow.Dimensions.h, false);
   wnd.SetupProjection();

   windowCreateCommon(wnd);

   rendererOk := renderer.SetupWindow(wnd);
   Result := rendererOk;

   if(rendererOk) then begin
      windowCreateFinalize(wnd);

      log.v('Created external window from: ' + externalWindow.Title);
   end;
end;

function windowCreate(wnd: oxTWindow): boolean;
var
   s: string;
   renderer: oxTRenderer;
   rendererOk: boolean;

begin
   Result := false;

   renderer := oxTRenderer(wnd.Renderer);
   renderer.SetupData(wnd);

   log.Enter('Window: ' + wnd.Title(* + ' (' + uiwGetIDString(wnd.w.wID) + ')'*));
      log.i('Size: ' + sf(wnd.Dimensions.w) + 'x' + sf(wnd.Dimensions.h));

      if(wnd.RenderSettings.DoubleBuffer) then
         s := 'double buffer'
      else
         s := 'single buffer';

      if(wnd.RenderSettings.Software) then
         s := s + ', software rendered';

      if(wnd.RenderSettings.Stereo) then
         s := s + ', stereo';

      if(wnd.RenderSettings.VSync) then
         s := s + ', vsync';

      log.Enter('Properties >');
         log.i('Color: '    + sf(wnd.RenderSettings.ColorBits));

         if(wnd.RenderSettings.DepthBits > 0) then
            log.i('Depth: '    + sf(wnd.RenderSettings.DepthBits));

         if(wnd.RenderSettings.StencilBits > 0) then
            log.i('Stencil: '  + sf(wnd.RenderSettings.StencilBits));

         if(wnd.RenderSettings.AccumBits > 0) then
            log.i('Accum: '    + sf(wnd.RenderSettings.AccumBits));

         log.i('Flags: ' + s);
      log.Leave();

      oxTRenderer(wnd.Renderer).LogWindow(wnd);
   log.Leave();

   {create window only if it is not already created}
   if(not wnd.oxProperties.Created) then begin
      if(not oxPlatform.MakeWindow(wnd)) then begin
         if(wnd.ErrorCode = eNONE) then
            wnd.ErrorCode := eFAIL;

         exit;
      end;

      {success}
      wnd.oxProperties.Created := true;
      Result := true;
   end;

   windowCreateCommon(wnd);

   rendererOk := renderer.SetupWindow(wnd);
   Result := rendererOk;

   if(rendererOk) then
      windowCreateFinalize(wnd);
end;

function oxTWindowGlobal.CreateWindow(wnd: oxTWindow; externalWindow: TObject): boolean;
begin
   if(externalWindow = nil) then
      Result := windowCreate(wnd)
   else
      Result := windowCreateExternal(wnd, uiTWindow(externalWindow));

   if(wnd.ErrorDescription <> '') then
      log.e('Failed to create window: ' + wnd.Title);

   if(Result) then begin
      {$IFNDEF OX_LIBRARY}
      oxRenderer.Clear(oxrBUFFER_CLEAR_DEFAULT);
      oxRenderer.SwapBuffers(wnd);
      {$ENDIF}
   end else begin
      oxWindow.Dispose(wnd);
   end;
end;

procedure oxTWindowGlobal.Dispose(wnd: oxTWindow);
begin
   if(wnd <> nil) then begin
      log.i('Destroying window: ' + wnd.Title);

      Include(wnd.Properties, uiwndpDISPOSED);

      if(wnd.oxProperties.Created) then begin
         if(not wnd.oxProperties.Context) then
            oxUIHooks.DestroyWindow(wnd);

         {$IFNDEF OX_LIBRARY}
         DestroyRenderingContexts(wnd);
         oxPlatform.DestroyWindow(wnd);
         {$ENDIF}
      end;
   end;
end;

procedure oxTWindowGlobal.DestroyRenderingContexts(wnd: oxTWindow);
begin
   oxTRenderer(wnd.Renderer).ClearContext(wnd.RenderingContext);

   {destroy context}
   if(wnd.RenderingContext > -1) then begin
      if(not oxTRenderer(wnd.Renderer).DestroyContext(wnd.RenderingContext)) then
         wnd.DestroyFail('Failed to destroy RC for window.');

      wnd.RenderingContext := -1;
   end;

   if(wnd.ThreadRenderingContext > -1) then begin
      if(not oxTRenderer(wnd.Renderer).DestroyContext(wnd.ThreadRenderingContext)) then
         wnd.DestroyFail('Failed to destroy thread RC for window.');

      wnd.ThreadRenderingContext := -1;
   end;

   oxTRenderer(wnd.Renderer).DestroyAllRenderingContexts(wnd);
end;

{ oxTWindowHelper }

procedure oxTWindowHelper.Fullscreen();
begin
   if(not oxProperties.Fullscreen) then begin
      FullscreenPosition := Position;
      FullscreenDimensions := Dimensions;

      if(oxPlatform.Fullscreen(self)) then begin
         SetPosition(0, 0);

         if(oxProperties.WindowedFullscreen) then
            Maximize();

         oxPlatform.ShowWindow(self);
         oxProperties.Fullscreen := true;

         log.i('Entered fullscreen: ' + Title);
      end else
         log.e('Failed to enter fullscreen: ' + Title);
   end;
end;

procedure oxTWindowHelper.WindowedFullscreen();
begin
   if(oxProperties.Fullscreen) then
      exit;

   oxProperties.WindowedFullscreen := true;
   Fullscreen();
end;

procedure oxTWindowHelper.LeaveFullscreen();
begin
   if(oxProperties.Fullscreen) then begin
      if(oxPlatform.LeaveFullscreen(self)) then begin
         oxPlatform.ShowWindow(self);

         SetPosition(FullscreenPosition.x, FullscreenPosition.y);
         SetDimensions(FullscreenDimensions.w, FullscreenDimensions.h);

         oxProperties.Fullscreen := false;
         log.i('Left fullscreen: ' + Title);
      end else
         log.e('Failed to leave fullscreen: ' + Title);
   end;
end;

procedure oxTWindowHelper.ToggleFullscreen();
begin
   if(not oxProperties.Fullscreen) then
      Fullscreen()
   else
      LeaveFullscreen();
end;

procedure oxTWindowHelper.ToggleWindowedFullscreen();
begin
   if(not oxProperties.Fullscreen) then
      WindowedFullscreen()
   else
      LeaveFullscreen();
end;

procedure oxTWindowHelper.SetPosition(x, y: longint; system: boolean);
begin
   Position.x := x;
   Position.y := y;

   if(not oxProperties.Context) then begin
      if(system) and (oxProperties.Created) then
         oxPlatform.Move(self, x, y);

      if(oxProperties.Created) then
         oxUIHooks.SetPosition(self, oxPoint(x, y));

      SetupProjection();
   end;
end;

procedure oxTWindowHelper.SetDimensions(w, h: longint; system: boolean);
begin
   Dimensions.w := w;
   Dimensions.h := h;

   if(not oxProperties.Context) then begin
      if(system) and (oxProperties.Created) then
         oxPlatform.Resize(self, w, h);

      if(oxProperties.Created) then
         oxUIHooks.SetDimensions(self, oxTDimensions.Make(w, h));

      SetupProjection();
   end;
end;

procedure oxTWindowHelper.SetupProjection();
begin
   Projection.SetViewport(Dimensions.w, Dimensions.h);
   SetProjectionOffset();
end;

procedure oxTWindowHelper.SetProjectionOffset();
begin
   if(ExternalWindow <> nil) then
      Projection.SetOffset(ExternalWindow.RPosition.x, ExternalWindow.RPosition.y - (ExternalWindow.Dimensions.h - 1))
   else
      Projection.SetOffset(0, 0);
end;

procedure oxTWindowHelper.Maximize();
begin
   if(oxProperties.Fullscreen) then
      exit;

   oxPlatform.Maximize(Self);

   if(oxUIHooks <> nil) then
      oxUIHooks.Maximize(Self);
end;

procedure oxTWindowHelper.Minimize();
begin
   if(oxProperties.Fullscreen) then
      exit;

   oxPlatform.Minimize(Self);

   if(oxUIHooks <> nil) then
      oxUIHooks.Minimize(Self);
end;

procedure oxTWindowHelper.Restore();
begin
   if(oxProperties.Fullscreen) then begin
      LeaveFullscreen();
      exit;
   end;

   oxPlatform.Restore(Self);

   if(oxUIHooks <> nil) then
      oxUIHooks.Restore(Self);
end;

procedure oxTWindowHelper.SetTitle(const newTitle: string);
begin
   log.v('oX > Set window title to: ' + newTitle + ' from ' + Title);

   Title := newTitle;

   if(oxProperties.Created) then begin
      if(not oxProperties.Context) and (oxProperties.Created) then begin
         uiTWindow(Self).SetTitle(newTitle);
         oxTPlatform(Platform).SetTitle(Self, newTitle);
      end;
   end;
end;

procedure oxTWindowHelper.SetFrame(fs: uiTWindowFrameStyle);
begin
   Frame := fs;
   {TODO: set the frame here for the system}
   if(oxProperties.Created) then;
end;

function instanceGlobal(): TObject;
begin
   Result := oxTWindowGlobal.Create();
end;

INITIALIZATION
   oxGlobalInstances.Add(oxTWindowGlobal, @oxWindow, @instanceGlobal);

END.
