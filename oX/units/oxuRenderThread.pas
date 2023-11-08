{
   oxuRenderThread,
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderThread;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {ox}
      oxuTypes, oxuWindowTypes, oxuRenderer, oxuRenderingContext;

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
var
   rtc: oxTRenderTargetContext;
   errorDescription: StdString;

begin
   oxRenderingContext.Initialize();

   wnd.FromWindow(rtc);
   rtc.RenderContext := rc;

   oxRenderingContext.UseWindow(wnd);
   oxRenderingContext.RC := rc;

   if(rc > -1) then begin
      oxTRenderer(wnd.Renderer).ContextCurrent(rtc);
      errorDescription := oxTRenderer(wnd.Renderer).CheckError();

      if(errorDescription <> '') then
         log.e(errorDescription);
   end;

   oxTRenderer(wnd.Renderer).StartThread(wnd);
   oxTRenderer(wnd.Renderer).logtv('Started rendering thread: ' + sf(oxRenderingContext.RC));
end;

procedure oxTRenderThread.StopThread(wnd: oxTWindow);
var
   wasRC: loopint;

begin
   wasRC := oxRenderingContext.RC;
   oxTRenderer(wnd.Renderer).StopThread(wnd);

   if(oxRenderingContext.RC > -1) then begin
      oxTRenderer(wnd.Renderer).ClearContext();
      oxRenderingContext.RC := -1;
   end;

   oxTRenderer(wnd.Renderer).logtv('Stopped rendering thread: ' + sf(wasRC));
end;

END.
