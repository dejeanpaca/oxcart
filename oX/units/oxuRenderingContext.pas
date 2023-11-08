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
      oxuViewportType, oxuProjectionType, oxuCamera;

TYPE
   oxTRenderingContext = record
      Name: StdString;

      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: oxPCamera;
   end;

THREADVAR
   oxRenderingContext: oxTRenderingContext;

IMPLEMENTATION

END.
