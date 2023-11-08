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
      procedure StartThread({%H-}wnd: oxTWindow; rc: loopint = -1);
      procedure StopThread({%H-}wnd: oxTWindow);
   end;

VAR
   oxRenderThread: oxTRenderThread;

IMPLEMENTATION

{ oxTRenderThread }

procedure oxTRenderThread.StartThread(wnd: oxTWindow; rc: loopint);
begin
   oxRenderingContext.UseWindow(wnd);
   oxRenderingContext.RC := rc;

  if(rc > -1) then
      oxTRenderer(wnd.Renderer).ContextCurrent(rc);

   oxTRenderer(wnd.Renderer).StartThread(wnd);
end;

procedure oxTRenderThread.StopThread(wnd: oxTWindow);
begin
   oxTRenderer(wnd.Renderer).StopThread(wnd);

  if(oxRenderingContext.RC > -1) then
      oxTRenderer(wnd.Renderer).ClearContext(oxRenderingContext.RC);
end;

END.
