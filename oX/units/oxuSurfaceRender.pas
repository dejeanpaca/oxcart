{
   oxheader, handlers surface rendering
   Copyright (c) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSurfaceRender;

INTERFACE

USES
   uStd,
   {ox}
   uOX,
   oxuWindowTypes, oxuViewport,
   oxuRenderer, oxuRenderingContext;

TYPE
   oxTSurfaceRenderRoutine = procedure(var context: oxTRenderingContext);

   oxPSurfaceRenderer = ^oxTSurfaceRenderer;

   oxTSurfaceRenderer = record
      Name: string;
      Routine: oxTSurfaceRenderRoutine;
      Layer: loopint;
   end;

   oxTSurfaceRenderers = specialize TSimpleList<oxPSurfaceRenderer>;

   { oxTSurfaceRenderGlobal }

   oxTSurfaceRenderGlobal = record
      List: oxTSurfaceRenderers;

      procedure Initialize();
      procedure Add(var renderer: oxTSurfaceRenderer);

      {get a surface renderer entry and add it to the list}
      procedure Get(out renderer: oxTSurfaceRenderer; routine: oxTSurfaceRenderRoutine);

      procedure Render(wnd: oxTWindow);
   end;

VAR
  oxSurfaceRender: oxTSurfaceRenderGlobal;

IMPLEMENTATION

{ oxTSurfaceRenderGlobal }

procedure oxTSurfaceRenderGlobal.Initialize();
begin
   List.InitializeEmpty(List);
end;

procedure oxTSurfaceRenderGlobal.Add(var renderer: oxTSurfaceRenderer);
begin
   List.Add(@renderer);
end;

procedure oxTSurfaceRenderGlobal.Get(out renderer: oxTSurfaceRenderer; routine: oxTSurfaceRenderRoutine);
begin
   ZeroOut(renderer, SizeOf(renderer));

   renderer.Routine := routine;
   renderer.Layer := 1 shl List.n;

   List.Add(@renderer);

   writeln(renderer.Layer);
end;

procedure oxTSurfaceRenderGlobal.Render(wnd: oxTWindow);
var
   rc: oxPRenderingContext;
   i: loopint;

begin
   if(wnd.oxProperties.ApplyDefaultViewport) then
      wnd.Viewport.Apply();

   rc := @oxRenderingContext;

   rc^.Viewport := @wnd.Viewport;
   rc^.Window := wnd;
   rc^.Camera := nil;
   rc^.Name := wnd.Title;
   rc^.RC := wnd.RenderingContext;

   for i := 0 to List.n - 1 do begin
      List.List[i]^.Routine(rc^);
   end;

   if(not ox.LibraryMode) then
      oxTRenderer(wnd.Renderer).SwapBuffers(wnd);

   wnd.Viewport.Done();
end;

INITIALIZATION
   oxSurfaceRender.Initialize();
END.

