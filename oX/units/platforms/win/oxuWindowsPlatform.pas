{
   oxuWindowsPlatform, Windows OS specific functionality
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWindowsPlatform;

INTERFACE

   USES
      uStd, StringUtils, uLog,
      {app}
      appuEvents, appuInputTypes, appuKeys, appuKeyEvents, appuMouse, appuMouseEvents,
      {oX}
      oxuTypes, oxuPaths,
      oxuWindowTypes, oxuWindow, oxuWindows, oxuWindowHelper,
      oxuPlatform, oxuPlatforms,
      oxuWindowsOS, oxuRenderer,
      {ui}
      uiuTypes, uiuWindow, uiuWindowTypes,
      {windows}
      Windows, oxuWindowsPlatformBase;

TYPE
   { oxTWinPointerDriver }

   oxTWinPointerDriver = class(appTPointerDriver)
      constructor Create();

      procedure GetXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure SetXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure Grab({%H-}devID: longint; wnd: pointer); override;
      procedure Release({%H-}devID: longint; {%H-}wnd: pointer); override;
      procedure Hide({%H-}devID: longint; {%H-}wnd: pointer); override;
      procedure Show({%H-}devID: longint; {%H-}wnd: pointer); override;
      function ButtonState({%H-}devID: longint; {%H-}wnd: pointer): longword; override;
   end;

   { oxTWindowsPlatform }

   oxTWindowsPlatform = class(oxTWindowsPlatformBase)
      constructor Create(); override;

      function Initialize(): boolean; override;

      function MakeWindow(wnd: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;
      procedure ProcessEvents(); override;

      function DeInitialize(): boolean; override;

      procedure SetTitle(wnd: oxTWindow; const newTitle: StdString); override;

      function TitleHeight(wnd: oxTWindow): longint; override;
      function FrameWidth(wnd: oxTWindow): longint; override;
      function FrameHeight(wnd: oxTWindow): longint; override;

      procedure ShowWindow(wnd: oxTWindow); override;
      procedure HideWindow(wnd: oxTWindow); override;

      procedure OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single); override;

      function Fullscreen(window: oxTWindow; x, y, bpp: longint): boolean; override;
      function Fullscreen(window: oxTWindow): boolean; override;
      function LeaveFullscreen(window: oxTWindow): boolean; override;

      procedure Move(wnd: oxTWindow; x, y: longint); override;
      procedure Resize(wnd: oxTWindow; w, h: longint); override;

      procedure Maximize(wnd: oxTWindow); override;
      procedure Minimize(wnd: oxTWindow); override;
      procedure Restore(wnd: oxTWindow); override;

      function TranslateKey(const k: appTKeyEvent): char; override;

      procedure GetCenterPosition(wnd: oxTWindow; out p: oxTPoint); override;
      function SetSystemIcon({%H-}wnd: oxTWindow; const {%H-}fn: string): loopint; override;
   end;

IMPLEMENTATION

CONST
   scRSHIFT       = 54;
   scBACKSLASH    = 86;
   scCOMMA        = 51;
   scPERIOD       = 52;
   scLBRACKET     = 26;
   scRBRACKET     = 27;
   scAPOSTROPHE   = 40;
   scSEMICOLON    = 39;
   scSLASH        = 53;

VAR
   {the window in the process of creation}
   wndCreate: oxTWindow = nil;
   {windows messages}
   WinMsg: MSG;

   {mouse button state}
   mButtonState: longword;
   mWheelDelta: loopint;

   pendingResetKeys: boolean = false;

{ KEY }
procedure resetKeys();
var
   kbState: TKeyboardState;
   i: loopint;

begin
   kbState[0] := 0;
   GetKeyboardState(kbState);

   for i := 0 to high(kbState) do begin
      if(appkRemapCodes[i] <> 0) then begin
         appk.Properties[appkRemapCodes[i]].Prop(kpPRESSED, kbState[i] and $80 > 0);
      end;
   end;

   appk.Modifiers.Prop(kmCAPS, kbState[VK_CAPITAL] and $01 <> 0);
   appk.Modifiers.Prop(kmSCROLL, kbState[VK_SCROLL] and $01 <> 0);
   appk.Modifiers.Prop(kmNUM, kbState[VK_NUMLOCK] and $01 <> 0);

   appk.Modifiers.Prop(kmSHIFT, hi(kbState[VK_SHIFT]) <> 0);
   appk.Modifiers.Prop(kmCONTROL, hi(kbState[VK_CONTROL]) <> 0);
   appk.Modifiers.Prop(kmALT, hi(kbState[VK_MENU]) <> 0);

   pendingResetKeys := false;
end;


{ WINDOW }

function findWindow(w: HWND): oxTWindow;
var
  i: longint;

begin
   Result := nil;

   if(oxWindows.n > 0) then begin
     for i := Low(oxWindows.w) to (oxWindows.n - 1) do begin
        if(oxWindows.w[i] <> nil) and (winosTWindow(oxWindows.w[i]).wd.h = w) then
           exit(oxWindows.w[i]);
     end;
   end;
end;

procedure queueKeyEvent(wnd: oxTWindow; AMessage, WParam, LParam: longint);
var
   i,
   rCount,
   scanCode: longint;
   key: appTKey;
   ev: appPEvent;
   extended: boolean;

begin
   if(pendingResetKeys) then
      resetKeys();

   rCount := lo(LParam);

   extended := LParam and (1 shl 24) > 0;
   scanCode := Lo(Hi(LParam));

   {initialize the key}
   ZeroOut(key, SizeOf(key));

   {set the key code}
   if(WParam < 256) then
      key.Code := appkRemapCodes[WParam];

   if(extended) then begin
      if(key.Code = kcLALT) then
         key.Code := kcRALT
      else if(key.Code = kcLCTRL) then
         key.Code := kcRCTRL;
   end;

   if(scanCode = scRSHIFT) then
      key.Code := kcRSHIFT;

   if(scanCode = scBACKSLASH) then
      key.Code := kcBACKSLASH;

   if(scanCode = scCOMMA) then
      key.Code := kcCOMMA;

   if(scanCode = scPERIOD) then
      key.Code := kcPERIOD;

   if(scanCode = scLBRACKET) then
      key.Code := kcLBRACKET;

   if(scanCode = scRBRACKET) then
      key.Code := kcRBRACKET;

   if(scanCode = scAPOSTROPHE) then
      key.Code := kcAPOSTROPHE;

   if(scanCode = scSEMICOLON) then
      key.Code := kcSEMICOLON;

   if(scanCode = scSLASH) then
      key.Code := kcSLASH;

   {set up the up/down state}
   if(AMessage = WM_KEYDOWN) or (AMessage = WM_SYSKEYDOWN) then
      key.State.Prop(kmDOWN);

   {set global modifiers}
   if(key.Code = kcCAPSLOCK) then begin
      if(key.IsPressed()) then
         appk.Modifiers.Toggle(kmCAPS);
   end;

   if(key.Code = kcNUMLOCK) then begin
      if(key.IsPressed()) then
         appk.Modifiers.Toggle(kmNUM);
   end;

   if(key.Code = kmSCROLL) then
      appk.Modifiers.Prop(kmSCROLL, key.IsPressed());

   if(key.Code = kcLSHIFT) or (key.Code = kcRSHIFT) then
      appk.Modifiers.Prop(kmSHIFT, key.IsPressed());

   if(key.Code = kcLCTRL) or (key.Code = kcRCTRL) then
      appk.Modifiers.Prop(kmCONTROL, key.IsPressed());

   if(key.Code = kcLALT) or (key.Code = kcRALT) then
      appk.Modifiers.Prop(kmALT, key.IsPressed());

   if(key.Code = kcRALT) then
      appk.Modifiers.Prop(kmALTGR, key.IsPressed());

   {add the key to the queue only if the key is pressed}
   if(key.Code <> 0) and (rCount > 0) then begin
      for i := 0 to (rCount - 1) do begin
         ev := appKeyEvents.Queue(key);
         appPKeyEvent(ev^.GetData())^.PlatformCode := WParam;
         appPKeyEvent(ev^.GetData())^.PlatformScanCode := scanCode;
         ev^.wnd := wnd;
      end;
   end;
end;

procedure queueMouseEvent(wnd: oxTWindow; wParam, lParam: longint; action, button: longword);
var
   mEvent: appTMouseEvent;
   e: appPEvent;
   delta: loopint;

begin
   if(action = appmcWHEEL) then begin
      delta := SmallInt(Hi(wParam));

      {if change of direction, zero accumulated delta}
      if(delta <= -(WHEEL_DELTA div 2)) and (mWheelDelta > 0) then
         mWheelDelta := 0
      else if(delta >= (WHEEL_DELTA div 2)) and (mWheelDelta < 0) then
         mWheelDelta := 0;

      mWheelDelta := mWheelDelta + delta;

      {wait until we have a WHEEL_DELTA accumulated value}
      if(Abs(mWheelDelta) < WHEEL_DELTA) then
         exit;
   end;

   if(action = appmcPRESSED) then
      mButtonState := mButtonState or button
   else if(action = appmcRELEASED) then
      mButtonState := mButtonState and button xor mButtonState;

   appm.Pointer[0].ButtonState := mButtonState;

   ZeroOut(mEvent, SizeOf(mEvent));
   mEvent.Action := action;
   mEvent.bState := mButtonState;
   mEvent.Button := button;

   if(action <> appmcWHEEL) then begin
      {event coordinates are relative to client area}
      mEvent.x := SmallInt(lo(lParam));
      mEvent.y := wnd.Dimensions.h - 1 - SmallInt(hi(lParam));
   end else begin
      {wheel events have coordinates relative to screen}
      mEvent.x := SmallInt(lo(lParam)) - wnd.Position.x - wnd.GetFrameWidth() + 1;
      mEvent.y := wnd.Dimensions.h - 1 - (SmallInt(hi(lParam)) - wnd.Position.y - wnd.GetNonClientHeight());
   end;

   if(action = appmcWHEEL) then begin
      {count our values}
      mEvent.Value := mWheelDelta div WHEEL_DELTA;

      {remove current delta from accumulated}
      if(mWheelDelta > 0) then
         mWheelDelta := mWheelDelta - abs(mEvent.Value) * WHEEL_DELTA
      else if(mWheelDelta < 0) then
         mWheelDelta := mWheelDelta + abs(mEvent.Value) * WHEEL_DELTA;
   end;

   e := appMouseEvents.Queue(mEvent);
   e^.wnd := wnd;
end;

{process windows window messages}
function WindowsMsgFunc(Window: HWND; AMessage, WParam, LParam: longint): longint; stdcall; export;
var
  wnd: oxTWindow = nil;
  mbts: longword;

begin
   Result := -1;

   wnd := findWindow(Window);

   if(wnd = nil) then
      wnd := wndCreate;

   if (wnd <> nil) then
   case AMessage of
      {destroy the window}
      WM_DESTROY:
         PostQuitMessage(0);

      WM_CLOSE: begin
         wnd.Close();
         exit(1);
      end;

      {window moved}
      WM_MOVE: begin
         if not wnd.IsMinimized() then
         wnd.SetPosition(
            SmallInt(lo(lParam)) - oxPlatform.FrameWidth(wnd),
            SmallInt(hi(lParam)) - oxPlatform.TitleHeight(wnd), false);
      end;

      WM_SIZE:
         if not wnd.IsMinimized() then
            wnd.SetDimensions(lo(LParam), hi(LParam), false);

      {a key has been pressed}
      WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP:
         queueKeyEvent(wnd, AMessage, WParam, LParam);

      {left mouse button}
      WM_LBUTTONDOWN:
         queueMouseEvent(wnd, WParam, LParam, appmcPRESSED, appmcLEFT);

      WM_LBUTTONUP:
         queueMouseEvent(wnd, WParam, LParam, appmcRELEASED, appmcLEFT);

      {right mouse button}
      WM_RBUTTONDOWN:
         queueMouseEvent(wnd, WParam, LParam, appmcPRESSED, appmcRIGHT);

      WM_RBUTTONUP:
         queueMouseEvent(wnd, WParam, LParam, appmcRELEASED, appmcRIGHT);

      {middle mouse button}
      WM_MBUTTONDOWN:
         queueMouseEvent(wnd, WParam, LParam, appmcPRESSED, appmcMIDDLE);

      WM_MBUTTONUP:
         queueMouseEvent(wnd, WParam, LParam, appmcRELEASED, appmcMIDDLE);

      WM_MOUSEWHEEL:
         queueMouseEvent(wnd, WParam, LParam, appmcWHEEL, 0);

      WM_MOUSEMOVE: begin
         mbts := 0;

         if(wParam and MK_LBUTTON > 0) then
            mbts := mbts or appmcLEFT;

         if(wParam and MK_RBUTTON > 0) then
            mbts := mbts or appmcRIGHT;

         if(wParam and MK_MBUTTON > 0) then
            mbts := mbts or appmcMIDDLE;

         queueMouseEvent(wnd, WParam, LParam, appmcMOVED, mbts);
      end;

      WM_SETFOCUS: begin
         resetKeys();
         pendingResetKeys := true;
      end;

      {system command has been issued}
      WM_SYSCOMMAND: begin
         case (wParam) of
            SC_KEYMENU: {don't need windows to handle the F10 key}
               Result := 0;

            SC_SCREENSAVE: {no screen-saver}
               if(oxWindows.AllowScreenSaver) then
                  Result := 0;

            SC_MONITORPOWER: {don't kill monitor power}
               if(oxWindows.AllowScreenSaver) then
                  Result := 0;

            SC_MINIMIZE:
               wnd.Minimize(true);

            SC_MAXIMIZE:
               wnd.Maximize(true);

            SC_RESTORE:
               wnd.Restore(true);
         end;
      end
      else
         Result := -1;
   end;

   {The system should take care of any other messages}
   if(Result = -1) then
      Result := DefWindowProc(Window, AMessage, WParam, LParam);
end;

{ CREATE WINDOW }
var
   hasClass: boolean = false;
   classAtom: windows.ATOM;
   windowClassName: string = 'OX_WD';

function ClassRegister(): boolean;
var
   WindowClass: WndClass;
   error: DWORD;

begin
   error := 0;

   if(not hasClass) then begin
      WindowClass.Style          := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;

      {Handle to our Windows messaging interface function}
      WindowClass.lpfnWndProc    := WndProc(@WindowsMsgFunc);
      WindowClass.cbClsExtra     := 0;
      WindowClass.cbWndExtra     := 0;
      WindowClass.hCursor        := 0;
      WindowClass.hbrBackground  := 0;
      WindowClass.lpszMenuName   := nil;

      {Name the specified window class}
      WindowClass.lpszClassName  := PChar(windowClassName);

      {Get the windows instance for our app}
      WindowClass.hInstance      := system.MainInstance;

      {get window icon}
      WindowClass.hIcon          := LoadIcon(0, IDI_APPLICATION);

      error := GetLastError();

      if(error <> 0) then
         log.w('win-gdi > Failed to create application icon: ' + winos.FormatMessage(error));

      { register the class }

      classAtom := RegisterClass(@WindowClass);

      if(classAtom = 0) then begin
         error := GetLastError();

         if(error <> 0) then
            log.e('win-gdi > Failed to create window class: ' + winos.FormatMessage(error));
      end else
         error := 0;

      hasClass := true;
   end;

   Result := (classAtom <> 0) and (error = 0);
end;

function CreateWindow(window: oxTWindow): HWND;
var
   wStyleEx,
   wStyle: longword;
   error: DWORD;

   framei: longint;
   r: Windows.RECT;
   w,
   h: longint;

   wnd: winosTWindow;

begin
   wnd := winosTWindow(window);

   if (wnd.Frame <> uiwFRAME_STYLE_NONE) then
      framei := 0
   else
      framei := 1;

   {use the style appropriate for the requested frame}
   if (not (uiwndpRESIZABLE in wnd.Properties)) then begin
      wStyle   := wndcFrames[framei].wStyle;
      wStyleEx := wndcFrames[framei].wStyleEx;
   end else begin
      wStyle   := wndcFrames[framei].wsStyle;
      wStyleEx := wndcFrames[framei].wsStyleEx;
   end;

   wStyle := wStyle or WS_MINIMIZEBOX;

   {can have a maximize button only if the window is sizeable}
   if(uiwndpRESIZABLE in wnd.Properties) then
      wStyle := wStyle or WS_MAXIMIZEBOX;

   {set to non visible if not enabled}
   if(not (uiwndpVISIBLE in wnd.Properties)) then
      wStyle := wStyle and WS_VISIBLE xor wStyle;

   wnd.wd.wStyle     := wStyle;
   wnd.wd.wStyleEx   := wStyleEx;

   wndCreate := wnd;

   {adjust dimensions so they are exactly what we want}
   r.Top    := wnd.Position.y;
   r.Left   := wnd.Position.x;
   r.Right  := wnd.Position.x + wnd.Dimensions.w;
   r.Bottom := wnd.Position.y + wnd.Dimensions.h;

   AdjustWindowRectEx(@r, wStyle, FALSE, wStyleEx);

   w := r.Right  - r.Left;
   h := r.Bottom - r.Top;

   {try to center the window on screen}
   if(uiwndpAUTO_CENTER in wnd.Properties) and (not wnd.oxProperties.Context) then begin
      wnd.GetPlatform().GetCenterPosition(wnd, wnd.Position);

      r.Left := wnd.Position.x;
      r.Top := wnd.Position.y;
   end;

   {create the window}
   wnd.wd.h := CreateWindowEx(
      wStyleEx, {extended style}
      PChar(windowClassName), {class name}
      PChar(wnd.Title), {title}
      wStyle, {style}
      r.Left,
      r.Top,
      w,
      h,
      0,
      0,
      system.MainInstance, {instance}
      nil
   );

   if(wnd.wd.h = 0) then begin
      error := GetLastError();

      if (error <> 0) then begin
         wnd.CreateFail('win-gdi > Error(' + sf(error) + '): Cannot create window.');

         if(error = ERROR_CANNOT_FIND_WND_CLASS) then
            wnd.ErrorDescription.Add('Cannot find class: ' + windowClassName);

         wnd.CreateFail('');
      end;
   end;

   wndCreate := nil;

   Result := wnd.wd.h;

   Log.i('Window handle (' + sf(wnd.wd.h) + ')');

   if(not wnd.wd.NoDC) then begin
      wnd.wd.dc := GetDC(wnd.wd.h);
      wnd.wd.LastError := winos.GetLastError();

      if(wnd.wd.LastError <> 0) then
         wnd.CreateFail('win-gdi > Cannot get window DC. ' + winos.FormatMessage(winos.LastError))
      else
         Log.i('Window dc(' + sf(wnd.wd.dc) + ')');
   end;
end;

{ POINTER DRIVER }

{ oxTWinPointerDriver }

constructor oxTWinPointerDriver.Create();
begin
   Name := 'mswin'
end;

procedure oxTWinPointerDriver.GetXY(devID: longint; wnd: pointer; out x, y: single);
var
   p: Windows.POINT = (
      x: 0;
      y: 0
   );

   oxwnd: oxTWindow = nil;

begin
   Windows.GetCursorPos(p);
   x := p.x;
   y := p.y;

   if(wnd <> nil) then begin
      oxwnd := oxTWindow(wnd);

      x     := x - (oxwnd.Position.x + oxPlatform.FrameWidth(oxwnd));
      y     := y - (oxwnd.Position.y + oxPlatform.TitleHeight(oxwnd));

      x     := round(x);
      y     := round(y);
   end;
end;

procedure oxTWinPointerDriver.SetXY(devID: longint; wnd: pointer; x, y: single);
var
   px,
   py: longint;

   oxwnd: oxTWindow  = nil;

   pos: oxTPoint;

begin
   {no window specified}
   if(wnd = nil) then begin
      px := round(x);
      py := round(y);
   {set pointer relative to window client position}
   end else begin
      oxwnd := oxTWindow(wnd);

      pos := oxwnd.Position;

      inc(pos.y, oxPlatform.TitleHeight(oxwnd));
      inc(pos.x, oxPlatform.FrameWidth(oxwnd));

      px := pos.x + round(x);
      py := pos.y + round(y);
   end;

   Windows.SetCursorPos(px, py);
end;

procedure oxTWinPointerDriver.Grab(devID: longint; wnd: pointer);
begin
   if(wnd <> nil) and (not appm.pointer[devID].grabbed) then begin
      appm.Pointer[devID].Grabbed := true;
      Windows.SetCapture(winosTWindow(wnd).wd.h);
   end;
end;

procedure oxTWinPointerDriver.Release(devID: longint; wnd: pointer);
begin
   appm.Pointer[devID].Grabbed := false;
   Windows.ReleaseCapture();
end;

procedure oxTWinPointerDriver.Show(devID: longint; wnd: pointer);
begin
   inc(appm.Pointer[devID].Shown);
   Windows.ShowCursor(TRUE);
end;

procedure oxTWinPointerDriver.Hide(devID: longint; wnd: pointer);
begin
   dec(appm.Pointer[devID].Shown);
   Windows.ShowCursor(FALSE);
end;

function oxTWinPointerDriver.ButtonState(devID: longint; wnd: pointer): longword;
begin
   Result := mButtonState;
end;

{ oxTWindowsPlatform }

constructor oxTWindowsPlatform.Create();
begin
   inherited;

   Name := 'mswin';
end;

function oxTWindowsPlatform.Initialize(): boolean;
begin
   PointerDriver := oxTWinPointerDriver.Create();

   Result := true;
end;

function oxTWindowsPlatform.MakeWindow(wnd: oxTWindow): boolean;

   procedure quit(const s: StdString);
   begin
      wnd.CreateFail('win-gdi > ' + s);
      Result := false;
   end;

begin
   Result := false;

   {register window class}
   if(not ClassRegister()) then begin
      quit('Failed to register the window class.');
      exit;
  end;

   {create window}
   if(CreateWindow(wnd) = 0) then begin
      quit('Window create fail.');
      exit;
   end;

   {initialize OpenGL for window}
   if(not oxTRenderer(wnd.Renderer).PreInitWindow(wnd)) then begin
      quit('Renderer window pixel format failed.');
      exit;
   end;

   {initialize renderer for window}
   if(not oxTRenderer(wnd.Renderer).InitWindow(wnd)) then begin
      quit('Renderer window create failed.');
      exit;
   end;

   if(winosTWindow(wnd).wd.LastError <> 0) then begin
      if(wnd.ErrorCode = 0) then
         wnd.CreateFail('Failed to create window due to error: ' + winos.FormatMessage(winosTWindow(wnd).wd.LastError));
   end;

   wnd.SetIcon(oxPaths.Find(oxPaths.UI + 'window.ico'));

   {done}
   if(uiwndpVISIBLE in wnd.Properties) then
      oxPlatform.ShowWindow(wnd);

   Result := true;
end;

function oxTWindowsPlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   Result := false;

   if(wnd.Renderer <> nil) then
      oxTRenderer(wnd.Renderer).DeInitWindow(wnd);

   if(winosTWindow(wnd).wd.dc <> 0) and (ReleaseDC(winosTWindow(wnd).wd.h, winosTWindow(wnd).wd.dc) = 0) then begin
      wnd.DestroyFail('Failed to release DC (' + sf(winosTWindow(wnd).wd.dc) + ') for window. ' + winos.FormatMessage(winos.GetLastError()));
   end;

   winosTWindow(wnd).wd.dc := 0;

   if(winosTWindow(wnd).wd.h <> 0) and (not windows.DestroyWindow(winosTWindow(wnd).wd.h)) then begin
      wnd.DestroyFail('Failed to destroy window handle (' + sf(winosTWindow(wnd).wd.h) + '). ' + winos.FormatMessage(winos.GetLastError()));
   end;

   winosTWindow(wnd).wd.h := 0;

   Result := true;
end;

procedure oxTWindowsPlatform.ProcessEvents();
var
   anyMessages: boolean;

begin
   repeat
      {process all messages at once}
      anyMessages := PeekMessage(@WinMsg, 0, 0, 0, 0);

      if (anyMessages) then begin
         GetMessage(@WinMsg, 0, 0, 0);
         DispatchMessage(WinMsg);
      end else
         break;
   until (false = true);
end;

function oxTWindowsPlatform.DeInitialize(): boolean;
begin
   {destroy the window class}
   UnregisterClass(pchar(windowClassName), system.MainInstance);

   classAtom := 0;
   hasClass := false;

   Result := true;
end;

procedure oxTWindowsPlatform.SetTitle(wnd: oxTWindow; const newTitle: StdString);
begin
   SetWindowText(winosTWindow(wnd).wd.h, pchar(newTitle));
end;

VAR
   defaultRect: windows.TRect = (
      Left:    0;
      Top:     0;
      Right:   0;
      Bottom:  0
   );

function oxTWindowsPlatform.TitleHeight(wnd: oxTWindow): longint;
var
   r: windows.TRECT;

begin
   r := defaultRect;
   AdjustWindowRectEx(@r, winosTWindow(wnd).wd.wStyle, FALSE, winosTWindow(wnd).wd.wStyleEx);

   Result := 0 - r.Top;
end;

function oxTWindowsPlatform.FrameWidth(wnd: oxTWindow): longint;
var
   r: windows.TRECT;

begin
   r := defaultRect;
   AdjustWindowRectEx(@r, winosTWindow(wnd).wd.wStyle, FALSE, winosTWindow(wnd).wd.wStyleEx);

   Result := 0 - r.Left;
end;

function oxTWindowsPlatform.FrameHeight(wnd: oxTWindow): longint;
var
   r: windows.TRECT;

begin
   r := defaultRect;
   AdjustWindowRectEx(@r, winosTWindow(wnd).wd.wStyle, FALSE, winosTWindow(wnd).wd.wStyleEx);

   Result := r.Bottom - 1;
end;

procedure oxTWindowsPlatform.ShowWindow(wnd: oxTWindow);
begin
   if(winosTWindow(wnd).wd.h <> 0) then
      windows.ShowWindow(winosTWindow(wnd).wd.h, SW_SHOW);
end;

procedure oxTWindowsPlatform.HideWindow(wnd: oxTWindow);
begin
   if(winosTWindow(wnd).wd.h <> 0) then
      windows.ShowWindow(winosTWindow(wnd).wd.h, SW_HIDE);
end;

procedure oxTWindowsPlatform.OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single);
begin
   x := wnd.Position.x + oxPlatform.FrameWidth(wnd);
   y := wnd.Position.y + oxPlatform.TitleHeight(wnd);
end;

function winosChangeDisplaySettings(lpDevMode: PDeviceMode; dwFlags: DWORD): longint;
var
   code: longint;
   codeName: string;

begin
   {if failed to enter full screen then exit}
   code := ChangeDisplaySettings(lpDevMode, dwFlags);

   if(code <> DISP_CHANGE_SUCCESSFUL) then begin
      codeName := sf(code);

      if code = DISP_CHANGE_BADDUALVIEW then
         codeName := 'BADDUALVIEW'
      else if code = DISP_CHANGE_BADFLAGS then
         codeName := 'BADFLAGS'
      else if code = DISP_CHANGE_BADMODE then
         codeName := 'BADMODE'
      else if code = DISP_CHANGE_BADPARAM then
         codeName := 'BADPARAM'
      else if code = DISP_CHANGE_FAILED then
         codeName := 'FAILED'
      else if code = DISP_CHANGE_NOTUPDATED then
         codeName := 'NOTUPDATED'
      else if code = DISP_CHANGE_RESTART then
         codeName := 'RESTART';

      log.e('ChangeDisplaySettings returned: ' + sf(code) + ' ' + codeName);         
   end;

   winos.LogError('Failed to change display settings');

   Result := code;
end;

function oxTWindowsPlatform.Fullscreen(window: oxTWindow; x, y, bpp: longint): boolean;
var
   dmScreenSettings: DEVMODE;

begin
   {fill the dmScreenSettings with the desired full screen information}
   ZeroOut(dmScreenSettings, SizeOf(dmScreenSettings));
   dmScreenSettings.dmSize       := SizeOf(dmScreenSettings);
   dmScreenSettings.dmPelsWidth	:= x;
   dmScreenSettings.dmPelsHeight	:= y;
   dmScreenSettings.dmBitsPerPel	:= bpp;
   dmScreenSettings.dmFields     := DM_BITSPERPEL or
                                    DM_PELSWIDTH or DM_PELSHEIGHT;

   {try to enter fullscreen}
   Result := winosChangeDisplaySettings(@dmScreenSettings, CDS_FULLSCREEN) = DISP_CHANGE_SUCCESSFUL;
end;

function oxTWindowsPlatform.Fullscreen(window: oxTWindow): boolean;
var
   wnd: winosTWindow;

begin
   wnd := winosTWindow(window);

   wnd.wd.Fullscreen.wStyle := wnd.wd.wStyle;
   wnd.wd.Fullscreen.wStyleEx := wnd.wd.wStyleEx;

   wnd.wd.wStyle := wnd.wd.wStyle and not(WS_CAPTION or WS_THICKFRAME);
   wnd.wd.wStyleEx := wnd.wd.wStyleEx and not (WS_EX_DLGMODALFRAME or WS_EX_WINDOWEDGE or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE);

   SetWindowLong(wnd.wd.h, GWL_STYLE, wnd.wd.wStyle);
   if(winos.LogError('Failed to set GWL_STYLE') <> 0) then
      exit(false);

   SetWindowLong(wnd.wd.h, GWL_EXSTYLE, wnd.wd.wStyleEx);
   if(winos.LogError('Failed to set GWL_EXSTYLE') <> 0) then
      exit(false);

   if(not wnd.Fullscreen.Windowed) then
      Result := Fullscreen(wnd, wnd.Dimensions.w, wnd.Dimensions.h, oxTRenderer(wnd.Renderer).Settings.ColorBits)
   else
      Result := true;
end;

function oxTWindowsPlatform.LeaveFullscreen(window: oxTWindow): boolean;
var
   wnd: winosTWindow;

begin
   wnd := winosTWindow(window);

   wnd.wd.wStyle := wnd.wd.Fullscreen.wStyle;
   wnd.wd.wStyleEx := wnd.wd.Fullscreen.wStyleEx;

   SetWindowLong(wnd.wd.h, GWL_STYLE, wnd.wd.wStyle);
   SetWindowLong(wnd.wd.h, GWL_EXSTYLE, wnd.wd.wStyleEx);

   if(not wnd.Fullscreen.Windowed) then
      Result := winosChangeDisplaySettings(nil, 0) = DISP_CHANGE_SUCCESSFUL
   else
      Result := true;
end;

procedure oxTWindowsPlatform.Move(wnd: oxTWindow; x, y: longint);
var
   r: windows.RECT;

begin
   {adjust dimensions so they are exactly what we want}
   r.Left   := x + FrameWidth(wnd);
   r.Right  := r.Left + wnd.Dimensions.w;

   r.Top    := y + TitleHeight(wnd);
   r.Bottom := r.Top + wnd.Dimensions.h;

   AdjustWindowRectEx(@r, winosTWindow(wnd).wd.wStyle, FALSE, winosTWindow(wnd).wd.wStyleEx);

   windows.MoveWindow(winosTWindow(wnd).wd.h, r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top,
      false {no repaint});
end;

procedure oxTWindowsPlatform.Resize(wnd: oxTWindow; w, h: longint);
var
   r: windows.RECT;

begin
   {adjust dimensions so they are exactly what we want}
   r.Left   := wnd.Position.x + FrameWidth(wnd);
   r.Right  := r.Left + w;

   r.Top    := wnd.Position.y + TitleHeight(wnd);
   r.Bottom := r.Top + h;

   AdjustWindowRectEx(@r, winosTWindow(wnd).wd.wStyle, FALSE, winosTWindow(wnd).wd.wStyleEx);

   windows.MoveWindow(winosTWindow(wnd).wd.h, r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top,
      false {no repaint});
end;

procedure oxTWindowsPlatform.Maximize(wnd: oxTWindow);
begin
   windows.ShowWindow(winosTWindow(wnd).wd.h, SW_MAXIMIZE);
end;

procedure oxTWindowsPlatform.Minimize(wnd: oxTWindow);
begin
   windows.ShowWindow(winosTWindow(wnd).wd.h, SW_MINIMIZE);
end;

procedure oxTWindowsPlatform.Restore(wnd: oxTWindow);
begin
   windows.ShowWindow(winosTWindow(wnd).wd.h, SW_RESTORE);
end;

procedure CreateKeyState(const k: appTKeyEvent; out state: TKeyboardState);
begin
   ZeroOut(state, SizeOf(state));

   if(k.Key.State.IsSet(kmCAPS)) then begin
      state[VK_CAPITAL] := $1;
   end;

   if(k.Key.State.IsSet(kmCONTROL)) then
      state[VK_CONTROL] := $FF;

   if(k.Key.State.IsSet(kmALT)) then
      state[VK_MENU] := $FF;

   if(k.Key.State.IsSet(kmSHIFT)) then
      state[VK_SHIFT] := $FF;

   state[k.PlatformCode] := $FF;
end;

function oxTWindowsPlatform.TranslateKey(const k: appTKeyEvent): char;
var
   keyState: TKeyboardState;
   chars: word = 0;
   count: loopint;

begin
   CreateKeyState(k, keyState);

   count := ToAscii(k.PlatformCode, k.PlatformScanCode, @keyState[0], @chars, 0);

   if(count = 2) then begin
      Result := char(hi(chars))
   end else if(count = 1) then
      Result := char(lo(chars))
   else
      Result := #0;
end;

procedure oxTWindowsPlatform.GetCenterPosition(wnd: oxTWindow; out p: oxTPoint);
var
   dvmd: DEVMODE;
   d: oxTDimensions;

begin
   d := wnd.GetTotalDimensions();
   EnumDisplaySettings(nil, ENUM_CURRENT_SETTINGS, @dvmd);

   p.x := dvmd.dmPelsWidth div 2  - d.w div 2;
   p.y := dvmd.dmPelsHeight div 2 - d.h div 2;
end;

function oxTWindowsPlatform.SetSystemIcon(wnd: oxTWindow; const fn: string): loopint;
var
   icon,
   smallIcon: windows.HICON;

begin
   Result := 0;

   icon := winos.LoadIcon(fn, 0, 0, LR_SHARED);
   smallIcon := winos.LoadIcon(fn, 16, 16, LR_SHARED);

   if(icon <> 0) then
      SendMessage(winosTWindow(wnd).wd.h, WM_SETICON, ICON_BIG, LPARAM(icon));

   if(smallIcon <> 0) then
      SendMessage(winosTWindow(wnd).wd.h, WM_SETICON, ICON_SMALL, LPARAM(smallIcon));

   if(icon = 0) then
      Result := eFAIL;
end;

INITIALIZATION
   { platform }
   oxPlatforms.Register(oxTWindowsPlatform);

END.
