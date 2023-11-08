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
      oxuTimer, oxuViewport, oxuRenderer, oxuRenderingContext,
      oxuWindows,
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
      {if true, the OnOverrideRender callbacks will be called and no rendering will be done by default}
      OverrideRender: Boolean;
      Rendered: boolean;

      constructor Create();

      {start rendering for a window (clear)}
      procedure StartRender(wnd: oxTWindow);

      {render window(s)}
      procedure Window(wnd: oxTWindow); virtual;
      procedure All(); virtual;

      {swaps the buffers for all windows}
      procedure SwapBuffers(wnd: oxTWindow);
      procedure SwapBuffers();

      {set rendering context to window}
      procedure ContextCurrent(wnd: oxTWindow);
   end;

VAR
   oxWindowRender: oxTWindowRender;

IMPLEMENTATION

procedure oxwRenderPost(wnd: oxTWindow);
begin
   oxuiHooks.Render(wnd);
end;

constructor oxTWindowRender.Create();
begin
end;

procedure oxTWindowRender.StartRender(wnd: oxTWindow);
var
   rc: oxPRenderingContext;

begin
   if(wnd.oxProperties.ApplyDefaultViewport) then
      wnd.Viewport.Apply();

   rc := @oxRenderingContext;

   rc^.Viewport := @wnd.Viewport;
   rc^.Window := wnd;
   rc^.Camera := nil;
   rc^.Name := wnd.Title;
   rc^.RC := wnd.RenderingContext;
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

   if(not OverrideRender) then begin
      StartRender(wnd);

      oxWindows.OnRender.Call(wnd);
      oxWindows.Internal.OnPostRender.Call(wnd);

      if(not ox.LibraryMode) then
         oxTRenderer(wnd.Renderer).SwapBuffers(wnd);

      wnd.Viewport.Done();

      Rendered := true;
   end else
      oxWindows.OnOverrideRender.Call(wnd);
end;

procedure oxTWindowRender.All();
var
   i: loopint;

begin
   for i := 0 to oxWindows.n - 1 do begin
      Window(oxWindows.w[i]);
   end;
end;

procedure oxTWindowRender.SwapBuffers(wnd: oxTWindow);
begin
   oxTRenderer(wnd.Renderer).SwapBuffers(wnd);
end;

{ BUFFERS }
procedure oxTWindowRender.SwapBuffers();
var
   i: longint;

begin
   for i := 0 to (oxWindows.n - 1) do begin
      SwapBuffers(oxWindows.w[i]);
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
