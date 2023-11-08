{
   oxuRenderThread,
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderThread;

INTERFACE

   USES
      uStd,
      {ox}
      oxuWindowTypes, oxuRenderer, oxuRenderingContext;

TYPE
   { oxTRenderThread }

   oxTRenderThread = record
      procedure StartThread({%H-}wnd: oxTWindow);
      procedure StopThread({%H-}wnd: oxTWindow);
   end;

VAR
   oxRenderThread: oxTRenderThread;

IMPLEMENTATION

{ oxTRenderThread }

procedure oxTRenderThread.StartThread(wnd: oxTWindow);
var
   rc: loopint;

begin
   rc := oxRenderer.GetContext(wnd);

   oxRenderingContext.UseWindow(wnd);
   oxRenderingContext.RC := rc;
   oxTRenderer(wnd.Renderer).ContextCurrent(rc);
   oxTRenderer(wnd.Renderer).StartThread(wnd);
end;

procedure oxTRenderThread.StopThread(wnd: oxTWindow);
begin
   oxTRenderer(wnd.Renderer).StopThread(wnd);
   oxTRenderer(wnd.Renderer).ClearContext(oxRenderingContext.RC);
   oxTRenderer(wnd.Renderer).DestroyContext(oxRenderingContext.RC);
end;

END.
