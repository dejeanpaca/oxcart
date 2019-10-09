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
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase,
      uiuWindow, uiuDrawUtilities;


TYPE
   { wdgTDivisor }

   wdgTDivisor = class(uiTWidget)
      DoOverrideColor,
      NoAutomaticSizing: boolean;

      OverrideColor: TColor4ub;

      constructor Create(); override;
      procedure Render(); override;

      procedure CorrectPosition();
      procedure GetComputedDimensions(out d: oxTDimensions); override;

      procedure SetOverrideColor(newColor: TColor4ub);

      procedure ParentSizeChange(); override;
   end;

   { wdgTDivisorGlobal }

   wdgTDivisorGlobal = class(specialize wdgTBase<wdgTDivisor>)
      Internal: uiTWidgetClass; static;
      DefaultColor: TColor4ub; static;

      function Add(const Caption: StdString;
                 const Pos: oxTPoint; Vertical: boolean = false): wdgTDivisor;
      function Add(const Caption: StdString): wdgTDivisor;
   end;

VAR
   wdgDivisor: wdgTDivisorGlobal;

IMPLEMENTATION

procedure InitWidget();
begin
   wdgDivisor.Internal.NonSelectable := true;
   wdgDivisor.Internal.Done(wdgTDivisor);

   wdgDivisor := wdgTDivisorGlobal.Create(wdgDivisor.Internal);
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
   if(DoOverrideColor) then
      cSurface := OverrideColor;

   if(not (wdgpTRUE in Properties)) then begin
      x := RPosition.x + PaddingLeft;
      y := RPosition.y - Dimensions.h div 2;
      x2 := x + Dimensions.w - (PaddingRight + PaddingLeft + 1);

      if(Caption = '') then begin
         uiDrawUtilities.HorizontalDivisorSunken(wnd, x, y, x2, cSurface);
      end else begin
         SetColorBlendedEnabled(uiTSkin(uiTWindow(wnd).Skin).Colors.Text,
            uiTSkin(uiTWindow(wnd).Skin).DisabledColors.Text);

         CachedFont.Start();
         CachedFont.Write(x + 5 + CachedFont.GetWidth(), y - CachedFont.GetHeight() div 2, Caption);
         oxf.Stop();

         w := CachedFont.GetLength(Caption);

         uiDrawUtilities.HorizontalDivisorSunken(wnd, x, y, x + 5, cSurface);
         uiDrawUtilities.HorizontalDivisorSunken(wnd, x + 10 + CachedFont.GetWidth() + w, y, x2, cSurface);
      end;
   end else begin
      x := RPosition.x + (Dimensions.w div 2);
      y := RPosition.y - PaddingTop;
      y2 := y - Dimensions.h + (PaddingTop + PaddingBottom + 1);

      if(Caption = '') then begin
         uiDrawUtilities.VerticalDivisorSunken(wnd, x, y, y2, cSurface);
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

procedure wdgTDivisor.SetOverrideColor(newColor: TColor4ub);
begin
   OverrideColor := newColor;
   DoOverrideColor := true;
end;

procedure wdgTDivisor.ParentSizeChange();
begin
   if(not NoAutomaticSizing) then
      Resize(GetComputedDimensionsf());
end;

function wdgTDivisorGlobal.Add(const Caption: StdString;
            const Pos: oxTPoint; Vertical: boolean): wdgTDivisor;
var
   lastRectX: loopint;

begin
   lastRectX := uiWidget.LastRect.r.x;
   Result := inherited AddInternal(Pos);

   if(Result <> nil) then begin
      Result.SetCaption(Caption);

      if(Vertical) then
         Include(Result.Properties, wdgpTRUE);

      Result.CorrectPosition();
      AddDone(Result);

      uiWidget.LastRect.r.x := lastRectX;
   end;
end;

function wdgTDivisorGlobal.Add(const Caption: StdString): wdgTDivisor;
begin
   Result := Add(Caption, uiWidget.LastRect.BelowOf());
end;

INITIALIZATION
   wdgDivisor.internal.Register('widget.link', @InitWidget);

END.
