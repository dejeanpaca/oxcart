{
   oxuRenderTask, rendering task
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderTask;

INTERFACE

   USES
      uTiming, uStd, uLog, uColors, StringUtils,
      {oX}
      uOX, oxuTypes, oxuWindowTypes,
      oxuRenderer, oxuRender, oxuRenderThread, oxuSurfaceRender, oxuRenderingContext,
      oxuThreadTask, oxuWindow,
      oxuRunRoutines, oxuTimer;


TYPE
   { oxTRenderTask }

   oxTRenderTask = class(oxTThreadTask)
      RC: loopint;

      {associated window}
      AssociatedWindow: oxTWindow;

      Timer,
      RenderingTimer: TTimer;
      TimeFlow: Single;

      constructor Create(); override;
      destructor Destroy(); override;

      {startup render for a window}
      procedure StartRender(wnd: oxTWindow); virtual;
      {load and initialize all required resources}
      procedure Load(); virtual;
      {unload all resources}
      procedure Unload(); virtual;
      {render the content}
      procedure Render(); virtual;
      {renders content here}
      procedure RenderContent(var {%H-}context: oxTRenderingContext); virtual;

      {run rendering in a separate thread, use instead of Start()}
      procedure RunThreaded(wnd: oxTWindow);
      {restore rendering context to the associated window}
      procedure RestoreRender();

      {called to update the content (animate, calculate, and what else, but not render)}
      procedure Update(); virtual;
      {waits until display time passsed}
      procedure WaitForDisplayTime();

      {runs the task main logic}
      procedure Run(); override;

      procedure TaskStart(); override;
      procedure TaskStop(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   oxTRenderTaskClass = class of oxTRenderTask;


IMPLEMENTATION

{ oxTRenderTask }

constructor oxTRenderTask.Create();
begin
   inherited;

   Timer.InitStart();
   RenderingTimer.InitStart();

   EmitAllEvents();
end;

destructor oxTRenderTask.Destroy();
begin
   Unload();

   inherited Destroy;
end;

procedure oxTRenderTask.StartRender(wnd: oxTWindow);
begin
   AssociatedWindow := wnd;

   Timer.Start();
   Load();

   RenderingTimer.InitStart();
end;

procedure oxTRenderTask.Load();
begin
end;

procedure oxTRenderTask.Unload();
begin

end;

procedure oxTRenderTask.Render();
begin
   if(AssociatedWindow <> nil) then
      oxSurfaceRender.RenderOnly(AssociatedWindow, @RenderContent);
end;

procedure oxTRenderTask.RenderContent(var context: oxTRenderingContext);
begin

end;

procedure oxTRenderTask.RunThreaded(wnd: oxTWindow);
begin
   StartRender(wnd);

   Start();
end;

procedure oxTRenderTask.RestoreRender();
var
   rtc: oxTRenderTargetContext;

begin
   AssociatedWindow.FromWindow(rtc);
   oxTRenderer(AssociatedWindow.Renderer).ContextCurrent(rtc);
end;

procedure oxTRenderTask.Update();
begin
end;

procedure oxTRenderTask.WaitForDisplayTime();
begin

end;

procedure oxTRenderTask.Run();
begin
   Update();
   TimeFlow := RenderingTimer.TimeFlow();
   Render();
end;

procedure oxTRenderTask.TaskStart();
begin

   {start the thread}
   oxRenderThread.StartThread(AssociatedWindow, RC);
   log.v('(t: ' + getThreadIdentifier() + ') Started thread: ' + GetName());
end;

procedure oxTRenderTask.TaskStop();
begin
   Unload();

   oxRenderThread.StopThread(AssociatedWindow);

   log.v('(t: ' + getThreadIdentifier() + ') Ended render thread: ' + GetName());
end;

procedure oxTRenderTask.ThreadStart();
var
   renderer: oxTRenderer;

begin
   renderer := oxTRenderer(AssociatedWindow.Renderer);

   {get an RC to render this task}
   RC := renderer.GetRenderingContext(AssociatedWindow);
   log.v('(t: ' + getThreadIdentifier() + ') Render task: ' + GetName() + ' got RC: ' + sf(RC));

   log.v('(t: ' + getThreadIdentifier() + ') Started render task: ' + GetName());
end;

procedure oxTRenderTask.ThreadDone();
begin
   log.v('(t: ' + getThreadIdentifier() + ') Done render task: ' + GetName());
end;

END.
