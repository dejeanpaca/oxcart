{
   oxuWindow, oX window management
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindow;

INTERFACE

   USES
      uStd, uLog, StringUtils, uAppInfo,
      {oX}
      uOX, oxuTypes, oxuViewport, oxuGlobalInstances,
      oxuWindowTypes, oxuWindowHelper,
      oxuPlatform, oxuUIHooks, oxuRenderer, oxuRender,
      {ui}
      uiuWindowTypes, uiuTypes;

TYPE

   { oxTWindowGlobal }

   oxTWindowGlobal = record
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

VAR
   oxWindow: oxTWindowGlobal;

IMPLEMENTATION

procedure oxTWindowGlobal.Init(wnd: oxTWindow; contextWindow: boolean = false);
var
   title: string;

begin
   title := oxEngineName;

   if(appInfo.Title <> '') then
      title := appInfo.Title
   else if(appInfo.Name <> '') then
      title := appInfo.Name
   else if(appInfo.NameShort <> '') then
      title := appInfo.NameShort;

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
   oxViewport := @wnd.Viewport;
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

begin
   Result := false;

   renderer := oxTRenderer(wnd.Renderer);
   renderer.SetupData(wnd);

   log.Enter('Window: ' + wnd.Title(* + ' (' + uiwGetIDString(wnd.w.wID) + ')'*));
      log.i('Requested Size: ' + sf(wnd.Dimensions.w) + 'x' + sf(wnd.Dimensions.h));

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

   {create window only if it is not already created}
   if(not wnd.oxProperties.Created) then begin
      if(not oxPlatform.MakeWindow(wnd)) then begin
         if(wnd.ErrorCode = eNONE) then
            wnd.ErrorCode := eFAIL;

         log.Leave();
         exit;
      end;

      {create a thread rendering context}
      {$IFNDEF NO_THREADS}
      if(oxTRenderer(wnd.Renderer).Properties.SupportsThreading) then begin
         wnd.ThreadRenderingContext := oxTRenderer(wnd.Renderer).GetContext(wnd, wnd.RenderingContext);

        if(wnd.ErrorCode = 0) then
           log.v('Created thread render context');
      end;
      {$ENDIF}

      {success}
      wnd.oxProperties.Created := true;
      Result := true;
   end;

   windowCreateCommon(wnd);

   Result := renderer.SetupWindow(wnd);

   if(Result) then
      windowCreateFinalize(wnd);

   log.Leave();
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

INITIALIZATION
   oxGlobalInstances.Add('oxTWindowGlobal', @oxWindow);

END.
