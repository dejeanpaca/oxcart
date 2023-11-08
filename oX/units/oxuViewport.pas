{
   oxuViewport, provides viewport management
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuViewport;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuTypes, oxuAspect, oxuWindowTypes, oxuViewportType, oxuRenderer, oxuRender;

TYPE

    { oxTViewportHelper }

    oxTViewportHelper = record helper for oxTViewport
       class procedure Create(out viewport: oxTViewport); static;

       procedure Initialize();
       procedure Initialize(x, y, w, h: longint);

       procedure Initialize(const source: oxTViewport);

       {apply this viewport}
       procedure Apply(doClear: boolean = true);

       {set viewport properties}
       procedure SetViewport(newW, newH: longint);
       procedure SetViewport(newX, newY, newW, newH: longint);
       procedure SetViewportf(newX, newY, newW, newH: single);
       {set the new offset}
       procedure SetOffset(offsetX, offsetY: longint);
       procedure SetOffset(const p: oxTPoint); inline;
       {setup the viewport}
       procedure Viewport();

       {clear buffers}
       procedure Clear();

       procedure SetViewport(const pt: oxTPoint; const d: oxTDimensions);
       {get settings from another viewport}
       procedure From(const source: oxTViewport);
       {set viewport from window}
       procedure SetFromWindow(wnd: oxTWindow);

       procedure GetNormalizedPointerCoordinates(x, y: single; out n: TVector2f);
       procedure GetNormalizedPointerCoordinates(x, y, z: single; out n: TVector4f);
    end;

VAR
   oxViewport: oxPViewport;

IMPLEMENTATION

class procedure oxTViewportHelper.Create(out viewport: oxTViewport);
begin
   ZeroPtr(@viewport, SizeOf(viewport));

   viewport.Initialize();
end;

procedure oxTViewportHelper.Initialize();
begin
   Enabled := true;
   ScissorOnClear := true;
   Changed := true;

   ClearBits := oxrBUFFER_CLEAR_DEFAULT;

   SetViewport(0, 0, 640, 480);
end;

procedure oxTViewportHelper.Initialize(x, y, w, h: longint);
begin
   Initialize();

   SetViewport(x, y, w, h);
end;

procedure oxTViewportHelper.Initialize(const source: oxTViewport);
begin
   From(source);
end;

procedure oxTViewportHelper.Apply(doClear: boolean);
begin
   if(Enabled) then begin
      Viewport();

      if(doClear) then
         Clear();

      oxViewport := @Self;
   end;
end;

procedure oxTViewportHelper.SetViewport(newW, newH: longint);
begin
   SetViewport(0, 0, newW, newH);
end;

procedure oxTViewportHelper.SetViewport(newX, newY, newW, newH: longint);
begin
   if (Dimensions.w <> newW) or (Dimensions.h <> newH) or (newX <> Position.x) or (newY <> Position.y) then begin
      Dimensions.w := newW;
      Dimensions.h := newH;

      Position.x := newX;
      Position.y := newY;

      a.Calculate(Dimensions.w, Dimensions.h);
   end;
end;

procedure oxTViewportHelper.SetViewportf(newX, newY, newW, newH: single);
begin
   Relative := true;

   if (Dimensionsf.w <> newW) or (Dimensionsf.h <> newH) or (Positionf.x <> newX) or (Positionf.y <> newY) then begin
      Dimensionsf.w := newW;
      Dimensionsf.h := newH;

      Positionf.x := newX;
      Positionf.y := newY;

      a.Calculate(Dimensionsf.w, Dimensionsf.h);
   end;
end;

procedure oxTViewportHelper.SetOffset(offsetX, offsetY: longint);
begin
   Offset.x := offsetX;
   Offset.y := offsetY;
end;

procedure oxTViewportHelper.SetOffset(const p: oxTPoint);
begin
  SetOffset(p.x, p.y);
end;

procedure oxTViewportHelper.Viewport();
begin
   if(Enabled) then begin
      if(not Relative) then
         oxRenderer.Viewport(Offset.x + Position.x, Offset.y + Position.y, Dimensions.w, Dimensions.h)
      else
         oxRenderer.Viewport(Offset.x + round(Dimensions.w * Positionf.x), Offset.y + round(Dimensions.h * Positionf.y),
            round(Dimensions.w * Dimensionsf.w), round(Dimensions.h  * Dimensionsf.h));
   end;
end;

procedure oxTViewportHelper.Clear();
begin
   oxRenderer.ClearColor(ClearColor);

   if(Enabled) then begin
      if(ScissorOnClear) then
         oxRender.Scissor(Offset.x + Position.x, Offset.y + Position.y + Dimensions.h - 1, Dimensions.w, Dimensions.h);

      oxRenderer.Clear(ClearBits);

      if(ScissorOnClear) then
         oxRender.DisableScissor();
   end;
end;

procedure oxTViewportHelper.SetViewport(const pt: oxTPoint; const d: oxTDimensions);
begin
   SetViewport(pt.x, pt.y - d.h + 1, d.w, d.h);
end;

procedure oxTViewportHelper.From(const source: oxTViewport);
begin
  Self := source;
end;

procedure oxTViewportHelper.SetFromWindow(wnd: oxTWindow);
begin
   SetViewport(0, 0, wnd.Dimensions.w, wnd.Dimensions.h);
end;

procedure oxTViewportHelper.GetNormalizedPointerCoordinates(x, y: single; out n: TVector2f);
begin
   n[0] := (2 * x) / Dimensions.w - 1;
   n[1] := (2 * y) / Dimensions.h - 1;
end;

procedure oxTViewportHelper.GetNormalizedPointerCoordinates(x, y, z: single; out n: TVector4f);
begin
   n[0] := (2 * x / Dimensions.w) - 1;
   n[1] := (2 * y / Dimensions.h) - 1;
   n[2] := z * 2 - 1;
   n[3] := 1;
end;

END.
