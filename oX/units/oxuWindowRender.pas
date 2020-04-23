{
   oxuWindowRender, renders oX windows
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowRender;

INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuWindowTypes, oxuWindow, oxuGlobalInstances,
      oxuViewport, oxuRenderer,
      oxuWindows, oxuUIHooks,
      {$IFDEF OX_LIBRARY}
      oxuRenderers,
      {$ENDIF}
      {io}
      uiuControl;

TYPE
   oxPWindowRender = ^oxTWindowRender;

   { oxTWindowRender }

   oxTWindowRender = record
      {if true, the OnOverrideRender callbacks will be called and no rendering will be done by default}
      OverrideRender: Boolean;

      {start rendering for a window (clear)}
      procedure StartRender(wnd: oxTWindow);

      {render window(s)}
      procedure Window(wnd: oxTWindow);
      procedure All();

      {swaps the buffers for all windows}
      procedure SwapBuffers(wnd: oxTWindow);
      procedure SwapBuffers();
   end;

VAR
   oxWindowRender: oxTWindowRender;
   {$IFDEF OX_LIBRARY}
   oxExternalWindows: oxPWindows;
   {$ENDIF}

IMPLEMENTATION

procedure oxwRenderPost(wnd: oxTWindow);
begin
   oxuiHooks.Render(wnd);
end;

procedure oxTWindowRender.StartRender(wnd: oxTWindow);
begin
   if(wnd.oxProperties.ApplyDefaultViewport) then
      wnd.Viewport.Apply();
end;

{All window(s)}
procedure oxTWindowRender.Window(wnd: oxTWindow);
begin
   if(not OverrideRender) then begin
      StartRender(wnd);

      oxWindows.OnRender.Call(wnd);
      oxWindows.Internal.OnPostRender.Call(wnd);

      {$IFNDEF OX_LIBRARY}
      oxTRenderer(wnd.Renderer).SwapBuffers(wnd);
      {$ENDIF}
   end else
      oxWindows.OnOverrideRender.Call(wnd);
end;

procedure oxTWindowRender.All();
var
   i: loopint;

begin
   for i := 0 to oxWindows.n - 1 do
      Window(oxWindows.w[i]);
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

INITIALIZATION
   oxGlobalInstances.Add('oxTWindowRender', @oxWindowRender);

END.
