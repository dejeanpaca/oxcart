{
   wdguRadioButton, progress bar widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguRadioButton;

INTERFACE

   USES
      uStd, uColors, vmVector,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxumPrimitive, oxuTexture, oxuTransform,
      {ui}
      uiuWindowTypes, uiuWindow, uiuWidget, uiWidgets;

TYPE

   { wdgTRadioButton }

   wdgTRadioButton = class(uiTWidget)
   public
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      procedure Render(); override;
      function Key(var k: appTKeyEvent): boolean; override;

      function SetGroup(g: longint): wdgTRadioButton; override;

      {set the check-box state}
      procedure Mark();
   end;

   { wdgTRadioButtonGlobal }

   wdgTRadioButtonGlobal = record
      Diameter, CaptionSpace: longint;
      Inner, Outer: oxTPrimitiveModel;

      clrDisabled: TColor4ub;

      procedure SetSize(w, h: longint);

      function Add(const Caption: string;
                  const Pos: oxTPoint;
                  value: boolean = false): wdgTRadioButton;
   end;

VAR
   wdgRadioButton: wdgTRadioButtonGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;


procedure wdgTRadioButton.Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint);
begin
   if(e.Action and appmcRELEASED > 0) and (e.Button and appmcLEFT > 0) then
      Mark();
end;

procedure wdgTRadioButton.Render();
var
   f: oxTFont;
   offset: longint;
   m: TMatrix4f;

begin
   offset := wdgRadioButton.Diameter div 2;

   m := oxTransform.Matrix;
   oxTransform.Translate(Position.x + offset, Position.y - offset, 0);
   oxTransform.Apply();

   SetColor(uiTWindow(wnd).Skin.Colors.Highlight);

   wdgRadioButton.Outer.Render();

   // if selected, choose the inner one
   if(wdgpTRUE in Properties) then
      wdgRadioButton.Inner.Render();

   oxTransform.Apply(m);

   if(Caption <> '') then begin
      f := CachedFont;
      offset := abs((wdgRadioButton.Diameter - f.GetHeight()) div 2) + f.GetHeight();

      f.Start();
      f.Write(RPosition.x + wdgRadioButton.Diameter + wdgRadioButton.CaptionSpace, RPosition.y - offset, Caption);
      oxf.Stop();
   end;
end;

function wdgTRadioButton.Key(var k: appTKeyEvent): boolean;
begin
   Result := false;

   if(k.Key.Equal(kcSPACE) or k.Key.Equal(kcENTER)) then begin
      if(k.Key.Released()) then
	     Mark();

      Result := true;
   end;
end;

function wdgTRadioButton.SetGroup(g: longint): wdgTRadioButton;
begin
   Result := wdgTRadioButton(inherited SetGroup(g));
end;

procedure wdgTRadioButton.Mark();
var
   w: uiTWidgets;
   i: longint;

begin
   w := GetWidgetsContainer();

   // go through widgets
   for i := 0 to w.w.n - 1 do
      if (uiTWidget(w.w.List[i]).Group = Group) and (w.w.List[i].ClassType = wdgTRadioButton) then
         Exclude(wdgTRadioButton(w.w.List[i]).Properties, wdgpTRUE);

   Include(Properties, wdgpTRUE);

   // TODO: Send events about state change perhaps
end;

procedure InitWidget();
begin
   internal.Instance := wdgTRadioButton;
   internal.Done();
end;

procedure wdgTRadioButtonGlobal.SetSize(w, h: longint);
begin
   Diameter := w;
   Diameter := h;

   Inner.InitDisk((Diameter / 2) * 0.75, 32);
   Outer.InitCircle(Diameter / 2, 32);
end;

function wdgTRadioButtonGlobal.Add(const Caption: string;
         const Pos: oxTPoint;
         value: boolean = false): wdgTRadioButton;

begin
   result := wdgTRadioButton(uiWidget.Add(internal, Pos, oxDimensions(0, 0)));

   if(result <> nil) then begin
      result.SetCaption(Caption);

      if(value) then
         result.Mark();

      if(result.Dimensions.h = 0) then
         result.Dimensions.h := wdgRadioButton.Diameter;

      if(result.Dimensions.w = 0) then begin
         result.Dimensions.w := wdgRadioButton.Diameter + wdgRadioButton.CaptionSpace;

         inc(result.Dimensions.w, result.CachedFont.GetLength(Caption));
      end;
   end;
end;


INITIALIZATION
   wdgRadioButton.SetSize(16, 16);
   wdgRadioButton.CaptionSpace := 4;
   wdgRadioButton.clrDisabled.Assign(96, 96, 96, 255);
   internal.Register('widget.radiobutton', @InitWidget);
END.

