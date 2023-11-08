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

      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: pointer;
      Window: oxTWindow;
   end;

THREADVAR
   oxRenderingContext: oxTRenderingContext;

IMPLEMENTATION

END.
