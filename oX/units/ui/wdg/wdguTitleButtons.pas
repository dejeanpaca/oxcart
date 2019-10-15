{
   wdguTitleButtons, title button widget
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguTitleButtons;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindow, uiuWindowTypes, uiuTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase;

TYPE
   { wdgTTitleButton }

   wdgTTitleTButton = record
      x, {x offset}
      w,  {specific width}
      Which: loopint; {ID}
      Highlighted: boolean;
      Mask: dword;
   end;


   { wdgTTitleButtons }

   wdgTTitleButtons = class(uiTWidget)
      procedure Point(var e: appTMouseEvent; x, {%H-}y: longint); override;
      procedure Render(); override;
      procedure Hover({%H-}x, {%H-}y: longint; what: uiTHoverEvent); override;
      procedure Action(action: uiTWidgetEvents); override;

      procedure SizeChanged(); override;
      procedure ParentSizeChange(); override;

   protected
      procedure FontChanged(); override;

   private
      Buttons: record
         n, {number of Buttons}
         h, {default height}
         w, {default width}
         Spacing: loopint; {spacing}

         b: array[0..uiwcbNMAX-1] of wdgTTitleTButton;
      end;

      procedure Calculate();
      function OnWhere(x: loopint): loopint;
      procedure UnHighlight();
   end;

   { wdgTTitleButtonsGlobal }

   wdgTTitleButtonsGlobal = class(specialize wdgTBase<wdgTTitleButtons>)
      Internal: uiTWidgetClass; static;

      {title button size ratio, button size:title height,
      used for both button height and width [square]}
      ButtonSizeRatio: single; static;
   end;

VAR
   wdgTitleButtons: wdgTTitleButtonsGlobal;

IMPLEMENTATION

{NOTE: the specific width is currently the same for any button}

procedure wdgTTitleButtons.Point(var e: appTMouseEvent; x, {%H-}y: longint);
var
   whaton: longint;

begin
   if(e.button = appmcLEFT) then begin
      whaton := OnWhere(x);

      if(whaton <> -1) then begin
         if(e.Action = appmcPRESSED) then
            Buttons.b[whaton].Highlighted := true
         else  if(e.Action = appmcRELEASED) then begin
            Buttons.b[whaton].Highlighted := false;

            case Buttons.b[whaton].Which of
               uiwBUTTON_CLOSE:
                  uiTWindow(wnd).Close();
               uiwBUTTON_MINIMIZE:
                  uiTWindow(wnd).Minimize();
               uiwBUTTON_MAXIMIZE:
                  uiTWindow(wnd).Maximize();
            end;
         end;

      end;
   end;
end;

{add the widget automatically to a window when it's created}
procedure wdgAdd(wnd: uiTWindow);
var
   pWdg: wdgTTitleButtons;

begin
   if (wnd.Parent <> nil) then begin
      pWdg := wdgTTitleButtons(uiWidget.Add(wdgTitleButtons.Internal,
         oxPoint(0, 0), oxDimensions(0, 0)).
         SetID(uiWidget.IDs.TITLE_BUTTONS));

      if(pWdg <> nil) then begin
         Include(pWdg.Properties, wdgpNON_CLIENT);

         pWdg.Calculate();
      end;
   end;
end;

{render the widget}
procedure wdgTTitleButtons.Render();
var
   pSkin: uiTSkin;

   x,
   i,
   y1: loopint;

   f: oxTFont;
   r: oxTRect;

   pWnd: uiTWindow;
   colors: uiPWindowSkinColors;

   scale: single;

begin
   pWnd := uiTWindow(wnd);
   pSkin := uiTSkin(pWnd.Skin);

   if(pWnd.IsSelected()) then
      colors := @pSkin.Window.Colors
   else
      colors := @pSkin.Window.InactiveColors;

   if(pWnd.Frame <> uiwFRAME_STYLE_NONE) and (pSkin <> nil) then begin
      if(Buttons.n > 0) then begin
         {set button color}
         SetColor(cWhite4ub);

         x  := RPosition.x;
         y1 := RPosition.y;

         f := CachedFont;
         f.Start();
         scale := (Buttons.h) / f.GetHeight();
         f.Scale(scale, scale);

         {render all the Buttons}
         for i := 0 to (Buttons.n - 1) do begin
            r.x := x + Buttons.b[i].x;
            r.y := y1;
            r.w := Buttons.w;
            r.h := Buttons.h;

            if(r.x + r.w < wnd.RPosition.x) or (r.x + r.w > wnd.RPosition.x + wnd.Dimensions.w) then
               continue;

            if(not Buttons.b[i].Highlighted) then
               pWnd.SetColorBlended(colors^.cTitleBt)
            else
               pWnd.SetColorBlended(colors^.cTitleBtHighlight);

            f.WriteCentered(pSkin.Window.cTitleBtSymbols[Buttons.b[i].Which], r, oxfpCenterHV);
         end;

         f.Scale(1, 1);

         oxf.Stop();
      end;
   end;
end;

procedure wdgTTitleButtons.Hover({%H-}x, {%H-}y: longint; what: uiTHoverEvent);
begin
   if(wdgpENABLED in Properties) then begin
      if(what = uiHOVER_NO) then
         UnHighlight();
   end;
end;

procedure wdgTTitleButtons.Action(action: uiTWidgetEvents);
begin
   if(uiTWindow(wnd).Frame <> uiwFRAME_STYLE_NONE) then begin
      if(action = uiwdgACTION_MOVE) then
         Calculate()
      else if(action = uiwdgACTION_DEACTIVATE) then
         UnHighlight();
   end;
end;

procedure wdgTTitleButtons.SizeChanged();
begin
   inherited SizeChanged;

   Calculate();
end;

procedure wdgTTitleButtons.ParentSizeChange();
begin
   inherited ParentSizeChange;

   Calculate();
end;

{calculate the properties of the title buttons}
procedure wdgTTitleButtons.Calculate();
var
   pWnd: uiTWindow;
   pSkin: uiTSkin;
   i,
   n,
   x,
   totalWidth,
   titleHeight: loopint; {title height}

begin
   pWnd := uiTWindow(wnd);

   if(pWnd = nil) then
      exit;

   pSkin := uiTSkin(pWnd.Skin);
   if(pWnd.Frame <> uiwFRAME_STYLE_NONE) and (pSkin <> nil) then begin
      titleHeight := pWnd.GetTitleHeight();

      {get the dimensions of individual Buttons}
      if(wdgTitleButtons.ButtonSizeRatio > 0) then
         Buttons.h := round(titleHeight * wdgTitleButtons.ButtonSizeRatio)
      else
         Buttons.h := CachedFont.GetHeight();

      Buttons.w := Buttons.h;

      Buttons.Spacing := 1; {set the spacing}

      {figure out how many Buttons there are and their properties}
      n := 0;
      x := 0;
      totalWidth := 0;

      for i := uiwcBUTTON_MAX downto 0 do begin
         if(pWnd.Buttons and (1 shl i) > 0) then begin
            Buttons.b[n].Highlighted := false;
            Buttons.b[n].x           := x;
            Buttons.b[n].w           := Buttons.w;
            Buttons.b[n].Which       := i;
            Buttons.b[n].Mask      := 1 shl i;

            inc(x, Buttons.b[n].w + Buttons.Spacing); {move the offset}
            inc(totalWidth, Buttons.b[n].w + Buttons.Spacing);
            inc(n);
         end;
      end;

      {there is no spacing after the last button needed}
      if(totalWidth > 0) then
         dec(totalWidth, Buttons.Spacing);

      Buttons.n := n; {set the number of Buttons}

      {calculate the total dimensions of the widget}
      Dimensions.h := Buttons.h;
      Dimensions.w := totalWidth;

      {need to determine the position of the widget}
      Position.y := pWnd.Dimensions.h + (titleHeight + Buttons.h) div 2;
      Position.x := pWnd.Dimensions.w - totalWidth - uiTWindow(wnd).GetFrameWidth() -
         {move away from the b}
         loopint((round((Buttons.h)) div 4));

      {update widgets relative position}
      PositionUpdate();
   end;
end;

function wdgTTitleButtons.OnWhere(x: loopint): loopint;
var
   i,
   p: loopint;

begin
   Result := -1;

   {NOTE: this routine will only check horizontally, as all Buttons cover the vertical dimensions of the widget}

   p := 0;

   for i := 0 to (Buttons.n - 1) do begin
      {let's see of the pointer is within this button}
      if(x >= p) and (x < p + Buttons.b[i].w) then
         exit(i);

      {go to the next button}
      inc(p, Buttons.b[i].w + Buttons.Spacing);
   end;
end;

procedure wdgTTitleButtons.UnHighlight();
var
   i: loopint;

begin
   for i := 0 to (Buttons.n - 1) do
      Buttons.b[i].Highlighted := false;
end;

procedure wdgTTitleButtons.FontChanged();
begin
   Calculate();
end;

procedure init();
begin
   wdgTitleButtons.Internal.SelectOnAdd := false;
   wdgTitleButtons.Internal.NonSelectable := true;

   wdgTitleButtons.Internal.Done(wdgTTitleButtons);

   wdgTitleButtons := wdgTTitleButtonsGlobal.Create(wdgTitleButtons.Internal);

   uiWindow.OnCreate.Add(@wdgAdd);
end;

procedure deinit();
begin
   FreeObject(wdgTitleButtons);
end;

INITIALIZATION
   wdgTitleButtons.ButtonSizeRatio := 0;
   wdgTitleButtons.Internal.Register('widget.title_buttons', @init, @deinit);

END.
