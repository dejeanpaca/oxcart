{
   uiuRender, UI rendering
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuRender;

INTERFACE

   USES
      {ox}
      oxuProjectionType, oxuProjection, oxuViewportType,
      {ui}
      uiuDraw;

TYPE

   { uiTRender }

   uiTRender = record
      procedure Prepare(var projection: oxTProjection; var viewport: oxTViewport);
   end;

VAR
   uiRender: uiTRender;

IMPLEMENTATION

{ uiTRender }

procedure uiTRender.Prepare(var projection: oxTProjection; var viewport: oxTViewport);
begin
  oxTProjection.Create(Projection, @Viewport);

  Projection.Ortho(0.375, viewport.Dimensions.w + 0.375, 0.375, viewport.Dimensions.h + 0.375, -1.0, 1.0);
  Projection.Apply();

  uiDraw.Start();
end;

END.
