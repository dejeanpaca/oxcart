{
   wdguDivisor, divisor widget
   Copyright (C) 2017. Dejan Boras

   Started On:    09.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguDivisor;

INTERFACE

   USES
      uStd, uColors, sysutils,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuDraw, uiuWindow;


TYPE

   { wdgTLink }

   { wdgTDivisor }

   wdgTDivisor = class(uiTWidget)
      NoAutomaticSizing: boolean;

      constructor Create(); override;
      procedure Render(); override;

      procedure CorrectPosition();
      procedure GetComputedDimensions(out d: oxTDimensions); override;

      procedure ParentSizeChange(); override;
   end;

   { wdgTLinkGlobal }

   wdgTDivisorGlobal = record
      DefaultColor: TColor4ub;

      function Add(const Caption: string;
                 const Pos: oxTPoint; Vertical: boolean = false): wdgTDivisor;
   end;

VAR
   wdgDivisor: wdgTDivisorGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure InitWidget();
begin
   internal.Instance := wdgTDivisor;
   internal.NonSelectable := true;
   internal.Done();
end;

{ wdgTDivisor }

constructor wdgTDivisor.Create();
begin
   inherited Create;

   Exclude(Properties, wdgpSELECTABLE);
   SetPadding(3);
end;

procedure wdgTDivisor.Render();
var
   x, y, x2, y2, w: loopint;
   cSurface: TColor4ub;

begin
   cSurface := Parent.GetSurfaceColor();

   if(not (wdgpTRUE in Properties)) then begin
      x := RPosition.x + PaddingLeft;
      y := RPosition.y - Dimensions.h div 2;
      x2 := x + Dimensions.w - (PaddingRight + PaddingLeft + 1);

      if(Caption = '') then begin
         SetColor(cSurface.Lighten(1.3));
         uiDraw.HLine(x, y, x2);

         SetColor(cSurface.Darken(0.8));
         uiDraw.HLine(x, y - 1, x2);
      end else begin
         SetColorBlendedEnabled(uiTSkin(uiTWindow(wnd).Skin).Colors.Text,
            uiTSkin(uiTWindow(wnd).Skin).DisabledColors.Text);

         CachedFont.Start();
         CachedFont.Write(x + 5 + CachedFont.GetWidth(), y - CachedFont.GetHeight() div 2, Caption);
         oxf.Stop();

         w := CachedFont.GetLength(Caption);

         SetColor(cSurface.Lighten(1.3));
         uiDraw.HLine(x, y, x + 5);
         uiDraw.HLine(x + 5 + CachedFont.GetWidth() * 2 + w, y, x2);

         SetColor(cSurface.Darken(0.8));
         uiDraw.HLine(x, y - 1, x + 5);
         uiDraw.HLine(x + 5 + CachedFont.GetWidth() * 2 + w, y - 1, x2);
      end;
   end else begin
      x := RPosition.x + (Dimensions.w div 2);
      y := RPosition.y - PaddingTop;
      y2 := y - Dimensions.h + (PaddingTop + PaddingBottom + 1);

      if(Caption = '') then begin
         SetColor(cSurface.Lighten(1.3));
         uiDraw.VLine(x + 1, y, y2);

         SetColor(cSurface.Darken(0.8));
         uiDraw.VLine(x, y, y2);
      end;
   end;
end;

procedure wdgTDivisor.CorrectPosition();
var
   p: oxTPoint;

begin
   p := Position;

   if(not (wdgpTRUE in Properties)) and (p.x > 0) then
     p.x := 0;

   if(wdgpTRUE in Properties) and (p.y > 0) then
     p.y := 0;

   Move(p);
end;

procedure wdgTDivisor.GetComputedDimensions(out d: oxTDimensions);
var
   f: oxTFont;

begin
   f := CachedFont;

   if(not (wdgpTRUE in Properties)) then begin
      SetHorizontalPadding(7);
      SetVerticalPadding(3);

      {horizontal}
      d.w := Parent.Dimensions.w;
      d.h := PaddingTop + PaddingBottom;

      if(Caption <> '') then
         d.h := d.h + f.GetHeight();
   end else begin
      SetHorizontalPadding(3);
      SetVerticalPadding(7);

      {vertical}
      d.w := PaddingLeft + PaddingRight;
      d.h := Parent.Dimensions.h;

      if(Caption <> '') then
        d.w := d.w + f.GetHeight();
   end;
end;

procedure wdgTDivisor.ParentSizeChange();
begin
   if(not NoAutomaticSizing) then
      Resize(GetComputedDimensionsf());
end;

function wdgTDivisorGlobal.Add(const Caption: string;
            const Pos: oxTPoint; Vertical: boolean): wdgTDivisor;
var
   lastRectX: loopint;

begin
   lastRectX := uiWidget.LastRect.r.x;
   Result := wdgTDivisor(uiWidget.Add(internal, Pos, oxNullDimensions));

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      if(Vertical) then
         Include(Result.Properties, wdgpTRUE);

      Result.CorrectPosition();
      Result.AutoSize();
      uiWidget.LastRect.r.x := lastRectX;
   end;
end;

INITIALIZATION
   internal.Register('widget.link', @InitWidget);
END.
