{
   wdguCheckbox, check-box widget for the dUI
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguCheckbox;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuRender,
      {ui}
      uiuDraw, uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuWidgetRender, wdguBase;

CONST
   wdgcCHECKBOX_TOGGLE                          = $0001;

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

   wdgTCheckboxGlobal = class(specialize wdgTBase<wdgTCheckbox>)
      Internal: uiTWidgetClass; static;
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
   y2: longint;

   renderProperties: longword;
   pwnd: uiTWindow;

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
         uiRenderWidget.Box(x1, y2, x2, y1, uiTSkin(pwnd.Skin).Colors.InputSurface, uiTSkin(pwnd.Skin).Colors.Border, props, pwnd.Opacity)
      else
         uiRenderWidget.Box(x1, y2, x2, y1, uiTSkin(pwnd.Skin).Colors.InputSurface, uiTSkin(pwnd.Skin).Colors.SelectedBorder, props, pwnd.Opacity);
   end else
      uiRenderWidget.Box(x1, y2, x2, y1, uiTSkin(pwnd.Skin).Colors.InputSurface, uiTSkin(pwnd.Skin).DisabledColors.Border, props, pwnd.Opacity)
end;

begin
   pwnd := uiTWindow(source.wnd);

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
         source.SetColor(wdgCheckbox.CheckedColor)
      else
         source.SetColor(wdgCheckbox.DisabledColor);

      oxRender.LineWidth(wdgCheckbox.LineWidth);
      {draw a checkmark}
      uiDraw.Line(x1 + 2, y2 + 5, x1 + 5, y2 + 1);
      uiDraw.Line(x1 + 5, y2 + 1, x2 - 3, y1 - 2);
      oxRender.LineWidth(1.0);
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

procedure init();
begin
   wdgCheckbox.Internal.Done(wdgTCheckbox);

   wdgCheckbox := wdgTCheckboxGlobal.Create(wdgCheckbox.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgCheckbox);
end;

INITIALIZATION
   wdgCheckbox.Width := 18;
   wdgCheckbox.Height := 18;
   wdgCheckbox.LineWidth := 2.0;

   wdgCheckbox.DisabledColor.Assign(96, 96, 96, 255);
   wdgCheckbox.CheckedColor.Assign(32, 91, 32, 255);
   wdgCheckbox.Internal.Register('widget.checkbox', @init, @deinit);

END.
