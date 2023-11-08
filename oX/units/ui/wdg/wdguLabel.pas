{
   wdguLabel, label widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguLabel;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuWindow, uiuDraw;

TYPE

   { wdgTLabel }

   wdgTLabel = class(uiTWidget)
      InRectangle: boolean;
      List: TStringArray;
      Transparent,
      IsMultiline,
      IsCentered: boolean;
      FontProperties: oxTFontPropertiesSet;

      constructor Create(); override;
      procedure Initialize(); override;

      procedure Render(clr: TColor4ub);
      procedure Render(); override;

      procedure GetComputedDimensions(out d: oxTDimensions); override;
      procedure Multiline();
   end;

   { wdgTLabelGlobal }

   wdgTLabelGlobal = record
      function Add(const Caption: string;
                 const Pos: oxTPoint; const Dim: oxTDimensions;
                 inrect: boolean = false): wdgTLabel;

      function Add(const Caption: string;
                 inrect: boolean = false): wdgTLabel;

      function Add(const List: TStringArray;
                 const Pos: oxTPoint; const Dim: oxTDimensions;
                 inrect: boolean = false): wdgTLabel;
   end;

VAR
   wdgLabel: wdgTLabelGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

constructor wdgTLabel.Create();
begin
   inherited;

   SetPadding(2);
   Transparent := true;
   FontProperties := oxfpCenterHV + oxfpInRectDefaultProperties;
end;

procedure wdgTLabel.Initialize();
begin
   inherited Initialize();

   Color := uiTSkin(uiTWindow(wnd).Skin).Colors.Text;
end;

procedure wdgTLabel.Render(clr: TColor4ub);
var
   r: oxTRect;
   f: oxTFont;
   i,
   h,
   y: loopint;
   current,
   copiedCaption: string;
   rprops: oxTFontPropertiesSet;

begin
   f := CachedFont;

   uiDraw.Scissor(RPosition, Dimensions);

   if((Caption <> '') or (Length(List) > 0)) and (f <> nil) then begin
      f.Start();

      SetColorBlended(clr);

      if(not InRectangle) then begin
         h := f.GetHeight();

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
end;

procedure wdgTLabel.Multiline();
begin
   IsMultiline := true;

   AutoSize();
end;

procedure InitWidget();
begin
   internal.NonSelectable := true;
   internal.Instance := wdgTLabel;
   internal.Done();
end;

function wdgTLabelGlobal.Add(const Caption: string;
            const Pos: oxTPoint; const Dim: oxTDimensions;
            inrect: boolean = false): wdgTLabel;
begin
   result := wdgTLabel(uiWidget.Add(internal, Pos, Dim));

   if(result <> nil) then begin
      result.InRectangle := inrect;
      result.SetCaption(Caption);

      result.AutoSize();
   end;
end;

function wdgTLabelGlobal.Add(const Caption: string; inrect: boolean): wdgTLabel;
begin
   result := Add(Caption, uiWidget.LastRect.BelowOf(), oxNullDimensions, inrect);
end;

function wdgTLabelGlobal.Add(const List: TStringArray;
            const Pos: oxTPoint; const Dim: oxTDimensions;
            inrect: boolean = false): wdgTLabel;
begin
   result := wdgTLabel(uiWidget.Add(internal, Pos, Dim));

   if(result <> nil) then begin
      result.InRectangle := inrect;
      result.List := List;

      result.AutoSize();
   end;
end;

INITIALIZATION
   internal.Register('widget.label', @InitWidget);
END.
