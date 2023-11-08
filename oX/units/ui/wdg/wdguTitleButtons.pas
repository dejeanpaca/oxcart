{
   wdguTitleButtons, title button widget
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguTitleButtons;

INTERFACE

   USES
      uColors,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindow, uiuWindowTypes, uiuTypes,
      uiuWidget, uiWidgets;

TYPE
   {a button}
   wdgTTitleTButton = record
      x, {x offset}
      w,  {specific width}
      which: longint; {ID}
      highlighted: boolean;
      btmask: dword;
   end;


   { wdgTTitleButtons }

   wdgTTitleButtons = class(uiTWidget)
      procedure Point(var e: appTMouseEvent; x, {%H-}y: longint); override;
      procedure Render(); override;
      procedure Hover({%H-}x, {%H-}y: longint; what: uiTHoverEvent); override;
      procedure Action(action: uiTWidgetEvents); override;

      procedure SizeChanged; override;
      procedure ParentSizeChange; override;

   protected
      procedure FontChanged; override;

   private
      buttons: record
         n: longint; {number of buttons}

         h, {default height}
         w, {default width}
         spc: longint; {spacing}

         b: array[0..uiwcbNMAX-1] of wdgTTitleTButton;
      end;

      procedure Calculate();
      function onWhere(x: longint): longint;
      procedure unHighlight();
   end;

   uiTWidgetTitleButtonsGlobal = record
      {title button size ratio, button size:title height,
      used for both button height and width [square]}
      ButtonSizeRatio: single;
   end;

VAR
   wdgTitleButtons: uiTWidgetTitleButtonsGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

{NOTE: the specific width is currently the same for any button}


procedure wdgTTitleButtons.Point(var e: appTMouseEvent; x, {%H-}y: longint);
var
   whaton: longint;

begin
   if(e.button = appmcLEFT) then begin
      whaton := onWhere(x);

      if(whaton <> -1) then begin
         if(e.Action = appmcPRESSED) then
            buttons.b[whaton].highlighted := true
         else  if(e.Action = appmcRELEASED) then begin
            buttons.b[whaton].highlighted := false;

            case buttons.b[whaton].which of
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
      pWdg := wdgTTitleButtons(uiWidget.Add(internal,
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
   i: longint;

   y1: longint;

   f: oxTFont;
   r: oxTRect;

   pwnd: uiTWindow;
   colors: uiPWindowSkinColors;

   scale: single;

begin
   pwnd := uiTWindow(wnd);
   pSkin := pwnd.Skin;

   if(pwnd.IsSelected()) then
      colors := @pwnd.Skin.Window.Colors
   else
      colors := @pwnd.Skin.Window.InactiveColors;

   if(pwnd.Frame <> uiwFRAME_STYLE_NONE) and (pSkin <> nil) then begin
      if(buttons.n > 0) then begin
         {set button color}
         SetColor(cWhite4ub);

         x  := RPosition.x;
         y1 := RPosition.y;

         f := CachedFont;
         f.Start();
         scale := (buttons.h) / f.GetHeight();
         f.Scale(scale, scale);

         {render all the buttons}
         for i := 0 to (buttons.n - 1) do begin
            r.x := x + buttons.b[i].x;
            r.y := y1;
            r.w := buttons.w;
            r.h := buttons.h;

            if(r.x + r.w < wnd.RPosition.x) or (r.x + r.w > wnd.RPosition.x + wnd.Dimensions.w) then
               continue;

            if(not buttons.b[i].highlighted) then
               pwnd.SetColorBlended(colors^.cTitleBt)
            else
               pwnd.SetColorBlended(colors^.cTitleBtHighlight);

            f.WriteCentered(pSkin.Window.cTitleBtSymbols[buttons.b[i].which], r, oxfpCenterHV);
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
         unHighlight();
   end;
end;

procedure wdgTTitleButtons.Action(action: uiTWidgetEvents);
begin
   if(uiTWindow(wnd).Frame <> uiwFRAME_STYLE_NONE) then begin
      if(action = uiwdgACTION_MOVE) then
         Calculate()
      else if(action = uiwdgACTION_DEACTIVATE) then
         unHighlight();
   end;
end;

procedure wdgTTitleButtons.SizeChanged;
begin
   inherited SizeChanged;

   Calculate();
end;

procedure wdgTTitleButtons.ParentSizeChange;
begin
   inherited ParentSizeChange;

   Calculate();
end;

{calculate the properties of the title buttons}
procedure wdgTTitleButtons.Calculate();
var
   pwnd: uiTWindow;
   pskin: uiTSkin;
   i,
   n,
   x,
   totalWidth: longint;
   th: longint; {title height}

begin
   pwnd := uiTWindow(wnd);

   if(pwnd = nil) then
      exit;

   pSkin := pwnd.Skin;
   if(pwnd.Frame <> uiwFRAME_STYLE_NONE) and (pSkin <> nil) then begin
      th := pwnd.GetTitleHeight();

      {get the dimensions of individual buttons}
      if(wdgTitleButtons.ButtonSizeRatio > 0) then
         buttons.h := round(th * wdgTitleButtons.ButtonSizeRatio)
      else
         buttons.h := CachedFont.GetHeight();

      buttons.w := buttons.h;

      buttons.spc := 1; {set the spacing}

      {figure out how many buttons there are and their properties}
      n := 0;
      x := 0;
      totalWidth := 0;

      for i := uiwcBUTTON_MAX downto 0 do begin
         if(pwnd.Buttons and (1 shl i) > 0) then begin
            buttons.b[n].highlighted := false;
            buttons.b[n].x           := x;
            buttons.b[n].w           := buttons.w;
            buttons.b[n].which       := i;
            buttons.b[n].btmask      := 1 shl i;

            inc(x, buttons.b[n].w + buttons.spc); {move the offset}
            inc(totalWidth, buttons.b[n].w + buttons.spc);
            inc(n);
         end;
      end;

      {there is no spacing after the last button needed}
      if(totalWidth > 0) then
         dec(totalWidth, buttons.spc);

      buttons.n := n; {set the number of buttons}

      {calculate the total dimensions of the widget}
      Dimensions.h := buttons.h;
      Dimensions.w := totalWidth;

      {need to determine the position of the widget}
      Position.y := pwnd.Dimensions.h + (th + buttons.h) div 2;
      Position.x := pwnd.Dimensions.w - totalWidth - uiTWindow(wnd).GetFrameWidth() -
         {move away from the b}
         (round((buttons.h)) div 4);

      {update widgets relative position}
      PositionUpdate();
   end;
end;

function wdgTTitleButtons.onWhere(x: longint): longint;
var
   i, p: longint;

begin
   result := -1;

   {note: this routine will only check horizontally, as all buttons
   cover the vertical dimensions of the widget}

   p := 0;

   for i := 0 to (buttons.n - 1) do begin
      {let's see of the pointer is within this button}
      if(x >= p) and (x < p + buttons.b[i].w) then
         exit(i);

      {go to the next button}
      inc(p, buttons.b[i].w + buttons.spc);
   end;
end;

procedure wdgTTitleButtons.unHighlight();
var
   i: longint;

begin
   for i := 0 to (buttons.n - 1) do
      buttons.b[i].highlighted := false;
end;

procedure wdgTTitleButtons.FontChanged;
begin
   Calculate();
end;

procedure initWidget();
begin
   internal.SelectOnAdd     := false;
   internal.NonSelectable   := true;
   internal.Instance := wdgTTitleButtons;

   internal.Done();

   uiWindow.OnCreate.Add(@wdgAdd);
end;

INITIALIZATION
   wdgTitleButtons.ButtonSizeRatio := 0;
   internal.Register('widget.titlebuttons', @InitWidget);

END.
