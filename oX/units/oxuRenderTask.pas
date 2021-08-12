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
   log.v('Started render task: ' + Name);
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
   if(AssociatedWindow <> nil) then
      oxRenderThread.StartThread(AssociatedWindow, RC);
end;

procedure oxTRenderTask.TaskStop();
begin
   Unload();

   if(AssociatedWindow <> nil) then
      oxRenderThread.StopThread(AssociatedWindow);

   log.v('Ended render task: ' + Name);
end;

procedure oxTRenderTask.ThreadStart();
var
   renderer: oxTRenderer;
   rtc: oxTRenderTargetContext;

begin
   renderer := oxTRenderer(AssociatedWindow.Renderer);

   {get an RC to render the splash screen}
   RC := renderer.GetRenderingContext(AssociatedWindow);
   log.v('Render task: ' + Name + ' got RC: ' + sf(RC));


   {restore old context before proceeding}
   AssociatedWindow.FromWindow(rtc);

   renderer.ContextCurrent(rtc);
   {$IFNDEF NO_THREADS}
   log.v('Set up render task ' + Name + ' on thread: ' + sf(GetThreadID()));
   {$ENDIF}
end;

END.
