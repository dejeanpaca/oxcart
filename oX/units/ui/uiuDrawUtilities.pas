{
   uiuDrawUtilities, UI drawing utilities
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuDrawUtilities;

INTERFACE

   USES
      uStd, uColors,
      {ox}
      oxuTypes, oxuTexture, oxuRenderUtilities, oxuGlyph,
      {ui}
      uiuControl, uiuWindow, uiuWindowTypes,
      uiuDraw;

TYPE
   { uiTDrawUtilities }

   uiTDrawUtilities = record
      class procedure VerticalDivisor(wnd: uiTWindow; x1, y1, y2: loopint; color: TColor4ub); static;
      class procedure HorizontalDivisor(wnd: uiTWindow; x1, y1, x2: loopint; color: TColor4ub); static;
      class procedure VerticalDivisorSunken(wnd: uiTWindow; x1, y1, y2: loopint; color: TColor4ub); static;
      class procedure HorizontalDivisorSunken(wnd: uiTWindow; x1, y1, x2: loopint; color: TColor4ub); static;
      class procedure VerticalDivisor(wnd: uiTControl; x1, y1, y2: loopint; color: TColor4ub); static; inline;
      class procedure HorizontalDivisor(wnd: uiTControl; x1, y1, x2: loopint; color: TColor4ub); static; inline;
      class procedure VerticalDivisorSunken(wnd: uiTControl; x1, y1, y2: loopint; color: TColor4ub); static; inline;
      class procedure HorizontalDivisorSunken(wnd: uiTControl; x1, y1, x2: loopint; color: TColor4ub); static; inline;

      class procedure Glyph(x, y, w, h: single; tex: oxTTexture); static;
      class procedure Glyph(const r: oxTRect; tex: oxTTexture); static;
      class procedure Glyph(const r: oxTRect; const g: oxTGlyph); static;
   end;

VAR
   uiDrawUtilities: uiTDrawUtilities;

IMPLEMENTATION

{ uiTDrawUtilities }

class procedure uiTDrawUtilities.VerticalDivisor(wnd: uiTWindow; x1, y1, y2: loopint; color: TColor4ub);
begin
  wnd.SetColor(color.Darken(0.4));
  uiDraw.VLine(x1 + 1, y1, y2);

  wnd.SetColor(color.Lighten(1.4));
  uiDraw.VLine(x1, y1, y2);
end;

class procedure uiTDrawUtilities.HorizontalDivisor(wnd: uiTWindow; x1, y1, x2: loopint; color: TColor4ub);
begin
  wnd.SetColor(color.Lighten(1.4));
  uiDraw.HLine(x1, y1, x2);

  wnd.SetColor(color.Darken(0.4));
  uiDraw.HLine(x1, y1 - 1, x2);
end;

class procedure uiTDrawUtilities.VerticalDivisorSunken(wnd: uiTWindow; x1, y1, y2: loopint; color: TColor4ub);
begin
   wnd.SetColor(color.Lighten(1.4));
   uiDraw.VLine(x1 + 1, y1, y2);

   wnd.SetColor(color.Darken(0.4));
   uiDraw.VLine(x1, y1, y2);
end;

class procedure uiTDrawUtilities.HorizontalDivisorSunken(wnd: uiTWindow; x1, y1, x2: loopint; color: TColor4ub);
begin
   wnd.SetColor(color.Darken(0.4));
   uiDraw.HLine(x1, y1, x2);

   wnd.SetColor(color.Lighten(1.4));
   uiDraw.HLine(x1, y1 - 1, x2);
end;

class procedure uiTDrawUtilities.VerticalDivisor(wnd: uiTControl; x1, y1, y2: loopint; color: TColor4ub);
begin
   VerticalDivisor(uiTWindow(wnd), x1, y1, y2, color);
end;

class procedure uiTDrawUtilities.HorizontalDivisor(wnd: uiTControl; x1, y1, x2: loopint; color: TColor4ub);
begin
   HorizontalDivisor(uiTWindow(wnd), x1, y1, x2, color);
end;

class procedure uiTDrawUtilities.VerticalDivisorSunken(wnd: uiTControl; x1, y1, y2: loopint; color: TColor4ub);
begin
   VerticalDivisorSunken(uiTWindow(wnd), x1, y1, y2, color);
end;

class procedure uiTDrawUtilities.HorizontalDivisorSunken(wnd: uiTControl; x1, y1, x2: loopint; color: TColor4ub);
begin
   HorizontalDivisorSunken(uiTWindow(wnd), x1, y1, x2, color);
end;

class procedure uiTDrawUtilities.Glyph(x, y, w, h: single; tex: oxTTexture);
begin
   oxRenderUtilities.TexturedQuad(x + (w / 2), y - (h / 2), w / 2, h / 2, tex);
end;

class procedure uiTDrawUtilities.Glyph(const r: oxTRect; tex: oxTTexture);
begin
   Glyph(r.x, r.y, r.w, r.h, tex);
end;

class procedure uiTDrawUtilities.Glyph(const r: oxTRect; const g: oxTGlyph);
var
   pr: oxTRect;
   factorx,
   factory: single;
   bearingx,
   bearingy: loopint;

begin
   if(g.Texture = nil) then
      exit;

   pr := r;
   bearingx := 0;
   bearingy := 0;


   factorx := (1 / g.Texture.Width * r.w);
   factory := (1 / g.Texture.Height * r.h);

   if(g.BearingX <> 0) then begin
      bearingx := round(factorx * g.BearingX);
      inc(pr.x, bearingx);
   end;

   if(g.BearingY <> 0) then begin
      bearingy := round(factory * (g.Height - g.BearingY + 1));
      if(bearingy <> 0) then
         dec(pr.y, bearingy div 2);
   end;

   if(g.Texture.Height <> g.Height) then begin
      bearingy := round(factory * (g.Texture.Height - g.Height) / 2);
      dec(pr.y, bearingy div 2);
   end;

   oxRenderUtilities.TexturedQuad(pr.x + (pr.w / 2), pr.y - (pr.h / 2), pr.w / 2, pr.h / 2, g.Texture);
end;

END.
