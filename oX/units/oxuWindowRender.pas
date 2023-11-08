{
   oxuWindowRender, renders oX windows
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWindowRender;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      uOX, oxuWindowTypes, oxuWindow, oxuGlobalInstances,
      oxuTimer, oxuRenderer, oxuRenderingContext, oxuSurfaceRender,
      oxuWindows, oxuWindowHelper,
      {ui}
      oxuUIHooks, uiuWindow
      {lib}
      {$IFDEF OX_LIBRARY}
      , oxuRenderers
      {$ENDIF};

TYPE
   oxPWindowRender = ^oxTWindowRender;

   { oxTWindowRender }

   oxTWindowRender = object
      {have we rendered last frame}
      Rendered: boolean;

      constructor Create();

      {render window(s)}
      procedure Window(wnd: oxTWindow); virtual;
      procedure All(); virtual;

      {set rendering context to window}
      procedure ContextCurrent(wnd: oxTWindow);
   end;

VAR
   oxWindowRender: oxTWindowRender;

IMPLEMENTATION

constructor oxTWindowRender.Create();
begin
end;


{All window(s)}
procedure oxTWindowRender.Window(wnd: oxTWindow);
begin
   Rendered := false;

   if(not wnd.oxProperties.RenderUnfocused) and (not wnd.IsSelected()) then
      exit;

   if(not ox.LibraryMode) then begin
     if(wnd.RenderingContext < 0) then
        exit;

     if(not oxRenderingTimer.Elapsed()) then
        exit;
   end;

   if(not oxRenderingContext.CanRender) then
      exit;

   if(not wnd.oxProperties.RenderMinimized) and (wnd.IsMinimized()) then
      exit;

     oxSurfaceRender.Render(wnd);

   {viewport has been updated}
   if(wnd.Viewport.Changed) then
      wnd.SetupViewport();

   oxSurfaceRender.Render(wnd);

   Rendered := true;
end;

procedure oxTWindowRender.All();
var
   i: loopint;

begin
   for i := 0 to oxWindows.n - 1 do begin
      Window(oxWindows.w[i]);
   end;
end;

procedure oxTWindowRender.ContextCurrent(wnd: oxTWindow);
begin
   oxTRenderer(wnd.Renderer).ContextCurrent(wnd.RenderingContext, wnd.RenderTarget);
end;

INITIALIZATION
   oxWindowRender.Create();
   oxGlobalInstances.Add('oxTWindowRender', @oxWindowRender);

END.
