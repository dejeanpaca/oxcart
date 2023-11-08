{
   uiuPointerEvents, UI mouse events
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuPointerEvents;

INTERFACE

   USES
      sysutils, uStd, uTiming,
      {app}
      appuMouse, appuEvents, appuMouseEvents,
      {oX}
      oxuWindowTypes, oxuTypes, oxuGlobalInstances, oxuWindow,
      {ui}
      oxuUI, uiuUI, uiuTypes, uiuControl, uiuCursor, uiuPointer,
      uiuWindowTypes, uiuWindow, uiuWidget, uiWidgets;

TYPE
   { uiTPointerEventsGlobal }

   uiTPointerEventsGlobal = record
      OpenContextWindow: uiTWindowProcedure;

      procedure Action(oxui: uiTUI; var event: appTEvent);
   end;

VAR
   uiPointerEvents: uiTPointerEventsGlobal;

IMPLEMENTATION

procedure uiTPointerEventsGlobal.Action(oxui: uiTUI; var event: appTEvent);
var
   m: appTMouseEvent;
   p,
   mv: oxTPoint;
   pf: oxTPointf;
   uiwnd: uiTWindow = nil;
   pmSelect: uiTSelectInfo;

   pmWindow: uiTWindow  = nil; {window over which the mouse previously hovered}
   pWindow: uiTWindow   = nil;

   pWidget: uiTWidget   = nil; {previously selected widget}
   pmWidget: uiTWidget  = nil; {widget over which the mouse previously hovered}

   changeSelect: uiTWindow;

{checks if the point is in title}
function inTitle(wnd: uiTWindow): boolean;
begin
   Result := p.y >= wnd.RPosition.y;
end;

procedure MoveWindow();
begin
   {move the window by relative coordinates}
   if(not oxui.PointerCapture.Moved) then begin
      oxui.PointerCapture.Moved := true;

      oxui.PointerCapture.Wnd.OnStartDrag();
      Include(oxui.PointerCapture.Wnd.Properties, uiwndpMOVED);
   end else
      oxui.PointerCapture.Wnd.OnDrag();

   oxui.PointerCapture.Wnd.MoveRelative(mv.x, mv.y);
end;

procedure ResizeWindow();
var
   w: uiTWindow;

begin
   w := oxui.PointerCapture.Wnd;

   if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_LEFT) then begin
      w.Move(w.Position.x + mv.x, w.Position.y);
      w.Resize(w.Dimensions.w - mv.x, w.Dimensions.h);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_RIGHT) then begin
      w.Resize(w.Dimensions.w + mv.x, w.Dimensions.h);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_TOP) then begin
      w.Move(w.Position.x, w.Position.y + mv.y);
      w.Resize(w.Dimensions.w, w.Dimensions.h + mv.y);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_BOTTOM) then begin
      w.Resize(w.Dimensions.w, w.Dimensions.h - mv.y);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_TL) then begin
      w.Move(w.Position.x + mv.x, w.Position.y + mv.y);
      w.Resize(w.Dimensions.w - mv.x, w.Dimensions.h + mv.y);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_TR) then begin
      w.Move(w.Position.x, w.Position.y + mv.y);
      w.Resize(w.Dimensions.w + mv.x, w.Dimensions.h + mv.y);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_BL) then begin
      w.Move(w.Position.x + mv.x, w.Position.y);
      w.Resize(w.Dimensions.w - mv.x, w.Dimensions.h - mv.y);
   end else if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_SIZE_BR) then begin
      w.Resize(w.Dimensions.w + mv.x, w.Dimensions.h - mv.y);
   end;
end;

procedure WindowOperations();
var
   distance: Single;

begin
   if(oxui.PointerCapture.Wnd = nil) then begin
      oxui.PointerCapture.Clear();
      exit;
   end;

   if(p.x <> oxui.WindowMove.x) or (p.y <> oxui.WindowMove.y) then begin
      mv.x  := p.x - oxui.WindowMove.x;
      mv.y  := p.y - oxui.WindowMove.y;

      pf.Assign(p);
      distance := pf.Distance(oxui.PointerCapture.Point);

      if(distance >= uiPointer.ActionMinimumDistance) or (uiwndpMOVED in oxui.PointerCapture.Wnd.Properties) then begin
         oxui.WindowMove.Assign(p.x, p.y);

         if(mv.x <> 0) or (mv.y <> 0) then begin
            if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_MOVE) then
               MoveWindow()
            else
               ResizeWindow();
         end;
      end;
   end;

   {let's see if the lock is released}
   if(m.Action.IsSet(appmcRELEASED) and m.Button.IsSet(appmcLEFT)) then begin
      if(oxui.PointerCapture.WindowOperation = uiWINDOW_POINTER_MOVE) then begin
         if(uiwndpMOVED in oxui.PointerCapture.Wnd.Properties) then
            oxui.PointerCapture.Wnd.OnStopDrag();

         {lock released}
         Exclude(oxui.PointerCapture.Wnd.Properties, uiwndpMOVED);
      end;

      oxui.PointerCapture.Clear();
   end;
end;

procedure HoverEvent(wdg: uiTWidget; what: uiTHoverEvent);
var
   sp: oxTPoint;

begin
   sp := wdg.GetPointerPosition(p.x, p.y);
   wdg.Hover(sp.x, sp.y, what);
end;

procedure PointEvent(wdg: uiTWidget);
var
   sp: oxTPoint;

begin
   sp := wdg.GetPointerPosition(p.x, p.y);

   if(wdg.IsEnabled()) then
      wdg.Point(m, sp.x, sp.y);
end;

procedure PointEvent(wnd: uiTWindow);
var
   sp: oxTPoint;

begin
   sp := wnd.GetPointerPosition(p.x, p.y);

   if(uiwndpENABLED in wnd.Properties) then
      wnd.Point(m, sp.x, sp.y);
end;

function WidgetCapture(): boolean;
begin
   if(oxui.PointerCapture.Wdg <> nil) then begin
      if(m.Action.IsSet(appmcRELEASED)) then begin
         oxui.PointerCapture.Wdg.UnlockPointer();
      end else begin
         PointEvent(oxui.PointerCapture.Wdg);
      end;

      exit(true);
   end else
      oxui.PointerCapture.Typ := uiPOINTER_CAPTURE_NONE;

   exit(false);
end;

function WindowCapture(): boolean;
begin
   if(oxui.PointerCapture.Wnd <> nil) then begin
      PointEvent(oxui.PointerCapture.Wnd);

      exit(true);
   end else
      oxui.PointerCapture.Typ := uiPOINTER_CAPTURE_NONE;

   exit(false);
end;

procedure HoverStart();
var
   i: longint;
   cur: uiTControl;

begin
   {go through widgets until found one marked as hovering over, or reach the top of the list}

   for i := oxui.mSelect.l downto 0 do begin
      cur := oxui.mSelect.s[i];

      if(cur.ControlType = uiCONTROL_WIDGET) then
         if(not uiTWidget(cur).Hovering()) then begin
            Include(uiTWidget(cur).Properties, wdgpHOVERING);
            HoverEvent(uiTWidget(cur), uiHOVER_START);
         end else
            break;
   end;
end;

procedure HoverNo(breakOn: uiTControl);
var
   i,
   j: longint;
   cur: uiTControl;

begin
   {find breaking point}
   for i := pmSelect.l downto 0 do begin
      cur := pmSelect.s[i];

      {tell breaking point and all nested controls they're no longer hovered over}
      if (cur = breakOn) then begin
         for j := i to pmSelect.l do begin
            cur := pmSelect.s[j];

            Exclude(uiTWidget(cur).Properties, wdgpHOVERING);
            HoverEvent(uiTWidget(cur), uiHOVER_NO);
         end;

         break;
      end;
   end;
end;

procedure NotifyHover();
begin
   {if the widgets are different we need to notify them of hovering}
   if(oxui.mSelect.Selected <> pmWidget) then begin
      {tell the previous widget the pointer is no longer hovering over it}
      if(pmWidget <> nil) then
         HoverNo(pmWidget);

      {tell the current widget the pointer is hovering over it}
      if(oxui.mSelect.Selected <> nil) then
         HoverStart();
   end else begin
     {if it's the same widget we'll tell it were still hovering over it}
      if(oxui.mSelect.Selected <> nil) and (oxui.mSelect.Selected.ControlType = uiCONTROL_WIDGET) then
         HoverEvent(uiTWidget(oxui.mSelect.Selected), uiHOVER);
   end;
end;

procedure NotifyEvent();
var
   wnd: uiTWindow;
   sp: oxTPoint;

begin
   if(oxui.Select.Selected <> nil) then begin
      wnd := uiTWindow(oxui.Select.Selected.wnd);
      sp := wnd.GetPointerPosition(p.x, p.y);

      wnd.Point(m, sp.x, sp.y);

      wnd.PropagateEvent(event);
   end;
end;

procedure TryCaptureWindow();
var
   border: loopint;
   wnd: uiTWindow;
   ok: boolean;
   operation: uiTPointerWindowOperation;
   left,
   right,
   bottom,
   top: boolean;

begin
   ok := false;

   if(oxui.Select.Selected = nil) then
      exit;

   wnd := uiTWindow(oxui.mSelect.GetSelectedWnd());
   if(wnd = nil) then
      exit;

   operation := uiWINDOW_POINTER_NONE;

   {determine current operation}
   top := false;
   bottom := false;
   left := false;
   right := false;

   {additional border along with the frame}
   border := uiWindow.SizeBorder - wnd.GetFrameWidth();

   if(p.x <= wnd.RPosition.x + border) then
      left := true
   else if(p.x >= wnd.RPosition.x + wnd.Dimensions.w - border) then
      right := true;

   if(p.y >= wnd.RPosition.y + (wnd.GetTitleHeight() - uiWindow.SizeBorder)) then
      top := true
   else if(p.y <= wnd.RPosition.y - wnd.Dimensions.h + border) then
      bottom := true;

   if(uiwndpRESIZABLE in wnd.Properties) then begin
      if(left) and (not right) and (not top) and (not bottom) then
         operation := uiWINDOW_POINTER_SIZE_LEFT
      else if(not left) and (right) and (not top) and (not bottom) then
         operation := uiWINDOW_POINTER_SIZE_RIGHT
      else if(not left) and (not right) and (top) and (not bottom) then
         operation := uiWINDOW_POINTER_SIZE_TOP
      else if(not left) and (not right) and (not top) and (bottom) then
         operation := uiWINDOW_POINTER_SIZE_BOTTOM
      else if(left) and (not right) and (top) and (not bottom) then
         operation := uiWINDOW_POINTER_SIZE_TL
      else if(not left) and (right) and (top) and (not bottom) then
         operation := uiWINDOW_POINTER_SIZE_TR
      else if(left) and (not right) and (not top) and (bottom) then
         operation := uiWINDOW_POINTER_SIZE_BL
      else if(not left) and (right) and (not top) and (bottom) then
         operation := uiWINDOW_POINTER_SIZE_BR;
   end;

   if(m.Action.IsSet(appmcPRESSED)) and (m.Button.IsSet(appmcLEFT)) and
   (uiwndpMOVABLE in wnd.Properties) then begin
      if(operation <> uiWINDOW_POINTER_NONE) then
         ok := true;

      {check if window is movable/resizeable}
      if(not (uiwndpMAXIMIZED in wnd.Properties)) and (not ok) then begin
         if(not left) and (not right) and (not top) and (not bottom) then begin
            if(inTitle(wnd)) then
               ok := true
            else if(uiwndpMOVE_BY_SURFACE in wnd.Properties) and (uiWindow.MoveOnlyByTitle)  then
               ok := true;

            if(ok) then
               operation := uiWINDOW_POINTER_MOVE;
         end;
      end;
   end;

   {set pointer}
   if(operation in [uiWINDOW_POINTER_SIZE_BOTTOM, uiWINDOW_POINTER_SIZE_TOP]) then
      uiCursor.SetCursorType(uiCURSOR_TYPE_RESIZE_TB)
   else if(operation in [uiWINDOW_POINTER_SIZE_LEFT, uiWINDOW_POINTER_SIZE_RIGHT]) then
      uiCursor.SetCursorType(uiCURSOR_TYPE_RESIZE_LR)
   else if(operation = uiWINDOW_POINTER_SIZE_TL) then
      uiCursor.SetCursorType(uiCURSOR_TYPE_RESIZE_TL)
   else if(operation = uiWINDOW_POINTER_SIZE_TR) then
      uiCursor.SetCursorType(uiCURSOR_TYPE_RESIZE_TR)
   else if(operation = uiWINDOW_POINTER_SIZE_BL) then
      uiCursor.SetCursorType(uiCURSOR_TYPE_RESIZE_BL)
   else if(operation = uiWINDOW_POINTER_SIZE_BR) then
      uiCursor.SetCursorType(uiCURSOR_TYPE_RESIZE_BR);

   if(ok) then begin
      oxui.WindowMove.Assign(p.x, p.y);

      oxui.PointerCapture.Typ := uiPOINTER_CAPTURE_WND_OPERATIONS;
      oxui.PointerCapture.WindowOperation := operation;
      oxui.PointerCapture.Wnd := wnd;
      oxui.PointerCapture.LockWindow();
      oxui.PointerCapture.Point.Assign(p);
   end else
      {if window not captured then send events to window}
      NotifyEvent();
end;

procedure ProcessWindow();
var
   ok: boolean;
   wnd: uiTWindow;

begin
   ok := false;

   if(m.Button.IsSet(appmcRIGHT)) then begin
      if(m.Action.IsSet(appmcRELEASED)) then begin
         wnd := uiTWindow(oxui.mSelect.GetSelectedWnd());

         if(wnd <> nil) and (inTitle(wnd)) then
            ok := true;

         if(ok) and (OpenContextWindow <> nil) then
            OpenContextWindow(wnd);
      end;
   end;

   if(not ok) then
      TryCaptureWindow();
end;

begin
   if(event.evID <> appMOUSE_EVENT) then
      exit;

   if(oxui = nil) then
      oxui := oxuUI.oxui;

   oxui.mLastEventTime := TTimer.Current();
   m := appTMouseEvent(event.GetData()^);

   p.x := round(m.x);
   p.y := round(m.y);

   if(event.wnd = nil) then
      event.wnd := oxWindow.Current;

   uiwnd := oxTWindow(event.wnd);

   {get the previous selected window and mouse selected window}
   pWindow := oxui.Select.GetSelectedWnd();
   pmWindow := oxui.mSelect.GetSelectedWnd();

   {get previous selected widget and mouse selected widget}
   pWidget := oxui.Select.GetSelectedWdg();
   pmWidget := oxui.mSelect.GetSelectedWdg();
   pmSelect := oxui.mSelect;

   {find the window the pointer is above}
   {if a window was specified}
   if(uiwnd <> nil) then
      uiwnd.Find(p.x, p.y, oxui.mSelect);

   if(oxui.mSelect.Selected <> nil) then
      uiCursor.SetCursorType(oxui.mSelect.Selected);

   {if there is a window movement capture then control it}
   if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_WND_OPERATIONS) then begin
      WindowOperations();
      exit;
   end else if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_WIDGET) then begin
      if(WidgetCapture()) then
         exit();
   end else if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_WINDOW) then begin
      if(WindowCapture()) then
         exit();
   end;

   {if the windows are different we need to notify them}
   if(pmWindow <> oxui.mSelect.GetSelectedWnd()) then begin
      if(pmWindow <> nil) then
         pmWindow.Notification(uiWINDOW_NO_HOVER);

      if(oxui.mSelect.GetSelectedWnd() <> nil) then
         oxui.mSelect.GetSelectedWnd().Notification(uiWINDOW_HOVER);
   end;

   {notify of hovering}
   NotifyHover();

   {if a button was pressed}
   if(m.Action <> appmcMOVED) then begin
      {add current event}
      uiPointer.AddEvent(oxui.mSelect.Selected, m);

      changeSelect := nil;

      {If the previously seleceted window is not the one currently selected.}
      if(pWindow <> oxui.mSelect.GetSelectedWnd()) then begin
         {remember our initial selection, if the selected/unselected window changes it}
         changeSelect := oxui.mSelect.GetSelectedWnd();

         {select new window}
         if(oxui.mSelect.GetSelectedWnd() <> nil) then
            oxui.mSelect.GetSelectedWnd().Select();

         oxui.mSelectHoverTime := TTimer.Current();
      end;

      {widget selection changed (changed to other widget, window, ...)}
      if(oxui.mSelect.GetSelectedWdg() <> pWidget) and
         {this check is because window selection can change above}
         ((changeSelect = nil) or (changeSelect = oxui.Select.GetSelectedWnd())) then begin
         if(pWidget <> nil) then
            pWidget.Deselected();

         if(oxui.mSelect.Selected <> nil) then begin
            if(oxui.mSelect.Selected.ControlType = uiCONTROL_WIDGET) then
               uiTWidget(oxui.mSelect.Selected).Select()
            else
               oxui.Select.Assign(oxui.mSelect.Selected);
         end;
      end;

      {if no widget was selected then we clicked onto a window,
      let's see if we got a window move lock.}
      if(oxui.Select.GetSelectedWdg() = nil) then
         ProcessWindow()
      else begin
         if(wdgpSELECTABLE in oxui.Select.GetSelectedWdg().Properties) or (wdgpNON_CLIENT in oxui.Select.GetSelectedWdg().Properties) then
            PointEvent(oxui.Select.GetSelectedWdg())
         else
            ProcessWindow();
      end;
   end else
      ProcessWindow();
end;


INITIALIZATION
   oxGlobalInstances.Add('uiTPointerEventsGlobal', @uiPointerEvents);

END.
