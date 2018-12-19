{
   uiuKeyEvents, UI key event management
   Copyright (C) 2011. Dejan Boras

   Started On:    23.04.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuKeyEvents;

INTERFACE

   USES
      uStd,
      {app}
      appuEvents, appuKeys, appuKeyEvents, appuKeyMappings,
      {oX}
      oxuWindowTypes, oxuGlobalInstances,
      {ui}
      uiuWindowTypes, uiuWindow, uiuWidget, uiuTypes, uiWidgets, oxuUI, uiuControl;

TYPE
   uiTKeyEventsGlobal = record
      function Action(oxui: oxTUI; var event: appTEvent): boolean;
   end;

VAR
   uiKeyEvents: uiTKeyEventsGlobal;

IMPLEMENTATION

TYPE
   TData = record
      wnd: uiTWindow;
      wdg: uiTWidget;
      KeyEvent: appTKeyEvent;
      Key: appTKey;
   end;

function wndHandler(wnd: uiTWindow; evID: uiTWindowEvents): longint;
var
   event: appTEvent;

begin
   Result := -1;

   event.wnd   := wnd;
   event.evID  := longword(evID);
   event.hID   := uievhpWINDOW;

   if(wnd.wHandler <> nil) then
      Result := wnd.wHandler(wnd, event);

   wnd.Action(evID);
end;

{this routine processes key events in case no widget or window intercepted the key}
function keyProcess(wnd: uiTWindow; var d: TData): boolean;
begin
   Result := false;

   case d.Key.Code of
      kcTAB: begin
         if(d.Key.Released()) then begin
            {shift+tab}
            if(d.Key.State.IsSet(kmSHIFT)) then
               uiWidget.SelectPrevious(wnd)
            {tab}
            else
               uiWidget.SelectNext(wnd);
         end;

         Result := true;
      end;
      else begin
         if((uiwndpNO_ESCAPE_KEY in wnd.Properties)) and (uiWindow.EscapeKeys.Find(d.Key) <> nil) then begin
            exit(true);
         end;

         {check for escape key}
         if(not (uiwndpNO_ESCAPE_KEY in wnd.Properties)) and (uiWindow.EscapeKeys.Find(d.Key) <> nil) then begin
            if(d.Key.Released()) then begin
               if(wndHandler(wnd, uiWINDOW_CLOSE_ON_ESCAPE) = -1) then
                  wnd.Close();
            end;

            Result := true;
         {check for confirmation key}
         end else if(uiWindow.ConfirmationKeys.Find(d.Key) <> nil) then begin
            if(d.Key.Released()) then;
            {TODO: Find default confirmation action, and react on it}
         end else if(d.Key = uiWindow.CloseKey) and (wnd.Parent <> nil) then begin
            if(d.Key.Released()) then
               wnd.CloseQueue();

            Result := true;
         end;

         if(not Result) and (wnd.Parent <> nil) then
            keyProcess(uiTWindow(wnd.Parent), d);
      end;
   end;
end;

function uiTKeyEventsGlobal.Action(oxui: oxTUI; var event: appTEvent): boolean;
var
   d: TData; {data}
   oxwnd: oxTWindow;
   wdg: uiTWidget;

function callWindowHandler(): boolean;
var
   r: longint;
   curWnd: uiTWindow;

begin
   r := -1;

   curWnd := d.wnd;

   if((uiwndpENABLED in curWnd.Properties) and (not (uiwndpCLOSED in curWnd.Properties))) then begin
      if(curWnd.Key(d.KeyEvent)) then
         r := 0;

      if(r = -1) and (curWnd.wHandler <> nil) then
         r := curWnd.wHandler(d.wnd, event);
   end;

   Result := r <> -1;
end;

function callKeyMappings(): boolean;
begin
   Result := appKeyMappings.Call(d.Key) <> nil;
end;

function callFurther(): boolean;
var
   r: boolean;

begin
   {first process standard keys}
   r := keyProcess(d.wnd, d);

   {call window handler}
   if(not r) then begin
      r := callWindowHandler();

      if(not r) then
         r := callKeyMappings();
   end;

   Result := r;
end;

begin
   Result := false;

   {HOW: Keys are first processed by the widget that has focus (selected).
   If no widget is selected then the keys are processed by keyProcess routine.
   If the routine does not process the key, then a key handler will be looked
   up in the global window key handlers table and the handler will be called(
   global window key handlers are yet TODO). If no such handler is found
   then the key is sent to the window handler. If the window does not handle the key,
   then the appropriate key mapping is found}
   if(event.evID = appKEY_EVENT) then begin
      d.KeyEvent  := appTKeyEvent(event.GetData()^);
      d.Key       := d.KeyEvent.Key;
      oxwnd       := oxTWindow(event.wnd);

      d.wnd       := nil;
      event.wnd   := nil;

      {set the UI window as the event window}
      if(oxwnd <> nil) then begin
         d.wnd       := oxwnd;
         event.wnd   := d.wnd;
      end;

      {if the key event specifies no window then find the currently selected one (top parent)}
      if(d.wnd = nil) and(oxui.select.l > -1) then begin
         event.wnd   := oxui.select.s[0];
         d.wnd       := uiTWindow(event.wnd);
         oxwnd       := oxTWindow(d.wnd.oxwParent);
      end;

      {if there is a window selected then}
      if(d.wnd <> nil) then begin
         {use the top window if the current window matches the selected one}
         if(oxui.select.l > -1) and (oxui.select.s[0] = oxwnd) then begin
            event.wnd   := oxui.Select.GetSelectedWnd();
            d.wnd       := uiTWindow(event.wnd);
         end else begin
            exit;
         end;

         {... send the key event to the widget, and if no widget selected to the window}

         {find the selected widget, if any}
         wdg := oxui.Select.GetSelectedWdg();
         d.wdg := wdg;

         {if there is a widget selected}
         if(wdg <> nil) then begin
            {send the key to the widget}
            Result := wdg.Key(d.KeyEvent);

            if(not Result) then
               Result := callFurther();
         {window}
         end else
            Result := callFurther();
      end;
   end;
end;

INITIALIZATION
   oxGlobalInstances.Add('uiTKeyEventsGlobal', @uiKeyEvents);

END.
