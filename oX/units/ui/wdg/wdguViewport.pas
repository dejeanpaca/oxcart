{
   wdguViewport, widget with its own rendering viewport
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguViewport;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuProjectionType, oxuProjection,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase;

TYPE

   { wdgTViewport }

   wdgTViewport = class(uiTWidget)
      Projection: oxTProjection;

      constructor Create(); override;
      procedure Render(); override;

      procedure UpdateViewport();

      procedure SizeChanged(); override;
      procedure PositionChanged(); override;
   end;

   wdgTViewportGlobal = class(specialize wdgTBase<wdgTViewport>)
     Internal: uiTWidgetClass; static;
   end;

VAR
   wdgViewport: wdgTViewportGlobal;

IMPLEMENTATION

procedure init();
begin
   wdgViewport.internal.Done(wdgTViewport);

   wdgViewport := wdgTViewportGlobal.Create(wdgViewport.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgViewport);
end;

{ wdgTViewport }

constructor wdgTViewport.Create();
begin
   inherited Create();

   oxTProjection.Create(Projection);
   Projection.Initialize(0, 0, 640, 480);
   Projection.Name := Caption;
   Projection.ClearColor.Assign(0.2, 0.2, 0.2, 1.0);
   Projection.Perspective(60, 0.5, 1000.0);
end;

procedure wdgTViewport.Render();
begin
   Projection.Apply();
end;

procedure wdgTViewport.UpdateViewport();
begin
   Projection.SetViewport(RPosition, Dimensions);
end;

procedure wdgTViewport.SizeChanged();
begin
   UpdateViewport();
end;

procedure wdgTViewport.PositionChanged();
begin
   UpdateViewport();
end;

INITIALIZATION
   wdgViewport.Internal.Register('widget.viewport', @init, @deinit);

END.
