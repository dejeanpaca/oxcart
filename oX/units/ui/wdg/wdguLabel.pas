{
   wdguLabel, label widget for the UI
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguLabel;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      vmVector,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuWindow, uiuDraw, uiuRegisteredWidgets,
      wdguBase;

TYPE

   { wdgTLabel }

   wdgTLabel = class(uiTWidget)
      InRectangle: boolean;
      List: TStringArray;
      Transparent,
      IsMultiline,
      IsCentered: boolean;
      FontProperties: oxTFontPropertiesSet;

      Scale: TVector2f;

      constructor Create(); override;
      procedure Initialize(); override;

      procedure Render(clr: TColor4ub);
      procedure Render(); override;

      procedure GetComputedDimensions(out d: oxTDimensions); override;
      procedure Multiline();
      procedure MultilineConditional();

      {set a scale}
      procedure SetScale(x, y: single);

      protected
         FontHeight: loopint;
         procedure FontChanged(); override;
   end;

   { wdgTLabelGlobal }

   wdgTLabelGlobal = object(specialize wdgTBase<wdgTLabel>)
      function Add(const Caption: StdString;
                 const Pos: oxTPoint; const Dim: oxTDimensions;
                 inrect: boolean = false): wdgTLabel;

      function Add(const Caption: StdString;
                 inrect: boolean = false): wdgTLabel;

      function Add(const List: TStringArray;
                 const Pos: oxTPoint; const Dim: oxTDimensions;
                 inrect: boolean = false): wdgTLabel;
   end;

VAR
   wdgLabel: wdgTLabelGlobal;

IMPLEMENTATION

constructor wdgTLabel.Create();
begin
   inherited;

   SetPadding(2);
   Transparent := true;
   FontProperties := oxfpCenterHV + oxfpInRectDefaultProperties;
   Scale := vmvOne2f;
end;

procedure wdgTLabel.Initialize();
begin
   inherited Initialize();

   Color := uiTSkin(uiTWindow(wnd).Skin).Colors.Text;
   FontChanged();
end;

procedure wdgTLabel.Render(clr: TColor4ub);
var
   r: oxTRect;
   f: oxTFont;
   i,
   h,
   y: loopint;
   current,
   copiedCaption: StdString;
   rprops: oxTFontPropertiesSet;

begin
   f := CachedFont;

   uiDraw.Scissor(RPosition, Dimensions);

   if((Caption <> '') or (Length(List) > 0)) and (f <> nil) then begin
      f.Start();

      if(Scale <> vmvOne2f) then
         f.Scale(Scale[0], Scale[1]);

      SetColorBlended(clr);

      if(not InRectangle) then begin
         h := FontHeight;

         {render caption the regular way}
         if(Caption <> '') then begin
            if(not IsMultiline) then
               f.Write(RPosition.x + PaddingLeft, RPosition.y - PaddingTop - h, Caption)
            else begin
               copiedCaption := Caption;

               y := RPosition.y - PaddingTop - h;

               repeat
                 current := CopyToDel(copiedCaption, #13);

                  f.Write(RPosition.x + PaddingLeft, y, current);
                  dec(y, h);
               until (copiedCaption = '') or (y <= BelowOf());
            end;
         end else if(Length(List) > 0) then begin
            for i := 0 to high(List) do
               f.Write(RPosition.x + PaddingLeft, RPosition.y - PaddingTop - (h * (i + 1)), List[i]);
         end
      end else begin
         {create a output rectangle}
         r.x := RPosition.x;
         r.y := RPosition.y;
         r.w := Dimensions.w;
         r.h := Dimensions.h;

         {write caption in rectangle}
         if(Caption <> '') then begin
            if(not IsCentered) then begin
               rprops := FontProperties;

               if(IsMultiline) then
                  Include(rprops, oxfpMultiline)
               else
                  Exclude(rprops, oxfpMultiline);

               f.WriteInRect(Caption, r, rprops);
            end else
              f.WriteCentered(Caption, r, FontProperties)
         end;
      end;

      if(Scale <> vmvOne2f) then
         f.Scale(1.0, 1.0);

      oxf.Stop();
   end;

   uiDraw.DoneScissor();
end;

procedure wdgTLabel.Render();
begin
   if(not Transparent) then begin
      SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Surface);
      uiDraw.Box(RPosition, Dimensions);
   end;

   Render(Color);
end;

procedure wdgTLabel.GetComputedDimensions(out d: oxTDimensions);
var
   i,
   w: loopint;
   count: loopint = 1;

begin
   d.w := CachedFont.GetLength(Caption) + (PaddingLeft + PaddingRight);

   count := Length(List);
   if(count > 0) then begin
      for i := 0 to (count - 1) do begin
         w := CachedFont.GetLength(List[i]) + (PaddingLeft + PaddingRight);

         if(d.w < w) then
            d.w := w;
      end;
   end else
      count := 1;

   if(IsMultiline) then
      count := 1 + StringCount(Caption, LineEnding);

   d.h := (CachedFont.GetHeight() + (PaddingTop + PaddingBottom)) * count;

   d.w := GetScaled(d.w, Scale[0]);
   d.h := GetScaled(d.h, Scale[1]);
end;

procedure wdgTLabel.Multiline();
begin
   IsMultiline := true;

   AutoSize();
end;

procedure wdgTLabel.MultilineConditional();
begin
   if Caption.IsMultiLine() then
      Multiline();
end;

procedure wdgTLabel.SetScale(x, y: single);
begin
   Scale[0] := x;
   Scale[1] := y;

   FontChanged();
end;

procedure wdgTLabel.FontChanged();
begin
   inherited FontChanged();
   FontHeight := GetScaled(CachedFont.GetHeight(), Scale[1]);
end;

function wdgTLabelGlobal.Add(const Caption: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions;
            inrect: boolean = false): wdgTLabel;
begin
   Result := inherited AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.InRectangle := inrect;
      Result.SetCaption(Caption);

      AddDone(Result);
   end;
end;

function wdgTLabelGlobal.Add(const Caption: StdString; inrect: boolean): wdgTLabel;
begin
   Result := Add(Caption, uiWidget.LastRect.BelowOf(), oxNullDimensions, inrect);
end;

function wdgTLabelGlobal.Add(const List: TStringArray;
            const Pos: oxTPoint; const Dim: oxTDimensions;
            inrect: boolean = false): wdgTLabel;
begin
   Result := inherited AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.InRectangle := inrect;
      Result.List := List;

      AddDone(Result);
   end;
end;

INITIALIZATION
   wdgLabel.Create('label');
   wdgLabel.Internal.NonSelectable := true;

END.
