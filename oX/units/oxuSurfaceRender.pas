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
   oxTSurfaceRenderObjectRoutine = procedure(var context: oxTRenderingContext) of object;

   oxPSurfaceRenderer = ^oxTSurfaceRenderer;

   oxTSurfaceRenderer = record
      Name: string;
      Routine: oxTSurfaceRenderRoutine;
      Layer: loopint;
   end;

   oxTSurfaceRenderers = specialize TSimpleList<oxPSurfaceRenderer>;

   oxTSurfaceRenderContext = record
      Window: oxTWindow;

      {routine used to render}
      Routine: oxTSurfaceRenderRoutine;
      {object routine used to render}
      ObjectRoutine: oxTSurfaceRenderObjectRoutine;
   end;

   { oxTSurfaceRenderGlobal }

   oxTSurfaceRenderGlobal = record
      List: oxTSurfaceRenderers;

      procedure Initialize();
      procedure Add(var renderer: oxTSurfaceRenderer);

      {get a surface renderer entry and add it to the list}
      procedure Get(out renderer: oxTSurfaceRenderer; routine: oxTSurfaceRenderRoutine);

      class procedure Initialize(out context: oxTSurfaceRenderContext); static;

      {render a surface context}
      procedure Render(var context: oxTSurfaceRenderContext);
      {render a window}
      procedure Render(wnd: oxTWindow);
      {render window with this method only}
      procedure RenderOnly(wnd: oxTWindow; renderRoutine: oxTSurfaceRenderObjectRoutine);
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
end;

class procedure oxTSurfaceRenderGlobal.Initialize(out context: oxTSurfaceRenderContext);
begin
   ZeroOut(context, SizeOf(context));
end;

procedure oxTSurfaceRenderGlobal.Render(var context: oxTSurfaceRenderContext);
var
   rc: oxPRenderingContext;
   i: loopint;
   wnd: oxTWindow;

begin
   wnd := context.Window;

   if(wnd.oxProperties.ApplyDefaultViewport) then
      wnd.Viewport.Apply();

   rc := @oxRenderingContext;

   rc^.Viewport := @wnd.Viewport;
   rc^.Window := wnd;
   rc^.Camera := nil;
   rc^.Name := wnd.Title;
   rc^.RC := wnd.RenderingContext;

   if(context.Routine = nil) and (context.ObjectRoutine = nil) then begin
      for i := 0 to List.n - 1 do begin
         List.List[i]^.Routine(rc^);
      end;
   end else begin
      if(context.Routine <> nil) then
         context.Routine(rc^);

      if(context.ObjectRoutine <> nil) then
         context.ObjectRoutine(rc^);
   end;

   if(not ox.LibraryMode) then
      oxTRenderer(wnd.Renderer).SwapBuffers(wnd);

   wnd.Viewport.Done();
end;

procedure oxTSurfaceRenderGlobal.Render(wnd: oxTWindow);
var
   context: oxTSurfaceRenderContext;

begin
   Initialize(context);
   context.Window := wnd;
   Render(context);
end;

procedure oxTSurfaceRenderGlobal.RenderOnly(wnd: oxTWindow; renderRoutine: oxTSurfaceRenderObjectRoutine);
var
   context: oxTSurfaceRenderContext;

begin
   Initialize(context);
   context.Window := wnd;
   context.ObjectRoutine := renderRoutine;
   Render(context);
end;

INITIALIZATION
   oxSurfaceRender.Initialize();
END.

