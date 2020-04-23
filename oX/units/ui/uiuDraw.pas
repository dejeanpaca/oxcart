{
   uiuDraw, UI drawing component
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuDraw;

INTERFACE

   USES
      uStd, uColors, vmVector,
      {oX}
      oxuTypes, oxuRender, oxuRenderUtilities,
      oxuPrimitives, oxuTransform, oxuUI, oxuTexture, oxuWindow,
      oxuViewportType;

CONST
   uiMAX_SCISSOR_STACK = 64;

TYPE
   uiTScissorStackElement = record
      IsSet: Boolean;
      r: oxTRectf;
   end;

   { uiTDrawComponent }

   uiTDraw = record
      UseScissoring: boolean;

      ScissorStackIndex: loopint;
      ScissorStack: array[0..uiMAX_SCISSOR_STACK - 1] of uiTScissorStackElement;

      procedure Box(x1, y1, x2, y2: single);
      {draw box at the specified point and dimensions}
      procedure Box(const p: oxTPoint; const d: oxTDimensions);
      procedure Box(const r: oxTRect);

      procedure Line(x1, y1, x2, y2: single);
      procedure HLine(x1, y1, x2: single);
      procedure VLine(x1, y1, y2: single);
      procedure Rect(x1, y1, x2, y2: single);
      procedure Rect(const p: oxTPoint; const d: oxTDimensions);
      procedure Rect(const r: oxTRect);
      procedure Point(x1, y1: single);
      procedure Points(var p: array of TVector2f);

      procedure CorrectPoints(p: PVector2f; count: loopint);
      procedure CorrectPoints(p: PVector3f; count: loopint);

      {start drawing}
      procedure Start();

     {restrict drawing to specified point and dimensions}
     procedure ScissorNextLevel();
     procedure Scissor(x, y, w, h: single; incrementLevel: boolean = true);
     procedure Scissor(const p: oxTPoint; const d: oxTDimensions; incrementLevel: boolean = true);
     procedure Scissor(const r: oxTRect; incrementLevel: boolean = true);
     procedure ScissorCurrent();
     procedure DoneScissor();

     procedure Color(const clr: TColor4ub);
     procedure Color(r, g, b, a: byte);
     procedure Color(r, g, b, a: single);

     {use the specified texture}
     procedure Texture(tex: oxTTexture);
     {remove the specified texture}
     procedure ClearTexture();

     {render a quad with a texture and standard texture coorrds and vertices}
     procedure Quad(tex: oxTTexture);
   end;

VAR
   uiDraw: uiTDraw;

IMPLEMENTATION

{ uiTDrawComponent }

{DRAWING}
procedure uiTDraw.Box(x1, y1, x2, y2: single);
var
   t: single;
   v: array[0..3] of TVector2f;

begin
   if(x1 > x2) then begin
      t  := x1;
      x1 := x2;
      x2 := t;
   end;

   if(y1 > y2) then begin
      t  := y1;
      y1 := y2;
      y2 := t;
   end;

   x2 := x2 + 1;
   y2 := y2 + 1;

   v[0][0] := x1;
   v[0][1] := y1;

   v[1][0] := x2;
   v[1][1] := y1;

   v[2][0] := x2;
   v[2][1] := y2;

   v[3][0] := x1;
   v[3][1] := y2;

   oxRender.Triangles(6, v, QuadIndicesus);
end;

procedure uiTDraw.Box(const p: oxTPoint; const d: oxTDimensions);
begin
   Box(p.x, p.y - d.h + 1, p.x + d.w - 1, p.y);
end;

procedure uiTDraw.Box(const r: oxTRect);
begin
   Box(r.x, r.y - r.h + 1, r.x + r.w - 1, r.y);
end;

procedure uiTDraw.Line(x1, y1, x2, y2: single);
var
   v: array[0..1] of TVector2f;

begin
   v[0][0] := x1 + 1;
   v[0][1] := y1 + 1;

   v[1][0] := x2 + 1;
   v[1][1] := y2 + 1;

   oxRender.Lines(v);
end;

procedure uiTDraw.HLine(x1, y1, x2: single);
var
   t: single;
   v: array[0..1] of TVector2f;

begin
   if(x1 > x2) then begin
      t  := x1;
      x1 := x2;
      x2 := t;
   end;

   x2 := x2 + 0.5;
   y1 := y1 + 0.5;
   x1 := x1 + 0.5;

   v[0][0] := x1;
   v[0][1] := y1;
   v[1][0] := x2;
   v[1][1] := y1;

   oxRender.Lines(v);
end;

procedure uiTDraw.VLine(x1, y1, y2: single);
var
   t: single;
   v: array[0..1] of TVector2f;

begin
   if(y1 > y2) then begin
      t := y1;
      y1 := y2;
      y2 := t;
   end;

   x1 := x1 + 0.5;
   y1 := y1 + 0.5;
   y2 := y2 + 0.5;

   v[0][0] := x1;
   v[0][1] := y1;
   v[1][0] := x1;
   v[1][1] := y2;

   oxRender.Lines(v);
end;

procedure uiTDraw.Rect(x1, y1, x2, y2: single);
var
   t: single;
   v: array[0..3] of TVector2f;

begin
   if(x1 > x2) then begin
      t := x1;
      x1 := x2;
      x2 := t;
   end;

   if(y1 > y2) then begin
      t := y1;
      y1 := y2;
      y2 := t;
   end;

   x1 := x1 + 1.0;
   y1 := y1 + 1.0;
   x2 := x2 + 1.0;
   y2 := y2 + 1.0;

   v[0][0] := x1 - 0.5;
   v[0][1] := y1;

   v[1][0] := x2;
   v[1][1] := y1;

   v[2][0] := x2;
   v[2][1] := y2;

   v[3][0] := x1;
   v[3][1] := y2;

   oxRender.LineLoop(v);
end;

procedure uiTDraw.Rect(const p: oxTPoint; const d: oxTDimensions);
begin
   Rect(p.x, p.y, p.x + d.w - 1, p.y - d.h + 1);
end;

procedure uiTDraw.Rect(const r: oxTRect);
begin
   Rect(r.x, r.y, r.x + r.w - 1, r.y - r.h + 1);
end;

procedure uiTDraw.Point(x1, y1: single);
var
   v: array[0..0] of TVector2f;

begin
   v[0][0] := x1 + 1.0;
   v[0][1] := y1 + 1.0;

   oxRender.Points(v);
end;

procedure uiTDraw.Points(var p: array of TVector2f);
begin
   oxRender.Points(p);
end;

procedure uiTDraw.CorrectPoints(p: PVector2f; count: loopint);
var
   i: loopint;

begin
   for i := 0 to count - 1 do begin
     p[i][0] := p[i][0] + 0.5;
     p[i][1] := p[i][1] + 0.5;
   end;
end;

procedure uiTDraw.CorrectPoints(p: PVector3f; count: loopint);
var
   i: loopint;

begin
   for i := 0 to count - 1 do begin
     p[i][0] := p[i][0] + 0.5;
     p[i][1] := p[i][1] + 0.5;
   end;
end;

procedure uiTDraw.Start();
begin
   oxRender.DisableBlend();
   oxRender.DepthTest(oxTEST_FUNCTION_NONE);
   oxRender.CullFace(oxCULL_FACE_DEFAULT);
   oxRender.DisableNormals();
   oxRender.PointSize(1.0);
   oxRender.LineWidth(1.0);

   oxRender.DisableScissor();
   ScissorStackIndex := 0;

   oxTransform.Identity();
   oxTransform.Apply();

   oxui.Material.Apply();
   uiDraw.ClearTexture();
end;

procedure uiTDraw.ScissorNextLevel();
begin
   if(not UseScissoring) then
      exit;

   Inc(ScissorStackIndex);

   ScissorStack[ScissorStackIndex].IsSet := false;
end;


procedure uiTDraw.Scissor(x, y, w, h: single; incrementLevel: boolean);
var
   previousScissor: uiTScissorStackElement;
   viewport: oxPViewport;

begin
   if(not UseScissoring) then
      exit;

   if(incrementLevel) then
      ScissorNextLevel();

   viewport := @oxWindow.Current.Viewport;
   x := x + viewport^.Offset.x;
   y := y + viewport^.Offset.y;

   if(ScissorStackIndex > 0) then begin
      if(ScissorStackIndex > 1) and (incrementLevel) then begin
         previousScissor := ScissorStack[ScissorStackIndex - 1];
         ScissorStack[ScissorStackIndex] := previousScissor;

         if(x < previousScissor.r.x) then
            x := previousScissor.r.x;
         if(y > previousScissor.r.y) then
            y := previousScissor.r.y;

         if(x + w > previousScissor.r.x + previousScissor.r.w) then
            w := w - (x + w - previousScissor.r.x + previousScissor.r.w);

         if(y + h > previousScissor.r.x + previousScissor.r.w) then
            h := h - (y + h  - previousScissor.r.y + previousScissor.r.h);
      end;

      ScissorStack[ScissorStackIndex].IsSet := true;
      ScissorStack[ScissorStackIndex].r.Assign(x, y, w, h);
   end;

   if(trunc(w) > 0) and (trunc(h) > 0) then
      oxRender.Scissor(trunc(x), trunc(y), trunc(w), trunc(h));
end;

procedure uiTDraw.Scissor(const p: oxTPoint; const d: oxTDimensions; incrementLevel: boolean);
begin
   Scissor(p.x, p.y, d.w, d.h, incrementLevel);
end;

procedure uiTDraw.Scissor(const r: oxTRect; incrementLevel: boolean);
begin
   Scissor(r.x, r.y, r.w ,r.h, incrementLevel);
end;

procedure uiTDraw.ScissorCurrent();
var
   r: uiTScissorStackElement;

begin
   if(not UseScissoring) then
      exit;

   if(ScissorStackIndex > 0) then begin
      r := ScissorStack[ScissorStackIndex];

      if(r.IsSet) then begin
         if(trunc(r.r.w) > 0) and (trunc(r.r.h) > 0) then
            oxRender.Scissor(trunc(r.r.x), trunc(r.r.y), trunc(r.r.w), trunc(r.r.h));
      end else
         oxRender.DisableScissor();
   end else
      oxRender.DisableScissor();
end;

procedure uiTDraw.DoneScissor();
begin
   if(not UseScissoring) then
      exit;

   assert(ScissorStackIndex > 0, 'uiDraw.DoneScissor called on an empty stack');
   dec(ScissorStackIndex);

   ScissorCurrent();
end;

procedure uiTDraw.Color(const clr: TColor4ub);
begin
   oxui.Material.ApplyColor('color', clr);
end;

procedure uiTDraw.Color(r, g, b, a: byte);
begin
   oxui.Material.ApplyColor('color', TColor4ub.Create(r, g, b, a));
end;

procedure uiTDraw.Color(r, g, b, a: single);
begin
   oxui.Material.ApplyColor('color', r, g, b, a);
end;

procedure uiTDraw.Texture(tex: oxTTexture);
begin
   oxui.Material.ApplyTexture('texture', tex);
end;

procedure uiTDraw.ClearTexture();
begin
   oxui.Material.ApplyTexture('texture', nil);
end;

procedure uiTDraw.Quad(tex: oxTTexture);
begin
   oxRenderUtilities.Quad(tex);
end;

INITIALIZATION
   uiDraw.UseScissoring := true;

END.
