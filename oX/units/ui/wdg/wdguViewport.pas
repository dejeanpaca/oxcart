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
      oxuTypes, oxuProjectionType, oxuProjection, oxuWindowTypes,
      {ui}
      uiuWindowRender,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase;

TYPE

   { wdgTViewport }

   wdgTViewport = class(uiTWidget)
      PreviousProjection: oxPProjection;
      Projection: oxTProjection;
      AlwaysClear,
      AutoProjectionName: boolean;

      constructor Create(); override;
      procedure Initialize(); override;
      procedure Render(); override;

      procedure ProjectionStart();
      procedure CleanupRender();

      procedure UpdateViewport();

      procedure CaptionChanged(); override;
      procedure SizeChanged(); override;
      procedure RPositionChanged(); override;
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
   Projection.ClearColor.Assign(0.2, 0.2, 0.2, 1.0);

   AutoProjectionName := true;
   AlwaysClear := true;
end;

procedure wdgTViewport.Initialize();
begin
   inherited;

   if(oxTWindow(oxwParent).ExternalWindow <> nil) then
     Projection.SetOffset(oxTWindow(oxwParent).Projection.Offset);
end;

procedure wdgTViewport.Render();
begin
   ProjectionStart();
   CleanupRender();
end;

procedure wdgTViewport.ProjectionStart();
begin
   PreviousProjection := oxProjection;
   Projection.Apply(AlwaysClear);
end;

procedure wdgTViewport.CleanupRender();
begin
   PreviousProjection^.Apply(false);
   uiWindowRender.Prepare(oxTWindow(oxwParent));
end;

procedure wdgTViewport.UpdateViewport();
begin
   Projection.SetViewport(RPosition.x, RPosition.y - Dimensions.h + 1, Dimensions.w, Dimensions.h);
end;

procedure wdgTViewport.CaptionChanged();
begin
  inherited CaptionChanged();

  if(AutoProjectionName) then
     Projection.Name := Caption;
end;

procedure wdgTViewport.SizeChanged();
begin
   UpdateViewport();
end;

procedure wdgTViewport.RPositionChanged();
begin
   UpdateViewport();
end;

INITIALIZATION
   wdgViewport.Internal.Register('widget.viewport', @init, @deinit);

END.
