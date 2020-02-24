{
   uiuDrawUtilities, UI drawing utilities
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuDrawUtilities;

INTERFACE

   USES
      uStd, uColors,
      oxuTexture, oxuRenderUtilities,
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
   oxRenderingUtilities.TexturedQuad(x + (w / 2), y - (h / 2), w / 2, h / 2, tex);
end;

END.
