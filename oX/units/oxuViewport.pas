{
   oxuViewport, provides viewport management
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuViewport;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuTypes, oxuAspect, oxuWindowTypes, oxuViewportType,
      oxuRenderer, oxuRender, oxuRenderingContext;

TYPE

    { oxTOnViewportChangeCallbacksHelper }

    oxTOnViewportChangeCallbacksHelper = record helper for oxTOnViewportChangeCallbacks
       procedure Call(viewport: oxPViewport);
    end;

    { oxTViewportHelper }

    oxTViewportHelper = record helper for oxTViewport
       class procedure Create(out viewport: oxTViewport); static;

       procedure Initialize();
       procedure Initialize(x, y, w, h: longint);

       procedure Initialize(const source: oxTViewport);

       {apply this viewport}
       procedure Apply(doClear: boolean = true);
       {call when this viewport is done rendering}
       procedure Done();

       {set viewport properties}
       procedure SetViewport(newW, newH: longint);
       procedure SetViewport(newX, newY, newW, newH: longint);
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

       {get a viewport from a relative one}
       procedure FromRelative(const relative: oxTViewport; out v: oxTViewport);
    end;

IMPLEMENTATION

{ oxTOnViewportChangeCallbacksHelper }

procedure oxTOnViewportChangeCallbacksHelper.Call(viewport: oxPViewport);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](viewport);
   end;
end;

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

      oxRenderingContext.Viewport := @Self;
   end;
end;

procedure oxTViewportHelper.Done();
begin
   Changed := false;
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
      Changed := true;
   end;
end;

procedure oxTViewportHelper.SetOffset(offsetX, offsetY: longint);
begin
   Offset.x := offsetX;
   Offset.y := offsetY;
   Changed := true;
end;

procedure oxTViewportHelper.SetOffset(const p: oxTPoint);
begin
  SetOffset(p.x, p.y);
end;

procedure oxTViewportHelper.Viewport();
begin
   if(Enabled) then
      oxRenderer.Viewport(Offset.x + Position.x, Offset.y + Position.y, Dimensions.w, Dimensions.h)
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

procedure oxTViewportHelper.FromRelative(const relative: oxTViewport; out v: oxTViewport);
begin
    v := Self;

    v.Position.x := v.Position.x + (v.Dimensions.w * relative.Position.x);
    v.Position.y := v.Position.y + (v.Dimensions.h * relative.Position.y);

    v.Dimensions.w := v.Dimensions.w * relative.Dimensions.w;
    v.Dimensions.h := v.Dimensions.h * relative.Dimensions.h;
end;

END.
