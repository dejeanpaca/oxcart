{
   oxuRenderingContext
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRenderingContext;

INTERFACE

   USES
      uStd,
      {oX}
      oxuWindowTypes, oxuViewportType, oxuProjectionType;

TYPE
   oxPRenderingContext = ^oxTRenderingContext;

   oxTRenderingContext = record
      Name: StdString;
      {rendering context Id of the renderer}
      RC: loopint;

      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: pointer;
      {window associated with this rendering context, if any}
      Window: oxTWindow;
   end;

THREADVAR
   oxRenderingContext: oxTRenderingContext;

IMPLEMENTATION

END.
