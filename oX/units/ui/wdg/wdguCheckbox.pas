{
   wdguCheckbox, check-box widget for the dUI
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguCheckbox;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuRender, oxuGlyph,
      {ui}
      uiuDraw, uiuWindowTypes, uiuSkinTypes, uiuDrawUtilities,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuWidgetRender, wdguBase;

CONST
   wdgcCHECKBOX_TOGGLE = $0001;

   {regular surface color}
   wdgscCHECKBOX_REGULAR = 0;
   {disabled surface color}
   wdgscCHECKBOX_REGULAR_DISABLED = 1;
   {checked surface color}
   wdgscCHECKBOX_CHECKED = 2;
   {check mark color}
   wdgscCHECKBOX_CHECK_MARK = 3;
   {disabled check mark color}
   wdgscCHECKBOX_CHECK_MARK_DISABLED = 4;

   wdgsgCHECKBOX_CHECK_MARK = 0;

   wdgsdCheckboxColor: array[0..4] of uiTWidgetSkinColorDescriptor = (
       (
          Name: 'regular';
          Color: (255, 255, 255, 255)
       ),
       (
          Name: 'regular_disabled';
          Color: (48, 48, 48, 255)
       ),
       (
          Name: 'checked';
          Color: (48, 192, 48, 255)
       ),
       (
          Name: 'check_mark';
          Color: (255, 255, 255, 255)
       ),
       (
          Name: 'check_mark_disabled';
          Color: (96, 96, 96, 255)
       )
    );

   wdgsdCheckboxGlyph: array[0..0] of uiTWidgetSkinGlyphDescriptor = (
      (
         Name: 'check_mark';
         Default: 'default:$f00c'
      )
   );

TYPE
   { wdgTCheckbox }

   wdgTCheckbox = class(uiTWidget)
   public
      {width and height of the box}
      Width,
      Height,
      Spacing: longint;

      constructor Create(); override;

      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      procedure Render(); override;
      class procedure RenderCheckbox(source: uiTWidget; checked, enabled, selected: boolean; const r: oxTRect); static;
      function Key(var k: appTKeyEvent): boolean; override;

      {see if a check-box is checked}
      function Checked(): boolean;
      {set the check-box state}
      function Check(isChecked: boolean): wdgTCheckbox;

      procedure GetComputedDimensions(out d: oxTDimensions); override;

      procedure Toggle();

      protected
         procedure SetSpacing();
         procedure SizeChanged(); override;
         procedure FontChanged(); override;
   end;

   { wdgTCheckboxGlobal }

   wdgTCheckboxGlobal = object(specialize wdgTBase<wdgTCheckbox>)
      Width,
      Height: longint; static;
      LineWidth: single; static;

      DisabledColor,
      CheckedColor: TColor4ub; static;

      function Add(const Caption: StdString;
                  const Pos: oxTPoint;
                  value: boolean = false): wdgTCheckbox;
      function Add(const Caption: StdString): wdgTCheckbox;
      function Add(const Caption: StdString; value: boolean): wdgTCheckbox;
   end;

VAR
   wdgCheckbox: wdgTCheckboxGlobal;

IMPLEMENTATION

constructor wdgTCheckbox.Create();
begin
   inherited;

   Width := wdgCheckbox.Width;
   Height := wdgCheckbox.Height;
end;

procedure wdgTCheckbox.Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint);
begin
   if(e.Action and appmcRELEASED > 0) and (e.Button and appmcLEFT > 0) then
      Toggle();
end;

procedure wdgTCheckbox.Render();
var
   x1,
   y1,
   x2: longint;

   r: oxTRect;
   f: oxTfont;

   pwnd: uiTWindow;

begin
   pwnd := uiTWindow(wnd);

   r.Assign(RPosition.x, RPosition.y, Width, Height);
   RenderCheckbox(self, Checked(), wdgpENABLED in Properties, IsSelected() or Hovering(), r);

   x1 := RPosition.x;
   y1 := RPosition.y;
   x2 := x1 + Width - 1;

   {render the check-box text}
   if(Caption <> '') then begin
      f := CachedFont;

      if(f <> nil) then begin
         r.w := Width + Spacing + f.GetLength(Caption);
         r.h := Dimensions.h;
         r.x := x2 + Spacing;
         r.y := y1;

         f.Start();

         if(wdgpENABLED in Properties) then
            SetColorBlended(uiTSkin(pwnd.Skin).Colors.Text)
         else
            SetColorBlended(uiTSkin(pwnd.Skin).Colors.InactiveText);

         f.WriteCentered(Caption, r, [oxfpCenterLeft, oxfpCenterVertical]);
         oxf.Stop();
      end;
   end;
end;

class procedure wdgTCheckbox.RenderCheckbox(source: uiTWidget; checked, enabled, selected: boolean; const r: oxTRect);
var
   x1,
   y1,
   x2,
   y2,
   diff: longint;

   br: oxTRect;

   renderProperties: longword;
   pwnd: uiTWindow;
   pSkin: uiPWidgetSkin;
   glyph: oxPGlyph;

   clr: TColor4ub;

procedure RenderBlock(borderOnly: boolean);
var
   props: longword;

begin
   if(not borderOnly) then
      props := renderProperties
   else
      props := wdgRENDER_BLOCK_BORDER;

   props := renderProperties;

   if(enabled) then begin
      if(not selected) then
         clr := uiTSkin(pwnd.Skin).Colors.Border
      else
         clr := uiTSkin(pwnd.Skin).Colors.SelectedBorder;

      if(not checked) then
         uiRenderWidget.Box(x1, y2, x2, y1, pSkin^.GetColor(wdgscCHECKBOX_REGULAR), clr, props, pwnd.Opacity)
      else
         uiRenderWidget.Box(x1, y2, x2, y1, pSkin^.GetColor(wdgscCHECKBOX_CHECKED), clr, props, pwnd.Opacity);
   end else begin
      uiRenderWidget.Box(x1, y2, x2, y1, pSkin^.GetColor(wdgscCHECKBOX_REGULAR_DISABLED), uiTSkin(pwnd.Skin).DisabledColors.Border, props, pwnd.Opacity)
   end;
end;

begin
   pwnd := uiTWindow(source.wnd);
   pSkin := source.GetSkinObject().Get(wdgCheckbox.Internal.cID);

   glyph := pSkin^.GetGlyph(wdgsgCHECKBOX_CHECK_MARK);

   {render check-box block}
   renderProperties := wdgRENDER_BLOCK_SURFACE or wdgRENDER_BLOCK_BORDER;

   x1 := r.x;
   y1 := r.y;
   x2 := x1 + r.w - 1;
   y2 := y1 - r.h + 1;

   RenderBlock(false);

   {render check if the checkbox is marked}
   if(checked) then begin
      if(enabled) then
         clr := pSkin^.GetColor(wdgscCHECKBOX_CHECK_MARK)
      else
         clr := pSkin^.GetColor(wdgscCHECKBOX_CHECK_MARK_DISABLED);

      {draw a checkmark}
      source.SetColor(clr);

      if(glyph <> nil) then begin
         diff := round(r.w * 0.35);
         br := r;

         br.w := br.w - diff;
         br.x := br.x + diff div 2;

         br.h := br.h - diff;
         br.y := br.y - diff div 2;

         uiDrawUtilities.Glyph(br, glyph^);
         uiDraw.ClearTexture();
      end else begin
         oxRender.LineWidth(wdgCheckbox.LineWidth);

         uiDraw.Line(x1 + 3, y2 + 7, x1 + 7, y2 + 3);
         uiDraw.Line(x1 + 7, y2 + 3, x2 - 3, y1 - 2);

         oxRender.LineWidth(1.0);
      end;
   end;
end;

function wdgTCheckbox.Key(var k: appTKeyEvent): boolean;
begin
   Result := false;

   if(k.Key.Equal(kcSPACE)) then begin
      if(k.Key.Released()) then
         Toggle();

      Result := false;
   end;
end;

function wdgTCheckbox.Checked(): boolean;
begin
   Result := wdgpTRUE in Properties;
end;

function wdgTCheckbox.Check(isChecked: boolean): wdgTCheckbox;
begin
   if(isChecked) then
      Include(Properties, wdgpTRUE)
   else
      Exclude(Properties, wdgpTRUE);

   Result := Self;
end;

procedure wdgTCheckbox.GetComputedDimensions(out d: oxTDimensions);
begin
   SetSpacing();

   if(Caption <> '') then
      d.w := Width + Spacing + CachedFont.GetLength(Caption)
   else
      d.w := Width;

   d.h := Height;
end;

procedure wdgTCheckbox.Toggle();
begin
   if(wdgpENABLED in Properties) then begin
      if(wdgpTRUE in Properties) then
         Exclude(Properties, wdgpTRUE)
      else
         Include(Properties, wdgpTRUE);

      Control(wdgcCHECKBOX_TOGGLE);
   end;
end;

procedure wdgTCheckbox.SetSpacing();
begin
   Spacing := Width div 2;
end;

procedure wdgTCheckbox.SizeChanged();
begin
   inherited SizeChanged;

   if(Dimensions.w < Width) then
      Width := Dimensions.w;

   if(Dimensions.h < Height) then
      Height := Dimensions.h;
end;

procedure wdgTCheckbox.FontChanged();
begin
   inherited FontChanged;

   SetSpacing();
end;

function wdgTCheckboxGlobal.Add(const Caption: StdString;
         const Pos: oxTPoint;
         value: boolean = false): wdgTCheckbox;
begin
   Result := inherited AddInternal(Pos, oxNullDimensions);

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      Result.Check(value);

      AddDone(Result);
   end;
end;

function wdgTCheckboxGlobal.Add(const Caption: StdString): wdgTCheckbox;
begin
   Result := Add(Caption, uiWidget.LastRect.BelowOf());
end;

function wdgTCheckboxGlobal.Add(const Caption: StdString; value: boolean): wdgTCheckbox;
begin
   Result := Add(Caption).Check(value);
end;

INITIALIZATION
   wdgCheckbox.Width := 18;
   wdgCheckbox.Height := 18;
   wdgCheckbox.LineWidth := 2.0;

   wdgCheckbox.Create('checkbox');

   wdgCheckbox.Internal.SkinDescriptor.UseColors(wdgsdCheckboxColor);
   wdgCheckbox.Internal.SkinDescriptor.UseGlyphs(wdgsdCheckboxGlyph);

END.
