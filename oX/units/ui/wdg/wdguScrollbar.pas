{
   wdguScrollbar, scroll bar widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguScrollbar;

INTERFACE

   USES
      uStd, uColors, uTiming,
      {app}
      appuKeys, appuMouse,
      {oX}
      uOX, oxuTypes, oxuRender,
      {ui}
      uiuTypes, oxuUI, uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuDraw, uiuWidgetRender, uiuRegisteredWidgets,
      wdguBase;

CONST
   {scrollbar actions}
   wdgSCROLLBAR_MOVED                  = $0001;

TYPE

   { wdgTScrollbar }

   wdgTScrollbar = class(uiTWidget)
     public
        Total,
        Visible,
        HandleSize,
        HandlePos,
        HandleMaxPos,
        HandleCapturePosition,
        SurfSize,
        Width: longint;
        b1,
        b2,
        surf,
        hr: oxTRect;
        b1a,
        b2a,
        surfa,
        hra: oxTRect;
        LightMode,
        {should the scrollbar be shown permanently}
        Permanent: boolean;

        InternalProperties: record
           LightMode,
           Horizontal: boolean;
        end;

   public
      constructor Create(); override;

      procedure Point(var {%H-}e: appTMouseEvent; x, y: longint); override;
      procedure Hover({%H-}x, {%H-}y: longint; what: uiTHoverEvent); override;
      procedure Render(); override;
      function Key(var k: appTKeyEvent): boolean; override;

      {set a top aligned scrollbar}
      function Top(): wdgTScrollbar;
      {set a bottom aligned scrollbar}
      function Bottom(): wdgTScrollbar;
      {set a left aligned scrollbar}
      function Left(): wdgTScrollbar;
      {set a right aligned scrollbar}
      function Right(): wdgTScrollbar;

      {activates standard mode, where scrollbar is shown in a default way}
      function Standard(): wdgTScrollbar;
      {activates light mode, where scrollbar is simpler, and only the scroll handle is visible (no buttons)}
      function Light(): wdgTScrollbar;

      {adjust to changes in position and dimensions}
      procedure Adjust();

      {return position, from 0.0 to 1.0}
      function GetHandlePosition(): single;
      {set handle position, from 0.0 to 1.0}
      procedure SetHandlePosition(p: single);

      function SetSize(_total, _visible: int64): wdgTScrollbar;

   private
      OpacityStart: TTimer;
      OpacityMul: single;

      procedure CalcHandleRect();
      procedure CalcRects();
      procedure CalcHandle();
      procedure MoveHandle(n: longint);
      function OnWhere(x, y: longint): longint;

      procedure CaptureMove(x, y: longint);

   protected
      procedure SizeChanged(); override;
      procedure PositionChanged(); override;
      procedure RPositionChanged(); override;
   end;

   { wdgTScrollbarGlobal }

   wdgTScrollbarGlobal = class(specialize wdgTBase<wdgTScrollbar>)
      Internal: uiTWidgetClass; static;

      {minimum handle size}
      MinHandleSize,
      {default width}
      Width,
      {width in light mode}
      LightWidth,
      {opacity for light mode surface}
      LightOpacity: longint; static;

      {adds a ScrollBar to a window, with the specified dimensions}
      function Add(Total, Visible: longint;
            const Pos: oxTPoint; const Dim: oxTDimensions; Horizontal: boolean = false): wdgTScrollbar;

      {adds a ScrollBar to a window, but do not specify position immediately}
      function Add(Total, Visible: longint): wdgTScrollbar;
   end;

VAR
   wdgScrollbar: wdgTScrollbarGlobal;

IMPLEMENTATION

procedure wdgTScrollbar.CalcHandleRect();
begin
   hr.x := surf.x;
   hr.y := surf.y;

   {vertical scrollbar}
   if(not InternalProperties.Horizontal) then begin
      dec(hr.y, HandlePos);
      hr.w := surf.w;
      hr.h := HandleSize;
   {horizontal scrollbar}
   end else begin
      inc(hr.x, HandlePos);
      hr.w := HandleSize;
      hr.h := surf.h;
   end;

   hra := hr;
   SetAbsolute(hra);
end;

{this calculates the bounding rectangles of the individual areas on the
scrollbar (button1, button2 and surface)}
procedure wdgTScrollbar.CalcRects();
begin
   {vertical scrollbar}
   if(not InternalProperties.Horizontal) then begin
      {calculate first button (up, left) rectangle}
      b1.Assign(Position.x, Position.y, Dimensions.w, Dimensions.w);

      {calculate second button (down, right) rectangle}
      b2.Assign(Position.x, Position.y - Dimensions.h + (Dimensions.w), Dimensions.w, Dimensions.w);

      {calculate surface rectangle}
      if(not LightMode) then
         surf.Assign(Position.x, Position.y - Dimensions.w, Dimensions.w, Dimensions.h - (2 * Dimensions.w))
      else
         surf.Assign(Position.x, Position.y, Dimensions.w, Dimensions.h);
   {horizontal scrollbar}
   end else begin
      {first button}
      b1.Assign(Position.x, Position.y, Dimensions.h, Dimensions.h);

      {second button}
      b2.Assign(Position.x + Dimensions.w - (Dimensions.h), Position.y, Dimensions.h, Dimensions.h);

      {calculate surface rectangle}
      if(not LightMode) then
         surf.Assign(Position.x + Dimensions.h, Position.y, Dimensions.w - (2 * Dimensions.h), Dimensions.h)
      else
         surf.Assign(Position.x, Position.y, Dimensions.w, Dimensions.h);
   end;

   {calculate absolute rectangles}
   b1a := b1;
   b2a := b2;
   surfa := surf;

   SetAbsolute(b1a);
   SetAbsolute(b2a);
   SetAbsolute(surfa);
end;

{this calculates the handle properties and associated values}
procedure wdgTScrollbar.CalcHandle();
var
   pcv: single; {percent visible}

begin
   {calculate the visible percent}
   if(Total > 0) then
      pcv := (100 / Total) * Visible
   else
      pcv := 0;

   if(not InternalProperties.Horizontal) then
      SurfSize := surf.h
   else
      SurfSize := surf.w;

   {calculate how many pixels the handle is big}
   if(pcv > 0) then begin
      HandleSize := round((SurfSize / 100) * pcv);
      if(HandleSize < wdgScrollbar.MinHandleSize) then
         HandleSize := wdgScrollbar.MinHandleSize;

      {calculate maximum handle position}
      HandleMaxPos := SurfSize - HandleSize - 1;

      {limit handle position}
      if(HandlePos < 0) then
         HandlePos := 0;

      if(HandlePos > HandleMaxPos) then
         HandlePos := HandleMaxPos;
   end;

   {calculate the handle rectangle}
   CalcHandleRect();
end;

procedure wdgTScrollbar.MoveHandle(n: longint);
begin
   if(HandleSize = 0) then
      exit;

   if(HandlePos + n > HandleMaxPos) then
      HandlePos := HandleMaxPos
   else if(HandlePos + n < 0) then
      HandlePos := 0
   else
      HandlePos := HandlePos + n;

   CalcHandleRect();

   Control(wdgSCROLLBAR_MOVED);
end;

CONST
   ON_UNKNOWN     =-1;
   ON_BUTTON_UP   = 0;
   ON_BUTTON_DOWN = 1;
   ON_HANDLE      = 2;
   ON_BEFORE      = 3;
   ON_AFTER       = 4;

function wdgTScrollbar.OnWhere(x, y: longint): longint;
begin
   onWhere := ON_UNKNOWN;

   {note: we get the x,y pointer position relative within the widget}
   x := x + Position.x;
   y := y + Position.y - Dimensions.h;

   {check buttons only if not in light mode}
   if(not LightMode) then begin
      {button 1}
      if(b1.Inside(x, y)) then
         exit(ON_BUTTON_UP)
      {button 2}
      else if(b2.Inside(x, y)) then
         exit(ON_BUTTON_DOWN);
   end;

   {If it's somewhere on the surface we need to check if the point
   is over the surface(before or after the handle) or on the handle.}
   if(surf.Inside(x, y)) then begin
      if(hr.Inside(x, y)) then
         result := ON_HANDLE
      {determine if before or after the handle}
      else begin
         if(not InternalProperties.Horizontal) then begin
            if(y > surf.y - HandlePos) then
               result := ON_BEFORE
            else if(y <= surf.y - HandlePos + HandleSize) then
               result := ON_AFTER;
         end else begin
            if(x < surfa.x + HandlePos) then
               result := ON_BEFORE
            else if(x >= surf.x + HandlePos + HandleSize) then
               result := ON_AFTER;
         end;
      end;
   end;
end;

procedure wdgTScrollbar.CaptureMove(x, y: longint);
var
   ox, oy: longint;

begin
   if(oxui.PointerCapture.Wdg = Self) then begin
      ox := x - round(oxui.PointerCapture.Point.x);
      oy := y - round(oxui.PointerCapture.Point.y);

      if(InternalProperties.Horizontal) then
         HandlePos := HandleCapturePosition + ox
      else
         HandlePos := HandleCapturePosition - oy;

      CalcHandle();

      Control(wdgSCROLLBAR_MOVED);
   end;
end;

procedure wdgTScrollbar.SizeChanged();
begin
   inherited SizeChanged;

   Adjust();
end;

procedure wdgTScrollbar.PositionChanged();
begin
   inherited PositionChanged;

   Adjust();
end;

procedure wdgTScrollbar.RPositionChanged();
begin
   inherited RPositionChanged;

   Adjust();
end;

constructor wdgTScrollbar.Create();
begin
   inherited;

   Standard();
   timer.Init(OpacityStart);
end;

procedure wdgTScrollbar.Point(var e: appTMouseEvent; x, y: longint);
var
   whaton: longint;

begin
   whaton := OnWhere(x, y);

   if(e.Action.IsSet(appmcRELEASED)) and (oxui.PointerCapture.Wdg = Self) then begin
      UnlockPointer();
   end;

   if(whaton <> ON_UNKNOWN) then begin
      if(e.Action.IsSet(appmcRELEASED)) then begin
         case whaton of
            ON_BUTTON_UP:
               MoveHandle(-1);
            ON_BUTTON_DOWN:
               MoveHandle(1);
            ON_BEFORE:
               MoveHandle(-HandleSize);
            ON_AFTER:
               MoveHandle(HandleSize);
         end;
      end else if(e.Action.IsSet(appmcPRESSED)) then begin
         if (whaton = ON_HANDLE) then begin
            HandleCapturePosition := HandlePos;
            LockPointer(x, y);
         end;
      end else if(e.Action.IsSet(appmcMOVED)) then begin
         CaptureMove(x, y);
      end;
   end else begin
      if(e.Action.IsSet(appmcMOVED)) then begin
         CaptureMove(x, y);
      end;
   end;
end;

procedure wdgTScrollbar.Hover(x, y: longint; what: uiTHoverEvent);
begin
   if(what = uiHOVER_START) then begin
      if(not Permanent) then begin
         OpacityMul := 0;
         OpacityStart.Start();
      end;
   end;
end;

procedure wdgTScrollbar.Render();
var
   cx,
   cy: longint; {central x and y positions}
   cSurface: TColor4ub;
   pSkin: uiTSkin;

begin
   if(LightMode) then begin
      if(not Hovering()) and (not Permanent) then
         exit;

      if(not Permanent) then begin
         OpacityStart.Update();
         OpacityMul := OpacityStart.Elapsedf();

         if(OpacityMul > 1) then
            OpacityMul := 1;
      end;
   end;

   pSkin := uiTSkin(uiTWindow(wnd).Skin);

   {first render the scrolling surface}
   cSurface := pSkin.Colors.LightSurface;
   if(LightMode) then begin
      if(not Permanent) then
         cSurface[3] := round(wdgScrollbar.LightOpacity * OpacityMul)
      else
         cSurface[3] := round(wdgScrollbar.LightOpacity);

      if(cSurface[3] < 255) then
         oxRender.EnableBlend();
   end;

   SetColor(cSurface);
   uiDraw.Box(surfa);

   if(cSurface[3] < 255) then
      oxRender.DisableBlend();

   {draw button rectangles}
   if(not LightMode) then begin
      SetColor(pSkin.Colors.Border);
      uiDraw.Rect(b1a);
      uiDraw.Rect(b2a);

      {draw button surfaces}
      SetColor(pSkin.Colors.Surface);
      uiDraw.Box(b1a.x + 1, b1a.y - 1, b1a.x + b1a.w - 2, b1a.y - b1a.h + 2);
      uiDraw.Box(b2a.x + 1, b2a.y - 1, b2a.x + b2a.w - 2, b2a.y - b2a.h + 2);

      {button markings}
      SetColor(pSkin.Colors.Text);
      {button 1}
      cx := b1a.x + (b1.w div 2);
      cy := b1a.y - (b1.h div 2);

      if(not InternalProperties.Horizontal) then begin
         uiDraw.Line(cx, cy + 2, cx - 2, cy - 2);
         uiDraw.Line(cx, cy + 2, cx + 2, cy - 2);
      end else begin
         uiDraw.Line(cx - 2, cy, cx + 2, cy + 2);
         uiDraw.Line(cx - 2, cy, cx + 2, cy - 2);
      end;

      {button 2}
      cx := b2a.x + (b2a.w div 2);
      cy := b2a.y - (b2a.h div 2);

      if(not InternalProperties.Horizontal) then begin
         uiDraw.Line(cx, cy - 2, cx - 2, cy + 2);
         uiDraw.Line(cx, cy - 2, cx + 2, cy + 2);
      end else begin
         uiDraw.Line(cx + 2, cy, cx - 2, cy + 2);
         uiDraw.Line(cx + 2, cy, cx - 2, cy - 2);
      end;
   end;

   {render the handle}
   if(HandleSize > 0) then begin
      if(LightMode) and (oxui.PointerCapture.Wdg = Self) then
         cSurface := pSkin.Colors.SelectedBorder
      else
         cSurface := pSkin.Colors.Surface;

      if(cSurface[3] < 255) then
         oxRender.EnableBlend();

      if(not LightMode) then begin
         SetColor(cSurface);
         uiDraw.Box(hra);
      end else begin
         uiRenderWidget.Box(hra.x, hra.y - hra.h + 1, hra.x + hra.w - 1, hra.y, cSurface, cSurface,
            wdgRENDER_BLOCK_SURFACE or wdgRENDER_BLOCK_BORDER, 1.0);
      end;

      if(cSurface[3] < 255) then
         oxRender.DisableBlend();

      if(not LightMode) then begin
         {render lines on the handle}
         if(IsSelected()) then
            SetColor(pSkin.Colors.LightSurface)
         else
            SetColor(pSkin.Colors.SelectedBorder);

         if(not InternalProperties.Horizontal) then begin
            cx := surfa.x + (surfa.w div 2);
            cy := surfa.y - HandlePos - (HandleSize div 2);
            uiDraw.HLine(cx - 3, cy - 2, cx + 3);
            uiDraw.HLine(cx - 3, cy, cx + 3);
            uiDraw.HLine(cx - 3, cy + 2, cx + 3);
         end else begin
            cx := surfa.x + HandlePos + (HandleSize div 2);
            cy := surfa.y - (surfa.h div 2);
            uiDraw.VLine(cx - 2, cy - 3, cy + 3);
            uiDraw.VLine(cx, cy - 3, cy + 3);
            uiDraw.VLine(cx + 2, cy - 3, cy + 3);
         end;
      end;
   end;
end;

function wdgTScrollbar.Key(var k: appTKeyEvent): boolean;
begin
   Result := true;

   if(k.Key.Equal(kcUP) or k.Key.Equal(kcLEFT)) then begin
      if(k.Key.IsPressed()) then
         moveHandle(-1);
   end else if(k.Key.Equal(kcDOWN) or k.Key.Equal(kcRIGHT)) then begin
      if(k.Key.IsPressed()) then
         moveHandle(1);
   end else if(k.Key.Equal(kcPGUP)) then begin
      if(k.Key.Released()) then
         moveHandle(-HandleSize);
   end else if(k.Key.Equal(kcPGUP)) then begin
      if(k.Key.Released()) then
         moveHandle(HandleSize);
   end else if(k.Key.Equal(kcHOME) or k.Key.Equal(kcNUMHOME)) then begin
      if(k.Key.Released()) then
         moveHandle(-HandleMaxPos);
   end else if(k.Key.Equal(kcEND) or k.Key.Equal(kcNUMEND)) then begin
      if(k.Key.Released()) then
         moveHandle(HandleMaxPos);
   end else
      Result := False;
end;

function wdgTScrollbar.Top(): wdgTScrollbar;
begin
   InternalProperties.Horizontal := true;

   Move(Parent.Border, Parent.Dimensions.h - (1 + Parent.Border));
   Resize(Parent.Dimensions.w - (Parent.Border * 2), Width);
   Adjust();

   Result := Self;
end;

function wdgTScrollbar.Bottom(): wdgTScrollbar;
begin
   InternalProperties.Horizontal := true;

   Move(Parent.Border, Parent.Border + Width - 1);
   Resize(Parent.Dimensions.w - (Parent.Border * 2), Width);
   Adjust();

   Result := Self;
end;

function wdgTScrollbar.Left(): wdgTScrollbar;
begin
   InternalProperties.Horizontal := false;

   Move(Parent.Border, Parent.Dimensions.h - (1 + Parent.Border));
   Resize(Width, Parent.Dimensions.h - (Parent.Border * 2));
   Adjust();

   Result := Self;
end;

function wdgTScrollbar.Right(): wdgTScrollbar;
begin
   InternalProperties.Horizontal := false;

   Move(Parent.Dimensions.w - (Width + Parent.Border), Parent.Dimensions.h - (1 + Parent.Border));
   Resize(Width, Parent.Dimensions.h - (Parent.Border * 2));
   Adjust();

   Result := Self;
end;

function wdgTScrollbar.Standard(): wdgTScrollbar;
begin
   LightMode := false;
   Width := wdgScrollbar.Width;
   result := Self;
end;

function wdgTScrollbar.Light(): wdgTScrollbar;
begin
   LightMode := true;
   Permanent := false;
   Width := wdgScrollbar.LightWidth;
   result := Self;
end;

procedure wdgTScrollbar.Adjust();
begin
   CalcRects();
   CalcHandle();
end;

function wdgTScrollbar.GetHandlePosition(): single;
begin
   result := (1.0 / HandleMaxPos) * HandlePos;
end;

procedure wdgTScrollbar.SetHandlePosition(p: single);
begin
   if(p < 0) then
      p := 0
   else if(p > 1) then
      p := 1;

   HandlePos := trunc(HandleMaxPos * p);

   CalcHandleRect();
end;

function wdgTScrollbar.SetSize(_total, _visible: int64): wdgTScrollbar;
begin
   Total     := _total;
   Visible   := _visible;

   assert(_total >= _visible, 'Scrollbar total size should always be greater than visible size');
   HandlePos := 0;

   if(Dimensions.w <> 0) and (Dimensions.h <> 0) then
      Adjust();

   result := Self;
end;

procedure InitWidget();
begin
   wdgScrollbar.Internal.Done(wdgTScrollbar);

   wdgScrollbar := wdgTScrollbarGlobal.Create(wdgScrollbar.Internal);
end;

function wdgTScrollbarGlobal.Add(Total, Visible: longint;
      const Pos: oxTPoint; const Dim: oxTDimensions; horizontal: boolean): wdgTScrollbar;

begin
   result := wdgTScrollbar(uiWidget.Add(internal, Pos, Dim));

   if(result <> nil) then begin
      result.InternalProperties.Horizontal := horizontal;

      result.SetSize(Total, Visible);
   end;
end;

function wdgTScrollbarGlobal.Add(Total, Visible: longint): wdgTScrollbar;
begin
   Result := Add(Total, Visible, oxNullPoint, oxNullDimensions);
end;


INITIALIZATION
   wdgScrollbar.MinHandleSize := 16;
   wdgScrollbar.Width := 20;
   wdgScrollbar.LightWidth := 10;
   wdgScrollbar.LightOpacity := 127;

   wdgScrollbar.Internal.Register('widget.scrollbar', @InitWidget);

END.
