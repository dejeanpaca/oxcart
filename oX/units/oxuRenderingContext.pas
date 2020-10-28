{
   oxuRenderingContext
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderingContext;

INTERFACE

   USES
      uStd,
      {oX}
      oxuWindowTypes, oxuViewportType, oxuProjectionType;

TYPE
   oxPRenderingContext = ^oxTRenderingContext;

   { oxTRenderingContext }

   oxTRenderingContext = record
      Name: StdString;
      {rendering context Id of the renderer}
      RC: loopint;

      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: pointer;
      {window associated with this rendering context, if any}
      Window: oxTWindow;

      procedure UseWindow(wnd: oxTWindow);
   end;

THREADVAR
   oxRenderingContext: oxTRenderingContext;

IMPLEMENTATION

{ oxTRenderingContext }

procedure oxTRenderingContext.UseWindow(wnd: oxTWindow);
begin
   Viewport := @wnd.Viewport;
   Window := Window;
end;

END.
