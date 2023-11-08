{
   oxuX11Platform, oX X11 platform
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuX11Platform;

INTERFACE

   USES
      uStd, uError, uLog, StringUtils,
      x, xlib, xutil, xkb, xkblib, cursorfont,
      {app}
      uAppInfo,
      appuInputTypes, appuKeys, appuEvents, appuKeyEvents, appuMouse, appuMouseEvents,
      {oX}
      oxuTypes, oxuWindowTypes, oxuWindows, oxuWindow, oxuWindowHelper,
      oxuPlatform, oxuPlatforms, oxuRenderer,
      oxuGlobalInstances, uiuWindowTypes,
      {ui}
      uiuWindow, uiuTypes;

TYPE
   PXAttrInt      = ^XAttrInt;
   XAttrInt       = longint;

   x11TWindow = class(oxTWindow)
      wd: record
         LastError: longint;
         VisInfo: PXVisualInfo;
         wAttr: TXSetWindowAttributes;

         h: x.TWindow;
      end;
   end;

   TX11PointerDriver = class(appTPointerDriver)
      constructor Create();

      procedure GetXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure SetXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure Hide(devID: longint; {%H-}wnd: pointer); override;
      procedure Show(devID: longint; {%H-}wnd: pointer); override;
   end;

   { oxTX11Platform }

   oxTX11Platform = class(oxTPlatform)
      {has the display been opened}
      DisplayOpened: boolean;
      {display}
      DPY: PDisplay;
      {screen}
      Screen: PScreen;
      {last X error}
      LastError: TXErrorEvent;
      LastErrorDescription: string;

      Cursors: record
         Normal,
         Input,
         Busy,
         Denied,
         Hand,
         ResizeTB,
         ResizeLR,
         ResizeTRBL,
         ResizeTLBR,
         ResizeTL,
         ResizeTR,
         ResizeBL,
         ResizeBR: x.TCursor;
      end;

      constructor Create(); override;

      function Initialize(): boolean; override;
      function DeInitialize(): boolean; override;
      function MakeWindow(window: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;
      procedure ProcessEvents(); override;

      procedure SetTitle(wnd: oxTWindow; const newTitle: StdString); override;

      procedure Move(wnd: oxTWindow; x, y: longint); override;
      procedure Resize(wnd: oxTWindow; w, h: longint); override;

      procedure OutClientAreaCoordinates({%H-}wnd: oxTWindow; out x, y: single); override;

      procedure XSetSizeHint(wnd: oxTWindow; flags: longint = PMinSize or PMaxSize);

      procedure LoadCursor(var c: x.TCursor; shape: LongWord);
      procedure LoadCursor(cursorType: uiTCursorType); override;
      procedure SetCursor(cursor: TCursor);
      procedure SetCursor(cursorType: uiTCursorType); override;

      class procedure LogError(error: longint); static;
      {get the last error}
      function GetError(doDumpCallStack: boolean = true): longint;

      protected
         function OpenDisplay(): boolean;
   end;

VAR
   x11: oxTX11Platform;

IMPLEMENTATION

   USES appukXCodes;

VAR
   wmDeleteMessage: TAtom;

{ HELPERS }
function findWnd(h: int64): oxTWindow;
var
   i: longint;

begin
   if(oxWindows.n > 0) then
      for i := 0 to (oxWindows.n - 1) do begin
         if(x11TWindow(oxWindows.w[i]).wd.h = h) then
            exit(oxWindows.w[i]);
      end;

   Result := nil;
end;


{ X11 DISPLAY }

VAR
   DisplayNotOpenedLogged: boolean = false;

{log down that the x server display is not opened}
procedure LogDisplayNotOpened();
begin
   if(DisplayNotOpenedLogged = false) then begin
      log.w('X11 > X Server display not opened.');

      DisplayNotOpenedLogged := true;
   end;
end;

VAR
   modifiers: record
      alt,
      altgr,
      numlock,
      scroll: longword;
   end;

{ EVENTS }
constructor oxTX11Platform.Create();
begin
   inherited;

   Name := 'X11';
   x11 := Self;
end;

{display	Specifies the connection to the X server.
event_return	Returns the next event in the queue.}

{process X11 messages}
procedure oxTX11Platform.ProcessEvents();
var
   event: TXEvent;
   eventCount,
   currentEvent: loopint;
   key: appTKey;
   wnd: oxTWindow       = nil;
   keysym: longword;
   wndh: int64;
   m, lastM: appTMouseEvent;

procedure MouseEventDone();
var
   appEvent: appPEvent;

begin
   if(lastM.Action <> 0) then begin
      appEvent := appMouseEvents.Queue(lastM);
      appEvent^.wnd := wnd;
      lastM.Action := 0;
   end;
end;

procedure PushMouseEvent();
begin
   if((m.Action <> lastM.Action) or (lastM.Button <> m.Button) or (m.devID <> lastM.devID)) and (lastM.Action <> 0) then
      MouseEventDone();

   lastM := m;
   m.Action := 0;
end;

procedure SetMouseButtonState(state: longword);
begin
   if(state and Button1Mask > 0) then
      m.bState := m.bState or appmc1;

   if(state and Button3Mask > 0) then
      m.bState := m.bState or appmc2;

   if(state and Button2Mask > 0) then
      m.bState := m.bState or appmc3;

   if(state and Button4Mask > 0) then
      m.bState := m.bState or appmc4;

   if(state and Button5Mask > 0) then
      m.bState := m.bState or appmc5;
end;

procedure SetMouseButton(button: longword);
begin
   if(button = Button1) then
      m.Button := appmc1;

   if(button = Button3) then
      m.Button := appmc2;

   if(button = Button2) then
      m.Button := appmc3;

   if(button = Button4) then
      m.Button := appmc4;

   if(button = Button5) then
      m.Button := appmc5;
end;

procedure MouseHandle();
begin
   {set the event position}
   m.x   := event.xbutton.x;
   m.y   := wnd.Dimensions.h - 1 - event.xbutton.y;

   {set button state}
   SetMouseButtonState(event.xmotion.state);
   m.bState := m.bState or m.Button;

   {process the event}
   PushMouseEvent();
end;

{handle a button press event}
procedure MouseButtonHandle();
begin
   appm.Init(m);

   {check if this is a scroll event}
   if(event.xbutton.state and Button4Mask > 0) then begin
      m.Action := appmcWHEEL;
      m.Value  := 1;
   end;

   if(event.xbutton.state and Button5Mask > 0) then begin
      m.Action := appmcWHEEL;
      m.Value  := -1;
   end;

   {set event action, if not determined it's a scroll action already}
   if(m.Action <> appmcWHEEL) then begin
      if(event._type = x.ButtonPress) then
         m.Action := appmcPRESSED
      else if(event._type = x.ButtonRelease) then
         m.Action  := appmcRELEASED;
   end else begin
      {ignore one scroll event so we don't have two scroll events,
      since X gives both press and release events for single scroll}
      if event._type = x.ButtonPress then
         exit;
   end;

   {set button state}
   SetMouseButton(event.xbutton.button);

   MouseHandle();
end;

{handle a motion or button press/release event}
procedure MotionHandle();
begin
   appm.Init(m);

   {set event action}
   m.Action := appmcMOVED;

   MouseHandle();
end;

{handle a key event}
procedure KeyHandle();
var
   appEvent: appTEvent;
   kEvent: appTKeyEvent;
   nev: TXEvent;
   ev: appPEvent;

begin
   appk.Init(key);

   {get the keysym for this keycode}
   keysym := XKeycodeToKeysym(x11.DPY, event.xkey.Keycode, 0);

   {try to remap the keysym to a dApp KeyCode}
   if(keysym >= XK_MISC_START) and (keysym <= XK_MISC_END) then
      key.Code := xkcMiscRemaps[keysym - $FF00]
   else if(keysym >= XK_LATIN_START) and (keysym <= XK_LATIN_END) then
      key.Code := xkcLatinRemaps[keysym - $FE00];

   if(key.Code > 255) then
      key.Code := 0;

   {if keysym remapping failed then let's try keycode remapping}
   if(event.xkey.keycode <= 255) and (key.Code = 0) then
      key.Code := appkRemapCodes[event.xkey.keycode];

   if(key.Code <> 0) then begin
      key.State := 0;

      appk.Modifiers.Prop(kmSHIFT, event.xkey.state and ShiftMask > 0);
      appk.Modifiers.Prop(kmCONTROL, event.xkey.state and ControlMask > 0);
      appk.Modifiers.Prop(kmALT, event.xkey.state and modifiers.alt > 0);
      appk.Modifiers.Prop(kmALTGR, event.xkey.state and modifiers.altgr > 0);
      appk.Modifiers.Prop(kmCAPS, event.xkey.state and LockMask > 0);
      appk.Modifiers.Prop(kmNUM, event.xkey.state and modifiers.numlock > 0);
      appk.Modifiers.Prop(kmSCROLL, event.xkey.state and modifiers.scroll > 0);

      {set the up/down state}
      if(event._type = x.KeyPress) then
         key.State.Prop(kmDOWN);

      {check if we have gotten an auto (fake) release (because X does this for reasons)}
      if(event._type = x.KeyRelease) and (XEventsQueued(DPY, QueuedAfterReading) > 0) then begin
         XPeekEvent(DPY, @nev);

         if(nev._type = x.KeyPress) and (nev.xkey.time = event.xkey.time) and (nev.xkey.keycode = event.xkey.keycode) then begin
            {just ignore the next event}
            XNextEvent(DPY, @nev);

            key.State.Prop(kmDOWN);
         end;
      end;

      appEvents.Init(appEvent, appKEY_EVENT, @appKeyEvents.evh);
      appk.Init(kEvent);
      kEvent.Key := key;
      appEvent.ExternalData := @kEvent;
      appEvent.wnd := wnd;

      ev := appKeyEvents.Queue(key);
      ev^.wnd := wnd;
   end;
end;

{handle regained keyboard focus}
procedure FocusInHandle();
var
   state: TXkbStateRec;

begin
   XkbGetState(x11.DPY, xkbUSeCoreKbd, @state);

   if(state.mods and ShiftMask = 0) then begin
      appk.Properties[kcLSHIFT].Clear(kpPRESSED);
      appk.Properties[kcRSHIFT].Clear(kpPRESSED);

      appk.Modifiers.Clear(kmSHIFT);
   end else
      appk.Modifiers.Prop(kmSHIFT);

   if (state.mods and modifiers.alt = 0)  then begin
      appk.Properties[kcLALT].Clear(kpPRESSED);
      appk.Properties[kcRALT].Clear(kpPRESSED);

      appk.Modifiers.Clear(kmALT);
   end else
      appk.Modifiers.Prop(kmALT);

   if (state.mods and ControlMask = 0)  then begin
      appk.Properties[kcLCTRL].Clear(kpPRESSED);
      appk.Properties[kcRCTRL].Clear(kpPRESSED);

      appk.Modifiers.Clear(kmCONTROL);
   end else
      appk.Modifiers.Prop(kmCONTROL);

   if (state.mods and modifiers.numlock = 0)  then begin
      appk.Properties[kcNUMLOCK].Clear(kpPRESSED);

      appk.Modifiers.Clear(kmNUM);
   end else
      appk.Modifiers.Prop(kmNUM);

   if (state.mods and LockMask = 0)  then begin
      appk.Properties[kcCAPSLOCK].Clear(kpPRESSED);

      appk.Modifiers.Clear(kmCAPS);
   end else
      appk.Modifiers.Prop(kmCAPS);

   if (state.mods and modifiers.scroll = 0)  then begin
      appk.Properties[kcSCROLLLOCK].Clear(kpPRESSED);

      appk.Modifiers.Clear(kmSCROLL);
   end else
      appk.Modifiers.Prop(kmSCROLL);
end;

procedure handleConfigure();
begin
   if(wnd <> nil) then begin
      {window moved}
      if(wnd.position.x <> event.xconfigure.x) or (wnd.position.y <> event.xconfigure.y) then
         wnd.SetPosition(event.xconfigure.x, event.xconfigure.y, false);

      {window resized}
      if(wnd.dimensions.w <> event.xconfigure.width) or (wnd.dimensions.h <> event.xconfigure.height) then
         wnd.SetDimensions(event.xconfigure.width, event.xconfigure.height, false);
   end;
end;

begin
   lastM.Action := 0;

   {if the display is not opened then exit}
   if(not x11.DisplayOpened) then begin
      LogDisplayNotOpened();
      exit;
   end;

   {process all events}
   eventCount := XPending(x11.DPY);

   FocusInHandle();

   if(eventCount > 0) then
   for currentEvent := 0 to (eventCount - 1) do begin;
      m.Action := 0;
      XNextEvent(x11.DPY, @event); {get the next event}

      {find window with associated with the event}
      wndh  := int64(event.xany.window);
      wnd   := findWnd(wndh);

      {process event by type}
      case event._type of
         x.Expose:;
         x.ConfigureRequest:;
         x.ConfigureNotify:   handleConfigure(); {window size changed}

         x.KeyPress,
         x.KeyRelease:        KeyHandle(); {key pressed or released}

         x.ButtonPress,
         x.ButtonRelease:     MouseButtonHandle();

         x.MotionNotify:      MotionHandle(); {pointer event}
         x.CreateNotify:;
         x.DestroyNotify:;
         x.FocusIn:
            FocusInHandle();
         x.FocusOut:;
         x.ClientMessage: begin
            if(wnd <> nil) then begin
               if(int64(event.xclient.data.l[0]) = int64(wmDeleteMessage)) then
                  wnd.Close();
            end;
         end;
      end;
   end;

   if(lastM.Action <> 0) then
      MouseEventDone();
end;

procedure oxTX11Platform.SetTitle(wnd: oxTWindow; const newTitle: StdString);
var
   xwnd: x11TWindow;

begin
   xwnd := x11TWindow(wnd);

   XStoreName(x11.DPY, xwnd.wd.h, PChar(newTitle));
end;

{ WINDOW }

function oxTX11Platform.MakeWindow(window: oxTWindow): boolean;
var
   Window_title_property: TXTextProperty;
   title: StdString;
   cm: TColormap;

   wnd: x11TWindow;

   classHint: TXClassHint;
   screenIndex: longint;
   depth: longint = 0;
   visual: PVIsual = nil;
   left, top: longint;

begin
   Result := false;

   {create window data}
   wnd := x11TWindow(window);

   if(DisplayOpened) then begin
      {initialize OpenGL for window}
      if(oxTRenderer(wnd.Renderer).PreInitWindow(wnd) = false) then begin
         Log.e('Renderer window pre init failed.');
         exit;
      end;

      {if successful then continue creating the window}
      if(wnd.wd.VisInfo <> nil) then begin
         screenIndex := wnd.wd.VisInfo^.screen;
         depth := wnd.wd.VisInfo^.depth;
         visual := wnd.wd.VisInfo^.visual;

         {create a colormap and assign it}
         cm := XCreateColormap(DPY, RootWindow(DPY, screenIndex), visual, AllocNone);
         wnd.wd.wAttr.colormap := cm;
      end else begin
         wnd.CreateFail('x11 > No visual created by the renderer');
         exit(false);
      end;

      {assign window attributes}
      wnd.wd.wAttr.border_pixel        := 0;
      wnd.wd.wAttr.background_pixel    := 0;
      wnd.wd.wAttr.event_mask          := ExposureMask or ClientMessage
         or StructureNotifyMask or SubstructureNotifyMask
         {keys}
         or KeyPressMask or KeyReleaseMask
         {mouse buttons and pointer}
         or PointerMotionMask or ButtonPressMask or ButtonReleaseMask
         or Button1MotionMask or Button2MotionMask or Button3MotionMask
         or Button4MotionMask or Button5MotionMask
         or FocusChangeMask;

      if(uiwndpAUTO_CENTER in wnd.Properties) then begin
         left := WidthOfScreen(Screen) div 2 - wnd.Dimensions.w div 2;
         top := HeightOfScreen(Screen) div 2 - wnd.Dimensions.h div 2;

         {correct position}
         wnd.Position.x := left;
         wnd.Position.y := top;
      end;

      {Create the window}
      wnd.wd.h := XCreateWindow(DPY,
            RootWindow(DPY, screenIndex),
            wnd.Position.x,
            wnd.Position.y,
            wnd.Dimensions.w,
            wnd.Dimensions.h,
            0,
            depth,
            InputOutput,
            visual,
            CWBorderPixel or CWColormap or CWEventMask,
            @wnd.wd.wAttr
      );

      {make sure we are notified about deleting the window}
      wmDeleteMessage := XInternAtom(DPY, 'WM_DELETE_WINDOW', false);
      XSetWMProtocols(DPY, wnd.wd.h, @wmDeleteMessage, 1);

      {Set the window title}
      title := wnd.Title;
      XStringListToTextProperty(@title, 1, @window_title_property);
      XSetWMName(DPY, TWindow(wnd.wd.h), @window_title_property);

      XFree(Window_title_property.value);

      classHint.res_name := PChar(appInfo.name);
      classHint.res_class := PChar(wnd.Title);
      XSetClassHint(DPY, TWindow(wnd.wd.h), @classHint);

      {initialize renderer for window}
      if(oxTRenderer(wnd.Renderer).InitWindow(wnd) = false) then begin
         Log.e('Renderer window create failed.');
         exit;
      end;

      {map the window onto the display}
      XMapWindow(DPY, TWindow(wnd.wd.h));

      {because X11 takes window position at creation as only a hint, move to the wanted position}
      XMoveWindow(DPY, wnd.wd.h, wnd.Position.x, wnd.Position.y);

      {disable resizing if indicated as so}
      if(not (uiwndpRESIZABLE in wnd.Properties)) then
         XSetSizeHint(wnd);

      {window successfully created}
      Result := true;
   end;
end;

function oxTX11Platform.DestroyWindow(wnd: oxTWindow): boolean;
var
   xwnd: x11TWindow;

begin
   Result := false;
   xwnd := x11TWindow(wnd);

   {initialize OpenGL for window}
   if(oxTRenderer(wnd.Renderer).DeInitWindow(wnd) = false) then
      Log.e('Renderer window de-init failed.');

   if(xwnd.wd.VisInfo <> nil) then begin
      XFree(xwnd.wd.VisInfo);
      xwnd.wd.VisInfo := nil;
   end;

   {destroy color map}
   if(xwnd.wd.wAttr.colormap <> 0) then begin
      XFreeColormap(DPY, xwnd.wd.wAttr.colormap);
      xwnd.wd.wAttr.colormap := 0;
   end;

   {destroy the window and data}
   if(xwnd.wd.h <> 0) then begin
      XDestroyWindow(DPY, xwnd.wd.h);
      xwnd.wd.h := 0;
   end;

   {finished}
   Result := true;
end;

procedure oxTX11Platform.Move(wnd: oxTWindow; x, y: longint);
var
   error: longint;

begin
   error := XMoveWindow(DPY, x11TWindow(wnd).wd.h, x, y);
   oxTX11Platform.LogError(error);
end;

procedure oxTX11Platform.Resize(wnd: oxTWindow; w, h: longint);
var
   error: longint;

begin
   {make temporarily resizable}
   if(not (uiwndpRESIZABLE in wnd.Properties)) then
      XSetSizeHint(wnd, 0);

   {resize}
   error := XResizeWindow(DPY, x11TWindow(wnd).wd.h, w, h);
   oxTX11Platform.LogError(error);

   {restore default hint}
   if(not (uiwndpRESIZABLE in wnd.Properties)) then
      XSetSizeHint(wnd);
end;

procedure oxTX11Platform.OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single);
begin
   x := 0;
   y := 0;
end;

procedure oxTX11Platform.XSetSizeHint(wnd: oxTWindow; flags: longint);
var
   sizeHints: TXSizeHints;

begin
   ZeroOut(sizeHints, SizeOf(sizeHints));
   sizeHints.flags := sizeHints.flags or flags;

   sizeHints.min_width := wnd.Dimensions.w;
   sizeHints.min_height := wnd.Dimensions.h;
   sizeHints.max_width := wnd.Dimensions.w;
   sizeHints.max_height := wnd.Dimensions.h;

   XSetWMNormalHints(DPY, x11TWindow(wnd).wd.h, @sizeHints);
end;

procedure oxTX11Platform.LoadCursor(var c: x.TCursor; shape: LongWord);
begin
   c := XCreateFontCursor(DPY, shape);
end;

procedure oxTX11Platform.LoadCursor(cursorType: uiTCursorType);
begin
   if(cursorType = uiCURSOR_TYPE_NORMAL) or (cursorType = uiCURSOR_TYPE_DEFAULT) then
      LoadCursor(Cursors.Normal, XC_arrow)
   else if(cursorType = uiCURSOR_TYPE_INPUT) then
      LoadCursor(Cursors.Input, XC_xterm)
   else if(cursorType = uiCURSOR_TYPE_BUSY) then
      LoadCursor(Cursors.Busy, XC_watch)
   else if(cursorType = uiCURSOR_TYPE_DENIED) then
      LoadCursor(Cursors.Denied, XC_X_cursor)
   else if(cursorType = uiCURSOR_TYPE_HAND) then
      LoadCursor(Cursors.Hand, XC_hand1)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TB) then
      LoadCursor(Cursors.ResizeTB, XC_double_arrow)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_LR) then
      LoadCursor(Cursors.ResizeLR, XC_sb_h_double_arrow)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TLBR) then
      LoadCursor(Cursors.ResizeTLBR, XC_sizing)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TRBL) then
      LoadCursor(Cursors.ResizeTRBL, XC_sizing)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TL) then
      LoadCursor(Cursors.ResizeTL, XC_top_left_corner)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TR) then
      LoadCursor(Cursors.ResizeTR, XC_top_right_corner)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_BL) then
      LoadCursor(Cursors.ResizeBL, XC_bottom_left_corner)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_BR) then
      LoadCursor(Cursors.ResizeBR, XC_bottom_right_corner);
end;

procedure oxTX11Platform.SetCursor(cursor: TCursor);
begin
   if(oxWindow.Current <> nil) then
      XDefineCursor(DPY, x11TWindow(oxWindow.Current).wd.h, cursor);
end;

procedure oxTX11Platform.SetCursor(cursorType: uiTCursorType);
begin
   if(cursorType = uiCURSOR_TYPE_DEFAULT) or (cursorType = uiCURSOR_TYPE_NORMAL) then
      SetCursor(Cursors.Normal)
   else if(cursorType = uiCURSOR_TYPE_INPUT) then
      SetCursor(Cursors.Input)
   else if(cursorType = uiCURSOR_TYPE_BUSY) then
      SetCursor(Cursors.Busy)
   else if(cursorType = uiCURSOR_TYPE_DENIED) then
      SetCursor(Cursors.Denied)
   else if(cursorType = uiCURSOR_TYPE_HAND) then
      SetCursor(Cursors.Busy)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TB) then
      SetCursor(Cursors.ResizeTB)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_LR) then
      SetCursor(Cursors.ResizeLR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TLBR) then
      SetCursor(Cursors.ResizeTLBR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TRBL) then
      SetCursor(Cursors.ResizeTRBL)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TL) then
      SetCursor(Cursors.ResizeTL)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_TR) then
      SetCursor(Cursors.ResizeTR)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_BL) then
      SetCursor(Cursors.ResizeBL)
   else if(cursorType = uiCURSOR_TYPE_RESIZE_BR) then
      SetCursor(Cursors.ResizeBR)
   else
      SetCursor(Cursors.Normal);
end;

function XErrorHandler(display: PDisplay; error: PXErrorEvent): longint; cdecl;
var
   errorString: array[0..4095] of char;

begin
   XGetErrorText(display, error^.error_code, @errorString, 4096);

   x11.LastError := error^;
   x11.LastErrorDescription := pchar(errorString);

   log.e('X11 > Error (' + sf(error^.error_code) +', ' + sf(error^.request_code) + ', ' + sf(error^.minor_code) + ') ' +
      x11.LastErrorDescription);

   exit(-1);
end;

{ INITIALIZATION/DEINITIALIZATION }

function oxTX11Platform.Initialize(): boolean;
begin
   XSetErrorHandler(@XErrorHandler);

   { pointer driver }
   PointerDriver := TX11PointerDriver.Create();

   {open the display for X11}
   if(OpenDisplay()) then
      Result := true
   else begin
      log.f('X11 > Fatal: Failed to open display.');
      Result := false;
   end;
end;

procedure UnloadCursor(var cursor: x.TCursor);
begin
   if(cursor <> 0) then begin
      XFreeCursor(x11.DPY, cursor);
      cursor := 0;
   end;
end;

function oxTX11Platform.DeInitialize(): boolean;
begin
   {destroy cursors}
   UnloadCursor(Cursors.Normal);
   UnloadCursor(Cursors.Input);
   UnloadCursor(Cursors.Busy);
   UnloadCursor(Cursors.Denied);
   UnloadCursor(Cursors.Hand);
   UnloadCursor(Cursors.ResizeTB);
   UnloadCursor(Cursors.ResizeLR);
   UnloadCursor(Cursors.ResizeTRBL);
   UnloadCursor(Cursors.ResizeTLBR);
   UnloadCursor(Cursors.ResizeTL);
   UnloadCursor(Cursors.ResizeTR);
   UnloadCursor(Cursors.ResizeBL);
   UnloadCursor(Cursors.ResizeBR);

   {close the display}
   if(DPY <> nil) then begin
      XSetCloseDownMode(DPY, DestroyAll);
      XCloseDisplay(DPY);
      DPY := nil;
      DisplayOpened := false;
   end;

   Result := true;

   if(not Result) then
      log.e('X11 > Fatal: Failed to close display.');
end;

class procedure oxTX11Platform.LogError(error: longint);
begin
   if(error = BadValue) then
      log.e('X11 > returned bad value')
   else if(error = BadWindow) then
      log.w('X11 > XMoveResizeWindow returned bad window');
end;

function oxTX11Platform.GetError(doDumpCallStack: boolean): longint;
begin
   Result := LastError.error_code;

   if(doDumpCallStack) and (Result <> 0) then
      DumpCallStack(1);

   LastError.error_code := 0;
end;

function oxTX11Platform.OpenDisplay(): boolean;
begin
   if(DisplayOpened = false) then begin
      DPY := XOpenDisplay(nil);

      if(DPY <> nil) then begin
         Screen := DefaultScreenOfDisplay(DPY);
         DisplayOpened := true;
      end else
         log.e('X11 > Cannot open X server display.');
   end;

   Result := DisplayOpened;
end;

{ POINTER DRIVER }

constructor TX11PointerDriver.Create();
begin
   Name := 'x11';
end;

procedure TX11PointerDriver.GetXY(devID: longint; wnd: pointer; out x, y: single);
var
   root,
   child: pointer;
   root_x,
   root_y,
   win_x,
   win_y: longint;
   mask: longword;

   wndh: int64;

begin
   wndh := None;

   if(wnd <> nil) then begin
      wndh := x11TWindow(wnd).wd.h;
   end else
      wndh := XDefaultRootWindow(x11.DPY);

   XQueryPointer(x11.DPY, wndh, @root, @child, @root_x, @root_y, @win_x, @win_y, @mask);

   x := win_x;
   y := win_y;
end;

procedure TX11PointerDriver.SetXY(devID: longint; wnd: pointer; x, y: single);
var
   oxwnd: oxTWindow = nil;
   pos: oxTPoint;

   root_window: TXID;

begin
   root_window := XDefaultRootWindow(x11.DPY);

   {no window specified, absolute}
   if(wnd = nil) then begin
      pos.x    := round(x);
      pos.y    := round(y);
   {set pointer relative to window client position}
   end else begin
      oxwnd    := oxTWindow(wnd);

      pos.x    := oxwnd.position.x;
      pos.y    := oxwnd.position.y;

      inc(pos.x, round(x));
      inc(pos.y, round(y));
   end;

   XWarpPointer(x11.DPY, root_window, root_window, {src_x}0, {src_y}0, {src_width}0, {src_height}0, pos.x, pos.y);
   XFlush(x11.DPY);
end;

procedure TX11PointerDriver.Show(devID: longint; wnd: pointer);
begin
   inc(appm.pointer[devID].shown);
end;

procedure TX11PointerDriver.Hide(devID: longint; wnd: pointer);
begin
   dec(appm.pointer[devID].shown);
end;

procedure onReferenceChange(const instanceType: StdString; {%H-}reference: pointer);
begin
   if(instanceType = 'oxTPlatform') then
      x11 := oxTX11Platform(oxPlatform)
end;

INITIALIZATION
   oxPlatforms.Register(oxTX11Platform);
   oxGlobalInstances.OnReferenceChange.Add(@onReferenceChange);

   modifiers.alt := Mod1Mask;
   modifiers.altgr := Mod5Mask;
   modifiers.numlock := Mod2Mask;
   modifiers.scroll := 0;

END.
