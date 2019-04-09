{
   uiuWindow, UI window management
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuWindow;

INTERFACE

   USES
      uStd, uLog, uColors, vmVector,
      {app}
      uApp, appuEvents, appuKeys, appuActionEvents, appuMouse,
      {oX}
      oxuTypes, oxuWindows, oxuFont, oxuResourcePool,
      oxuPrimitives, oxuWindowTypes, oxuRender, oxuTransform,
      {ui}
      oxuUI, uiuSkin, uiuZOrder, uiuTypes, uiuControl,
      oxuTexture, oxuTextureGenerate, oxuRenderer,
      uiuWindowTypes, uiuWidget, uiuDraw, uiWidgets;

CONST
   wndevDISPOSE = 1;
   wndevSELECT = 2;
   wndevCLOSE = 3;

TYPE
   uiTWindowClass = class of uiTWindow;

   uiTWindowCreateData = record
      {frame type for window}
      Frame: uiTWindowFrameStyle;
      {what title buttons will the window use}
      Buttons: longword;
      {what parent the window will use}
      Parent: uiTWindow;
      {properties for the created window}
      Properties: uiTWindowProperties;
      {z index for the created window}
      ZIndex: loopint;
      {sets the ox window parent, this is usually automatically obtained from Parent}
      oxwParent: oxTWindow;
      {indicates what class of window to instance}
      Instance,
      {minimum base class type the above set instance needs to be}
      MinimumInstanceType: uiTWindowClass;

      {minimum size for the created window}
      MinimumSize,
      {maximum size for the created window}
      MaximumSize: oxTDimensions;
   end;

   { uiTWindowHelper }

   uiTWindowHelper = class helper for uiTWindow
      {select this window (bring to focus)}
      procedure Select();
      {queue a select event for the window}
      procedure SelectQueue();
      {checks if a window is sel-ected}
      function IsSelected(): boolean;
      {select a window level above}
      function SelectParent(): boolean;
      {deselect the currently selected window}
      procedure Deselect(reselect: boolean = true);
      {should be called when the window is deselected}
      procedure Deselected();

      { window control }

      {open a window}
      procedure Open();
      {closes a window}
      procedure Close();
      {queues a window close event}
      procedure CloseQueue();

      {minimizes a window}
      procedure Minimize();
      {maximizes a window}
      procedure Maximize();
      {restore window from maximized or minimized state to normal}
      procedure Restore();

      {set a new frame style}
      procedure SetFrameStyle(frameStyle: uiTWindowFrameStyle);

      {checks if the window is in front}
      function InFront(): boolean;

      {get coordinates for maximization}
      procedure GetMaximizationCoords(out p: oxTPoint; out d: oxTDimensions; exclude: uiTControl = nil);
      {get pointer position}
      function GetPointerPosition(x, y: longint): oxTPoint;

      {moves a window}
      procedure Move(x, y: longint);
      procedure Move(position: oxTPoint);

      procedure MoveAdjusted(x, y: longint);
      procedure MoveAdjusted(const p: oxTPoint);
      {move a the window for a relative position}
      procedure MoveRelative(x, y: longint);
      procedure MoveRelative(p: oxTPoint);

      {resizes a window}
      procedure Resize(w, h: longint; ignoreRestrictions: boolean = false);
      procedure Resize(newSize: oxTDimensions; ignoreRestrictions: boolean = false);

      procedure ResizeAdjusted(w, h: longint; ignoreRestrictions: boolean = false);
      procedure ResizeAdjusted(const newSize: oxTDimensions; ignoreRestrictions: boolean = false);

      {adjust width and height according to window restrictions}
      procedure AdjustSizesWithRestrictions(var w, h: longint);
      procedure AdjustSizesWithRestrictions(var d: oxTDimensions);

      {sends a notification event to the window}
      procedure Notification(evt: uiTWindowEvents);
      procedure PropagateEvent(var event: appTEvent);
      {queue a window event}
      procedure QueueEvent(evt: TEventID);

      { window management }

      {hides a window}
      procedure Hide(notify: boolean = true);
      {hides a window}
      procedure HideNoSelect(notify: boolean = true);
      {shows a window}
      procedure Show();
      {enables a window}
      procedure Enable();
      {disables a window}
      procedure Disable();

      { state management }
      function IsVisible(): boolean;
      function IsOpen(): boolean;

      { window listeners }

      {adds a listener to the list, returns true if added}
      function AddListener(listener: uiTWindowListener): boolean;
      {removes a listener from the list, returns true if the listener specified was found in the list}
      function RemoveListener(listener: uiTWindowListener): boolean;
      {removes all listeners}
      procedure RemoveListeners();

      { size }

      {get the title height}
      function GetTitleHeight(): longint;
      {get the frame width and height}
      function GetFrameWidth(): longint;
      function GetFrameHeight(): longint;
      {get the total non-client height of the window}
      function GetNonClientHeight(): longint;
      {get the total non-client width of the window}
      function GetNonClientWidth(): longint;
      {get total width (including non-client)}
      function GetTotalWidth(): loopint;
      {get total height (including non-client)}
      function GetTotalHeight(): loopint;
      {gets a rectangle for the specified window}
      procedure GetRect(out r: oxTRect);

      {get total dimensions, both client and non-client area}
      function GetTotalDimensions(): oxTDimensions;
      {compute dimensions required to fit all content (widgets)}
      function ContentDimensions(spacing: loopint = -1): oxTDimensions;
      {auto size to fit all content}
      procedure ContentAutoSize();

      { window rendering }
      procedure RenderSubWindows();
      procedure RenderWindow();

      procedure SetColor(r, g, b, a: byte);
      procedure SetColor(r, g, b, a: single);
      procedure SetColor(color: TColor4ub);
      procedure SetColor(color: TColor4f);

      procedure SetColorBlended(r, g, b, a: byte);
      procedure SetColorBlended(r, g, b, a: single);
      procedure SetColorBlended(color: TColor4ub);
      procedure SetColorBlended(color: TColor4f);

      procedure SetSkin(newSkin: uiTSkin);

      { management }

      {disposes all child windows}
      procedure DisposeSubWindows();
      procedure RemoveSubWindow(child: uiTWindow);

      { background }
      procedure SetBackgroundType(t: uiTWindowBackgroundType);
      procedure SetBackgroundColor(const clr: TColor4ub);
      function SetBackground(const fn: string): longint;

      {background texture type}
      procedure SetBackgroundFit(fit: uiTWindowBackgroundFit);
      procedure SetBackgroundTexture(tex: oxTTexture; fit: uiTWindowBackgroundFit);
      procedure SetBackgroundTextureTiling(tileX, tileY: single);

      {dispose of the background}
      procedure DisposeBackground();

      { finding windows }

      {finds a window and returns selection}
      procedure Find(x, y: longint; var s: uiTSelectInfo);
      {find the first child of the specified class, specifying recursive if you want to all levels}
      function Find(c: uiTWindowClass; recursive: boolean = false): uiTWindow;

      {returns the top level parent window, or the specified window if it has no parent}
      function GetTopLevel(): uiTWindow;
      {checks whether a window exists at any level within this window and returns its level}
      function Exists(pwnd: uiTWindow; sub: boolean = true): longint;
      {checks whether a window exists in this window and returns its index}
      function ExistChild(pwnd: uiTWindow): longint;

      { EFFECTS }
      procedure SetOpacity(newOpacity: single);

      { REPARENTING }
      {inserts a specified window as a child}
      procedure InsertWindow(child: uiTWindow);
      {move this window to the specified window}
      procedure ReparentTo(target: uiTWindow);

      { INTERNAL }

      {updates positions for all child windows}
      procedure UpdatePositions();
      {notifies all children that the parent resized}
      procedure UpdateParentSize(selfNotify: boolean = true);

      {adjusts the window position}
      procedure AdjustPosition();
      procedure AdjustPosition(x, y: longint; var p: oxTPoint);
      procedure AdjustDimensions(var d: oxTDimensions);
      {get the center position}
      function GetCenterPosition(): oxTPoint;
      {centers the window position}
      procedure AutoCenter();

      {set a window to quit application when escape key is pressed}
      procedure QuitOnEscape();

      { pointer locking }
      procedure LockPointer();
      procedure LockPointer(x, y: single);
      procedure UnlockPointer();

      procedure SetPointerCentered();

      {find all windows lined up horizontally with us}
      function FindHorizontalLineup(fitWithin: boolean = false): uiTPreallocatedWindowListArray;
      {find all windows lined up horizontally with us}
      function FindVerticalLineup(fitWithin: boolean = false): uiTPreallocatedWindowListArray;

      {find all windows of a given type}
      function FindType(wndType: uiTWindowClass): uiTPreallocatedWindowListArray;
      {find all windows of a given type recursively}
      procedure FindTypeRecursive(wndType: uiTWindowClass; var windows: uiTPreallocatedWindowListArray);

      {find a parent of the specified type, otherwise returns nil}
      function GetParentOfType(whatType: uiTWindowClass): uiTWindow;
      {checks if the window is of the specified type}
      function IsType(whatType: uiTWindowClass): boolean;
   end;

   { uiTPreallocatedWindowListArrayHelper }

   uiTPreallocatedWindowListArrayHelper = record helper for uiTPreallocatedWindowListArray
      function FindLeftOf(x: loopint): uiTPreallocatedWindowListArray;
      function FindRightOf(x: loopint): uiTPreallocatedWindowListArray;

      function FindAbove(y: loopint): uiTPreallocatedWindowListArray;
      function FindBelow(y: loopint): uiTPreallocatedWindowListArray;

      {get total width (including non-client) of all windows}
      function GetTotalWidth(): loopint;
      {get total height (including non-client) of all windows}
      function GetTotalHeight(): loopint;

      {get total window width to the left from the specified x point}
      function GetLeftWidthFrom(px: loopint): loopint;
      {get total window width to the right from the specified x point}
      function GetRightWidthFrom(px: loopint): loopint;

      {get total window height above the specified y point}
      function GetAboveHeightFrom(py: loopint): loopint;
      {get total window height below the specified y point}
      function GetBelowHeightFrom(py: loopint): loopint;
   end;

   { uiTWindowGlobalOn }

   uiTWindowOnRoutine = procedure(wnd: uiTWindow);

   {handles window oncreate callbacks}
   uiTWindowGlobalOn = specialize TPreallocatedArrayList<uiTWindowOnRoutine>;

   uiTWindowGlobalOnHelper = record helper for uiTWindowGlobalOn
      {call all oncreate callbacks from the list}
      procedure Call(wnd: uiTWindow);
   end;

   { uiTWindowGlobal }

   uiTWindowGlobal = record
      {event handler}
      evh: appTEventHandler;
      evhp: appPEventHandler;

      {stores window creation data}
      Create: uiTWindowCreateData;

      {renders windows automatically, if disabled the application has to call rendering routines}
      AutoRender,
      {move windows only by title}
      MoveOnlyByTitle,
      {automatically adjust window position when a window is created}
      AutoAdjustPosition: boolean;

      {border width/height for resizing a window}
      SizeBorder,
      {allocate memory for how many window listeners at a time}
      ListenerAllocationStep: longint;

      {default window buttons}
      DefaultButtons,
      RootDefaultButtons: longword;
      {default window properties}
      DefaultProperties,
      RootDefaultProperties: uiTWindowProperties;

      {list of escape keys, used for the default escape action}
      EscapeKeys: appTKeyList;
      {list of confirmation keys, used for the default confirmation action}
      ConfirmationKeys: appTKeyList;

      {NOTE: These keys are used for sub-windows, since top-level windows are handled by the OS anyways}
      {key used to close the window (sub-window)}
      CloseKey,
      {key used to switch to the next window (for sub-windows)}
      NextWindowKey,
      {key used to switch to previous window (for sub-windows)}
      PreviousWindowKey: appTKey;

      DefaultEscapeKey: appTKeyListItem;
      BackEscapeKey: appTKeyListItem;
      DefaultConfirmationKey: appTKeyListItem;
      DefaultBackground: uiTWindowBackground;

      {routines to call whenever a window is created}
      OnCreate,
      {routines to call whenever a window is destroyed}
      OnDestroy,
      {routines to call whenever a window rendering has finished}
      OnPostRender,
      {routines to call whenever an ox window rendering has finished}
      OxwPostRender: uiTWindowGlobalOn;

      {checks if the window is of the specified type}
      function IsType(wnd, whatType: uiTWindowClass): boolean;

      { WINDOW CREATION }
      {setup a created window}
      procedure SetupCreatedWindow(wnd: uiTWindow; var createData: uiTWindowCreateData);
      {creates a window}
      function Make(var createData: uiTWindowCreateData; out wnd: uiTWindow; const title: string;
               position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListener = nil): longint;
      function Make(wnd: uiTWindow; const title: string;
               position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListener = nil): longint;
      {creates a child window whose parent is wnd}
      function MakeChild(var createData: uiTWindowCreateData; wnd: uiTWindow; const title: string;
               const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListener = nil): uiTWindow;
      function MakeChild(wnd: uiTWindow; const title: string;
               const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListener = nil): uiTWindow;

      {disposes of a window}
      procedure Dispose(var wndRef: uiTWindow; destroyObject: boolean = true);
      {disposes a queue event}
      procedure DisposeQueue(wndRef: uiTWindow);
      {called either by dispose or free}
      procedure Destroyed(wnd: uiTWindow);

      {WINDOW SETUP}
      {restores window creating data to defaults}
      procedure RestoreCreateDefaults();
      {returns window creating data}
      procedure GetCreateData(out data: uiTWindowCreateData);

      { WINDOW SELECTION }
      {tells to how many levels two selections are equal}
      function SelectionEqu(const s1, s2: uiTSelectInfo): longint;

      { FINDING WINDOWS }
      {returns the top level parent window of the currently selected window}
      function GetSelectedTopLevelParent(): uiTWindow;

      { WINDOW RENDERING }
      {render an oX window}
      procedure RenderPrepare(wnd: oxTWindow);
      procedure Render(wnd: oxTWindow);
      {render all windows}
      procedure RenderAll();

      { UTILITIES }
      {get window notification from an event, or uiWINDOW_EVENT_NONE}
      function GetNotification(const event: appTEvent): uiTWindowEvents;
   end;

VAR
   uiWindow: uiTWindowGlobal;

{compare a window with an ID}
operator = (wnd: uiTWindow; var id: uiTControlID): boolean;

IMPLEMENTATION

VAR
   defaultEscapeKey: appTKeyListItem = (
      Name: 'ESC';
      Key: (
         Code: kcESC;
         State: 0
      );
      next: nil
   );

   backEscapeKey: appTKeyListItem = (
      Name: 'SYSBACK';
      Key: (
         Code: kcSYSBACK;
         State: 0
      );
      next: nil
   );

   defaultConfirmationKey: appTKeyListItem = (
      Name: 'ENTER';
      Key: (
         Code: kcENTER;
         State: 0
      );
      next: nil
   );

   defaultBackground: uiTWindowBackground = (
      Typ: uiwBACKGROUND_SOLID;
      Color: ($FF, $FF, $FF, $FF);
      Texture: nil;
      Fit: uiwBACKGROUND_TEX_DEFAULT;
      Tile: (1.0, 1.0);
      Offset: (0.0, 0.0);
   );


operator = (wnd: uiTWindow; var id: uiTControlID): boolean;
begin
   Result := (wnd <> nil) and (wnd.ID.ID = id.ID);
end;

{ uiTPreallocatedWindowListArrayHelper }

function uiTPreallocatedWindowListArrayHelper.FindLeftOf(x: loopint): uiTPreallocatedWindowListArray;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.x < x) then
         Result.Add(List[i]);
   end;
end;

function uiTPreallocatedWindowListArrayHelper.FindRightOf(x: loopint): uiTPreallocatedWindowListArray;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.x > x) then
         Result.Add(List[i]);
   end;
end;

function uiTPreallocatedWindowListArrayHelper.FindAbove(y: loopint): uiTPreallocatedWindowListArray;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.y > y) then
         Result.Add(List[i]);
   end;
end;

function uiTPreallocatedWindowListArrayHelper.FindBelow(y: loopint): uiTPreallocatedWindowListArray;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.y < y) then
         Result.Add(List[i]);
   end;
end;

function uiTPreallocatedWindowListArrayHelper.GetTotalWidth: loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      inc(Result, List[i].GetTotalWidth());
   end;
end;

function uiTPreallocatedWindowListArrayHelper.GetTotalHeight: loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      inc(Result, List[i].GetTotalHeight());
   end;
end;

function uiTPreallocatedWindowListArrayHelper.GetLeftWidthFrom(px: loopint): loopint;
var
   i,
   leftMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      leftMost := List[i].Position.x;

      if(px - leftMost> Result) then
         Result := px - leftMost;
   end;
end;

function uiTPreallocatedWindowListArrayHelper.GetRightWidthFrom(px: loopint): loopint;
var
   i,
   rightMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      rightMost := List[i].Position.x + List[i].GetTotalWidth();

      if(rightMost - px > Result) then
         Result := rightMost - px;
   end;
end;

function uiTPreallocatedWindowListArrayHelper.GetAboveHeightFrom(py: loopint): loopint;
var
   i,
   aboveMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      aboveMost := List[i].Position.y;

      if(aboveMost - py > Result) then
         Result := aboveMost - py;
   end;
end;

function uiTPreallocatedWindowListArrayHelper.GetBelowHeightFrom(py: loopint): loopint;
var
   i,
   belowMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      belowMost := List[i].Position.y - List[i].GetTotalHeight();

      if(py - belowMost > Result) then
         Result := py - belowMost;
   end;
end;


{ uiTWindowGlobalOnCreateHelper }

procedure uiTWindowGlobalOnHelper.Call(wnd: uiTWindow);
var
   i: longint;

begin
   for i := 0 to n - 1 do
      List[i](wnd);
end;

function uiTWindowGlobal.IsType(wnd, whatType: uiTWindowClass): boolean;
begin
   Result := uiTControl.IsType(wnd, whatType);
end;

procedure uiTWindowGlobal.SetupCreatedWindow(wnd: uiTWindow; var createData: uiTWindowCreateData);
begin
   wnd.SetSkin(oxui.DefaultSkin);
   wnd.Background       := uiWindow.DefaultBackground;
   wnd.SetBackgroundColor(wnd.Skin.Window.Colors.cBackground);
   wnd.Buttons          := createData.Buttons;
   wnd.Properties       := createData.Properties;

   {set minimum and maximum size, without overriding existing (constructor) if nothing is set in createData}
   if((wnd.MinimumSize.w = 0) and (wnd.MinimumSize.h = 0)) and
      ((createData.MinimumSize.w = 0) or (createData.MinimumSize.h <> 0)) then
      wnd.MinimumSize := createData.MinimumSize;

   if((wnd.MaximumSize.w = 0) and (wnd.MaximumSize.h = 0)) and
      ((createData.MaximumSize.w = 0) or (createData.MaximumSize.h <> 0)) then
      wnd.MaximumSize := createData.MaximumSize;

   wnd.AdjustSizesWithRestrictions(wnd.Dimensions);

   {set window parent}
   if(createData.Parent <> nil) then begin
      wnd.Parent := createData.Parent;

      createData.oxwParent := oxTWindow(createData.Parent.oxwParent);
   end;

   wnd.oxwParent := createData.oxwParent;

   {set window data}
   uiSkin.SetWindowDefault(wnd);
   wnd.Frame := createData.Frame;

   {adjust positions}
   if(autoAdjustPosition) then
      wnd.AdjustPosition();

   if(uiwndpAUTO_CENTER in wnd.Properties) and (wnd.Parent <> nil) then
      wnd.Position := wnd.GetCenterPosition();

   {call the interface to do it's portion of window creation if
   the window is not a child window}
   if(createData.Parent <> nil) then
      {put the child window at the next level}
      wnd.Level := createData.Parent.Level + 1;

   {restore defaults}
   RestoreCreateDefaults();

   {select this window is none is selected}
   if(oxui.Select.GetSelectedWnd() = nil) then
      wnd.Select();

   uiWindow.OnCreate.Call(wnd);

   wnd.Initialize();

   {update}
   wnd.UpdatePositions();

   wnd.Notification(uiWINDOW_CREATE);

   wnd.Open();
end;

{ WINDOW CREATION }

procedure uiMakeWindowFail(wnd: uiTWindow);
begin
   if(wnd <> nil) then
      log.e('ui > Failed to create window: ' + wnd.title);

   uiWindow.RestoreCreateDefaults();
end;

function uiTWindowGlobal.Make(var createData: uiTWindowCreateData; out wnd: uiTWindow; const title: string;
      position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListener): longint;

begin
   Result := eNONE;

   if(createData.MinimumInstanceType <> nil) then begin
      {set proper minimum window class, if one is not already set}
      if(not uiWindow.IsType(createData.Instance, createData.MinimumInstanceType)) then
         createData.Instance := createData.MinimumInstanceType;
   end;

   {allocate memory for the windows}
   if(createData.Instance = nil) then
      wnd := uiTWindow.Create()
   else
      wnd := createData.Instance.Create();

   if (wnd <> nil) then begin
      assert(wnd.ControlType = uiCONTROL_WINDOW, 'Instanced a window whose control type is not uiCONTROL_WINDOW');

      {adjust position and size}
      wnd.Position   := position;
      wnd.Dimensions := dimensions;
      wnd.SetTitle(title);
      wnd.ZIndex := createData.ZIndex;

      SetupCreatedWindow(wnd, createData);
      wnd.wHandler := wHandler;

      uiWidget.LastRect.Assign(wnd);
   end else
      exit(eNO_MEMORY);
end;

function uiTWindowGlobal.Make(wnd: uiTWindow; const title: string;
      position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListener): longint;
begin
   Result := Make(Create, wnd, title, position, dimensions, wHandler);
end;

function uiTWindowGlobal.MakeChild(var createData: uiTWindowCreateData; wnd: uiTWindow; const title: string;
         const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListener): uiTWindow;
var
   errcode: longint;
   child: uiTWindow;

begin
   assert(wnd <> nil, 'You cannot create a child window if the parent is nil.');

   {create the child window}
   createData.Parent := wnd;

   errcode := Make(create, child, title, position, dimensions, wHandler);
   if(errcode = 0) then begin
      wnd.W.Insert(child);

      {return a pointer to the child window}
      Result := wnd;
   end else
      Result := nil;

   Result := child;
end;

function uiTWindowGlobal.MakeChild(wnd: uiTWindow; const title: string;
         const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListener): uiTWindow;
begin
   Result := MakeChild(Create, wnd, title, position, dimensions, wHandler);
end;

procedure uiTWindowHelper.RemoveSubWindow(child: uiTWindow);
begin
   W.Remove(child);
end;

procedure uiTWindowGlobal.Dispose(var wndRef: uiTWindow; destroyObject: boolean);
var
   wnd: uiTWindow;

begin
   if(wndRef = nil) or (uiwndpDESTRUCTION_IN_PROGRESS in wndRef.Properties) then
      exit;

   Include(wndRef.Properties, uiwndpDESTRUCTION_IN_PROGRESS);

   wnd := wndRef;
   wndRef := nil;

   {unhook from parent}
   if(wnd.Parent <> nil) then
      uiTWindow(wnd.Parent).RemoveSubWindow(wnd);

   {make window unusable}
   wnd.Close();

   wnd.Properties := wnd.Properties - [uiwndpVISIBLE, uiwndpENABLED];

   Destroyed(wnd);

   wnd.DisposeSubWindows();
   uiWidget.Dispose(uiTWidgets(wnd.Widgets));

   appEvents.DisableForWindow(wnd);

   oxui.Select.Deselect(uiTControl(wnd));
   oxui.mSelect.Deselect(uiTControl(wnd));

   Destroyed(wnd);

   wnd.DisposeBackground();

   {destroy any listeners on this window}
   wnd.RemoveListeners();

   if(destroyObject) then
      FreeObject(wnd);
end;

procedure uiTWindowGlobal.DisposeQueue(wndRef: uiTWindow);
begin
   if(wndRef <> nil) then
      wndRef.QueueEvent(wndevDISPOSE);
end;

procedure uiTWindowGlobal.Destroyed(wnd: uiTWindow);
begin
   assert(wnd <> nil, 'Tried to mark a nil window as destroyed');

   if(oxui.UseWindow = wnd) then
      oxui.UseWindow := nil;

   {call all OnDestroy routines}
   uiWindow.OnDestroy.Call(wnd);

   {deinitialize the window}
   wnd.Notification(uiWINDOW_DESTROY);
   wnd.DeInitialize();

   {remove our parent, if it was for some reason destroyed before us}
   wnd.Parent := nil;
end;

procedure uiTWindowHelper.DisposeSubWindows();
var
   current: uiTWindow;

begin
   assert(w.w.n <= Length(w.w.List), 'Sub-window count not equal to sub-window array size.');

   if(w.w.n > 0) then begin
      current := uiTWindow(w.w[0]);
      uiWindow.Dispose(current);

      DisposeSubWindows();
   end else
      w.w.Dispose();
end;

{ WINDOW LISTENERS }

function uiTWindowHelper.AddListener(listener: uiTWindowListener): boolean;
begin
   Result := Listeners.Add(listener);
end;

function uiTWindowHelper.RemoveListener(listener: uiTWindowListener): boolean;
var
   i: longint;
   where: longint = -1;

begin
   for i := 0 to Listeners.n - 1 do begin
      if(Listeners[i] = listener) then begin
         where := i;
         break;
      end;
   end;

   if(where > -1) then begin
      {reorder list if necessary}
      if(where < Listeners.n - 1) and (Listeners.n > 1) then
         for i := where to Listeners.n - 2 do
            Listeners.List[i] := Listeners.List[i + 1];

      dec(Listeners.n);
      Result := true;
   end else
      Result := false;
end;

procedure uiTWindowHelper.RemoveListeners();
begin
   Listeners.Dispose();
end;

procedure uiTWindowHelper.Notification(evt: uiTWindowEvents);
var
   e: appTEvent;

begin
   Action(evt);

   appEvents.Init(e);

   e.hID    := uievhpWINDOW;
   e.evID   := LongWord(evt);
   e.wnd    := Self;

   PropagateEvent(e);
end;

procedure uiTWindowHelper.PropagateEvent(var event: appTEvent);
var
   i: longint;

begin
   if(wHandler <> nil) then
      wHandler(Self, event);

   for i := 0 to Listeners.n - 1 do
      Listeners[i](Self, event);
end;

procedure uiTWindowHelper.QueueEvent(evt: TEventID);
var
   ev: appTEvent;

begin
   appEvents.Init(ev, evt, uiWindow.evhp);
   ev.wnd := Self;
   appEvents.Queue(ev);
end;

{ WINDOW CONTROL }

procedure uiTWindowHelper.Open();
begin
   if(uiwndpCLOSED in Properties) then begin
      {the window is enabled and shown}
      Enable();
      Show();

      {clear the window closed property}
      Exclude(Properties, uiwndpCLOSED);

      {move to front}
      if(Parent <> nil) then
         uiTWindow(Parent).w.z.MoveToTop(self);

      Select();

      {notify the window it is now open}
      Notification(uiWINDOW_OPEN);
      OnOpen();
   end else if(uiwndpMINIMIZED in Properties) then begin
      Restore();

      Select();
   end else
      Select();
end;

procedure uiTWindowHelper.Close();
begin
   if(IsOpen()) then begin
      {set the window closed property}
      Include(Properties, uiwndpCLOSED);

      {this just disables and hides the window and deselects any widgets}
      Disable();
      if(uiwndpCLOSE_SELECT in Properties) then
         Hide(false)
      else
         HideNoSelect(False);

      {clear any pointer lock}
      if(oxui.PointerCapture.Wnd = Self) then
         oxui.PointerCapture.Clear();

      {TODO: Check if any children performed the lock}

      {notify window handler the window is closed}
      Notification(uiWINDOW_CLOSE);

      OnClose();

      {check if the application should quit when this window is close}
      if((uiwndpQUIT_ON_CLOSE in Properties) and app.Active and
         (not appEvents.Queued(evhpACTION_EVENTS, appACTION_QUIT))) then begin
         log.i('Quitting application, due to window(' + ID.ToString() + ') closing.');
         appActionEvents.QueueQuitEvent();
      end;

      {TODO: Close ox window}
   end;
end;

procedure uiTWindowHelper.CloseQueue();
begin
   QueueEvent(wndevCLOSE);
end;

procedure uiTWindowHelper.Minimize();
begin
   if(not (uiwndpMINIMIZED in Properties)) then begin
      Include(Properties, uiwndpMINIMIZED);

      Notification(uiWINDOW_MINIMIZE);
      OnMinimize();
   end;
end;

procedure uiTWindowHelper.Maximize();
var
   p: oxTPoint;
   d: oxTDimensions;

begin
   if(not (uiwndpMAXIMIZED in Properties)) then begin
      Exclude(Properties, uiwndpMINIMIZED);
      Include(Properties, uiwndpMAXIMIZED);

      if(Parent <> nil) then begin
         MaximizedPosition := Position;
         MaximizedDimensions := Dimensions;
         MaximizedFrame := Frame;

         uiTWindow(Parent).GetMaximizationCoords(p, d);

         SetFrameStyle(uiwFRAME_STYLE_NONE);

         Move(p);
         Resize(d);

         Notification(uiWINDOW_MAXIMIZE);
         OnMaximize();
      end;

      {TODO: Maximize ox window}
   end;
end;

procedure uiTWindowHelper.Restore();
begin
   if(uiwndpMINIMIZED in Properties) then begin
      Exclude(Properties, uiwndpMINIMIZED);

      Notification(uiWINDOW_RESTORE);
      exit;
   end;

   if(uiwndpMAXIMIZED in Properties) then begin
      Exclude(Properties, uiwndpMAXIMIZED);

      if(Parent <> nil) then begin
         SetFrameStyle(MaximizedFrame);

         Move(MaximizedPosition);
         Resize(MaximizedDimensions);
      end;

      {TODO: Restore ox window}

      Notification(uiWINDOW_RESTORE);
   end;
end;

procedure uiTWindowHelper.SetFrameStyle(frameStyle: uiTWindowFrameStyle);
begin
   Frame := frameStyle;
end;

function uiTWindowHelper.InFront(): boolean;
var
   i: loopint;
   targetWnd, parentWnd: uiTWindow;

begin
   if(Parent <> nil) and (Parent.ControlType = uiCONTROL_WINDOW) then begin
      parentWnd := uiTWindow(Parent);

      for i := (parentWnd.W.z.Entries.n - 1) downto 0 do begin
         if(parentWnd.W.z.Entries[i] <> nil) then begin
            targetWnd := uiTWindow(parentWnd.W.z.Entries[i]);

            if(not (uiwndpCLOSED in targetWnd.Properties)) and (not (uiwndpMINIMIZED in targetWnd.Properties)) then
               exit(targetWnd = Self);
         end;
      end;

      exit(false);
   end;

   {TODO: Check for ox window, we'll just assume for now it is in front}
   Result := true;
end;

procedure uiTWindowHelper.GetMaximizationCoords(out p: oxTPoint; out d: oxTDimensions; exclude: uiTControl);
var
   i: longint;
   wdg: uiTWidget;
   x,
   rightX,
   y,
   bottomY,
   w,
   h: longint;

begin
   h := Dimensions.h;
   w := Dimensions.w;

   d.w := Dimensions.w;
   d.h := h;

   p.x := 0;
   p.y := Dimensions.h - 1;

   {find maximum available unobscured vertical space}
   if(Widgets.w.n > 0) then begin
      y := Dimensions.h - 1;
      bottomY := 0;

      for i := 0 to (Widgets.w.n - 1) do begin
         wdg := uiTWidget(Widgets.w[i]);

         if(wdg <> nil) and (wdg.ObscuresMaximization = uiCONTROL_MAXIMIZATION_OBSCURE_VERTICAL) and (exclude <> wdg) then begin
            if(wdg.Position.y = y) then
               y := wdg.Position.y - wdg.Dimensions.h
            else if(wdg.Position.y < y) and (wdg.Position.y > bottomY) then
               bottomY := wdg.Position.y + 1;
         end;
      end;

      h := y + 1 - bottomY;

      x := 0;
      rightX := Dimensions.w - 1;

      for i := 0 to (Widgets.w.n - 1) do begin
         wdg := uiTWidget(Widgets.w[i]);

         if(wdg <> nil) and (wdg.ObscuresMaximization = uiCONTROL_MAXIMIZATION_OBSCURE_HORIZONTAL) and (exclude <> wdg) then begin
            if(wdg.Position.y - wdg.Dimensions.h < y) and (wdg.Position.y > y - h + 1) then begin
               if(wdg.Position.x = x) then
                  x := wdg.Position.x + wdg.Dimensions.w
               else if(wdg.Position.x > x) then
                  rightX := wdg.Position.x + 1;
            end;
         end;
      end;

      w := rightX - x + 1;

      p.y := y;
      p.x := x;
      d.h := h;
      d.w := w;
   end;
end;

function uiTWindowHelper.GetPointerPosition(x, y: longint): oxTPoint;
begin
   Result.x := x - (RPosition.x + GetFrameWidth());
   Result.y := y - RPosition.y + Dimensions.h - 1;
end;

{ WINDOW MANAGEMENT }
procedure uiTWindowHelper.Move(x, y: longint);
begin
   Position.x := x;
   Position.y := y;

   UpdatePositions();
end;

procedure uiTWindowHelper.Move(position: oxTPoint);
begin
   Move(position.x, position.y);
end;

procedure uiTWindowHelper.MoveAdjusted(x, y: longint);
begin
   Move(x + GetFrameWidth() - 1, y - GetTitleHeight() - 1);
end;

procedure uiTWindowHelper.MoveAdjusted(const p: oxTPoint);
begin
   MoveAdjusted(p.x, p.y);
end;

procedure uiTWindowHelper.MoveRelative(x, y: longint);
begin
   if(x <> 0) or (y <> 0) then
      Move(Position.x + x, Position.y + y)
end;

procedure uiTWindowHelper.MoveRelative(p: oxTPoint);
begin
   if(p.x <> 0) or (p.y <> 0) then
      Move(Position.x + p.x, Position.y + p.y);
end;

procedure uiTWindowHelper.Resize(w, h: longint; ignoreRestrictions: boolean);
begin
   if(not ignoreRestrictions) then begin
      AdjustSizesWithRestrictions(w, h);
   end else begin
      if(w < 0) then
         w := 0;

      if(h < 0) then
         h := 0;
   end;

   PreviousDimensions := Dimensions;
   Dimensions.w := w;
   Dimensions.h := h;

   Notification(uiWINDOW_RESIZE);
   SizeChanged();

   UpdateParentSize(false);
end;

procedure uiTWindowHelper.Resize(newSize: oxTDimensions; ignoreRestrictions: boolean = false);
begin
   Resize(newSize.w, newSize.h, ignoreRestrictions);
end;

procedure uiTWindowHelper.ResizeAdjusted(w, h: longint; ignoreRestrictions: boolean = false);
var
   d: oxTDimensions;

begin
   d.w := w;
   d.h := h;

   ResizeAdjusted(d, ignoreRestrictions);
end;

procedure uiTWindowHelper.ResizeAdjusted(const newSize: oxTDimensions; ignoreRestrictions: boolean = false);
var
   d: oxTDimensions;

begin
   d := newSize;

   AdjustDimensions(d);

   Resize(d.w, d.h, ignoreRestrictions);
end;

procedure uiTWindowHelper.AdjustSizesWithRestrictions(var w, h: longint);
begin
   if(w < MinimumSize.w) then
      w := MinimumSize.w;

   if(h < MinimumSize.h) then
      h := MinimumSize.h;

   if(w > MaximumSize.w) and (MaximumSize.w <> 0) then
      w := MaximumSize.w;

   if(h > MaximumSize.h) and (MaximumSize.h <> 0) then
      h := MaximumSize.h;
end;

procedure uiTWindowHelper.AdjustSizesWithRestrictions(var d: oxTDimensions);
begin
   AdjustSizesWithRestrictions(d.w, d.h);
end;

{WINDOW SETUP}
procedure uiTWindowGlobal.RestoreCreateDefaults();
begin
   uiWindow.GetCreateData(Create);
end;

procedure uiTWindowGlobal.GetCreateData(out data: uiTWindowCreateData);
begin
   ZeroOut(data, SizeOf(uiTWindowCreateData));

   data.Instance  := nil;
   data.MinimumInstanceType := nil;
   data.Frame     := uiwFRAME_STYLE_DEFAULT;
   data.Buttons   := defaultButtons;
   data.ZIndex    := uiwzcDefaultZIndex;
   data.Properties := DefaultProperties;

   data.MinimumSize := oxNullDimensions;
   data.MaximumSize := oxNullDimensions;
end;

{ BACKGROUND }
procedure uiTWindowHelper.SetBackgroundType(t: uiTWindowBackgroundType);
begin
   Background.Typ := t;
end;

procedure uiTWindowHelper.SetBackgroundColor(const clr: TColor4ub);
begin
   Background.Color := clr;
end;

function uiTWindowHelper.SetBackground(const fn: string): longint;
var
   errcode: longint;

begin
   errcode  := oxTextureGenerate.Generate(fn, oxTTexture(Background.Texture));

   if(errcode = 0) then begin
      Background.Typ := uiwBACKGROUND_TEX;
      Background.Color := cWhite4ub;
   end;

   Result := errcode;
end;

procedure uiTWindowHelper.SetBackgroundFit(fit: uiTWindowBackgroundFit);
begin
   Background.Fit := fit;
end;

procedure uiTWindowHelper.SetBackgroundTexture(tex: oxTTexture; fit: uiTWindowBackgroundFit);
begin
   Background.Texture := tex;
   if(tex <> nil) then begin
      tex.MarkUsed();
      Background.Fit := fit;
      Background.Typ := uiwBACKGROUND_TEX;
      Background.Color := cWhite4ub;
   end else begin
      SetBackgroundColor(Background.Color);
   end;
end;

procedure uiTWindowHelper.SetBackgroundTextureTiling(tileX, tileY: single);
begin
   Background.Fit  := uiwBACKGROUND_TEX_TILE;
   Background.Typ  := uiwBACKGROUND_TEX;
   Background.Tile[0] := tileX;
   Background.Tile[1] := tileY;
end;

procedure uiTWindowHelper.DisposeBackground();
begin
   if(Background.Texture <> nil) then begin
      oxResource.Destroy(Background.Texture);
      Background.Typ := uiwBACKGROUND_SOLID;
   end;
end;

procedure uiTWindowHelper.Hide(notify: boolean);
begin
   if(uiwndpVISIBLE in Properties) then begin
      Exclude(Properties, uiwndpVISIBLE);
      Deselect();

      {notify the window it is now open}
      if(notify) then
         Notification(uiWINDOW_HIDE);
   end;
end;

procedure uiTWindowHelper.HideNoSelect(notify: boolean);
begin
   if(uiwndpVISIBLE in Properties) then begin
      Exclude(Properties, uiwndpVISIBLE);

      {notify the window it is now open}
      if(notify) then
         Notification(uiWINDOW_HIDE);
   end;
end;

procedure uiTWindowHelper.Show();
begin
   if(not (uiwndpVISIBLE in Properties)) then begin
      Include(Properties, uiwndpVISIBLE);

      {notify the window it is now open}
      Notification(uiWINDOW_SHOW);
   end;
end;

procedure uiTWindowHelper.Enable();
begin
   if(not (uiwndpENABLED in Properties)) then
      Include(Properties, uiwndpENABLED);
end;

procedure uiTWindowHelper.Disable();
begin
   if(uiwndpENABLED in Properties) then
      Exclude(Properties, uiwndpENABLED);
end;

{WINDOW SELECTION}
function uiTWindowHelper.IsSelected(): boolean;
begin
   Result := (Level <= oxui.Select.l) and (oxui.Select.s[Level] = Self);
end;

procedure uiTWindowHelper.Select();
var
   i: longint;
   selected: uiTControl;
   previouslySelected: uiTWindow;
   previouslySelectedWdg: uiTWidget;

begin
   selected := oxui.Select.Selected;
   previouslySelected := oxui.Select.GetSelectedWnd();
   previouslySelectedWdg := oxui.Select.GetSelectedWdg();

   if(selected <> Self) then begin
      oxui.Select.Assign(uiTControl(Self));

      oxui.useWindow := Self;

      if(previouslySelected <> Self) then begin
         {move the window and all it's parents to the top of the z order}
         for i := 0 to oxui.Select.l do begin
            if(i > 0) and (oxui.Select.s[i - 1].ControlType = uiCONTROL_WINDOW) then
               uiTWindow(oxui.Select.s[i - 1]).w.z.MoveToTop(oxui.Select.s[i])
         end;

         Notification(uiWINDOW_ACTIVATE);
         OnActivate();

         if(previouslySelected <> nil) then
            previouslySelected.Deselected();
      end;

      if(previouslySelectedWdg <> nil) then
         previouslySelectedWdg.Deselected();
   end;
end;

procedure uiTWindowHelper.SelectQueue();
begin
   QueueEvent(wndevSELECT);
end;

function uiTWindowHelper.SelectParent(): boolean;
begin
   if(Parent <> nil) then begin
      uiTWindow(Parent).Select();
      Result := true;
   end else
      Result := false;
end;

procedure uiTWindowHelper.Deselect(reselect: boolean);
var
   i: longint;
   sWnd, pWnd: uiTWindow;

begin
   oxui.mSelect.Deselect(uiTControl(Self));

   if(not IsSelected()) then
      exit;

   oxui.Select.Deselect(uiTControl(Self));

   if(reselect) then begin
      sWnd := nil;

      {if there is a parent, then go through its children}
      if(Parent <> nil) and (uiTWindow(Parent).w.z.Entries.n > 0) then begin
         {use parent by default if nothing found}
         sWnd := uiTWindow(Parent);

         for i := (uiTWindow(Parent).w.z.Entries.n - 1) downto 0 do begin
            pWnd := uiTWindow(uiTWindow(Parent).w.z.Entries[i]);

            {the window must be visible and selectable}
            if(pWnd <> self) and (pWnd.IsVisible() and (uiwndpSELECTABLE in pWnd.Properties)) then begin
               sWnd := pWnd;
               break;
            end;
         end;

         {if no window was found amongst parents children, then set parent}
         if(sWnd = nil) then
            sWnd := uiTWindow(Parent);
      end;

      if(sWnd <> nil) then
         sWnd.Select();
   end;

   Deselected();
end;

procedure uiTWindowHelper.Deselected();
begin
   Notification(uiWINDOW_DEACTIVATE);
   OnDeactivate();
end;

function uiTWindowGlobal.SelectionEqu(const s1, s2: uiTSelectInfo): longint;
var
   i,
   rep_end: longint;

begin
   Result := -1;

   {get the loop end, which has to be the smallest level of both selections}
   rep_end := s1.l;
   if(s2.l < rep_end) then
      rep_end := s2.l;

   {find the equal levels}
   if(rep_end > -1) then begin
      for i := 0 to rep_end do begin
         if(s1.s[i] <> s2.s[i]) then
            exit(i-1);
      end;

      exit(rep_end);
   end;
end;

{ FINDING WINDOWS }
procedure uiFindNext(parentWdg: uiTWidget; const widgets: uiTWidgets; x, y: longint; var s: uiTSelectInfo);
var
   r: oxTRect;
   i: longint;
   wdg: uiTWidget;


begin
   if(parentWdg <> nil) then begin
      inc(s.l);
      s.s[s.l] := parentWdg;
      s.Selected := parentWdg;
   end;

   for i := (widgets.z.Entries.n - 1) downto 0 do begin
      wdg := uiTWidget(widgets.z.Entries[i]);

      if(wdg <> nil) and (wdgpVISIBLE in wdg.Properties) then begin
         wdg.GetRect(r);

         {if the point is in the rectangle}
         if(r.Inside(x, y)) then begin
            dec(s.x, wdg.Position.x);
            dec(s.y, wdg.Position.y - (wdg.Dimensions.h - 1));

            uiFindNext(wdg, wdg.Widgets, s.x, s.y, s);

            exit; {stop if in rectangle}
         end;
      end;
   end;
end;

procedure uiFindNext(wnd: uiTWindow; x, y: longint; var s: uiTSelectInfo);
var
   r: oxTRect;
   i: longint;
   p: uiTWindow;


begin
   inc(s.l);
   s.s[s.l] := wnd;
   s.Selected := wnd;

   for i := (wnd.w.z.Entries.n - 1) downto 0 do begin
      p := uiTWindow(wnd.w.z.Entries[i]);

      if(p <> nil) and p.IsVisible() and (s.Exclude <> p) then begin
         p.GetRect(r);

         {if the point is in the rectangle}
         if(r.Inside(x, y)) then begin
            dec(s.x, p.Position.x);
            dec(s.x, p.GetFrameWidth());

            dec(s.y, p.Position.y);
            inc(s.y, p.Dimensions.h + p.GetTitleHeight() - 1);

            uiFindNext(p, s.x, s.y, s);

            exit; {stop if in rectangle}
         end;
      end;
   end;

   if(not s.OnlyWindows) then
      uiFindNext(nil, uiTWidgets(wnd.Widgets), x, y, s);
end;


procedure uiTWindowHelper.Find(x, y: longint; var s: uiTSelectInfo);
begin
   s.l   := -1;
   s.x   := x;
   s.y   := y;

   s.startPoint.x := x;
   s.startPoint.y := y;

   if(s.Exclude <> Self) then
      uiFindNext(Self, x, y, s);
end;

function uiTWindowHelper.Find(c: uiTWindowClass; recursive: boolean): uiTWindow;
var
   i: loopint;

begin
   if(W.w.n > 0) then begin
      for i := 0 to (W.w.n - 1) do begin
         if(uiTWindow(W.w[i]).IsType(c)) then
            exit(uiTWindow(W.w[i]));
      end;

      if(recursive) then begin
         for i := 0 to (W.w.n - 1) do begin
            Result := uiTWindow(W.w[i]).Find(c, true);

            if(Result <> nil) then
               exit;
         end;
      end;
   end;

   Result := nil;
end;

function uiTWindowHelper.GetTopLevel(): uiTWindow;
begin
   Result := oxTWindow(oxwParent);
end;

{checks whether the window exists}
function uiTWindowHelper.Exists(pwnd: uiTWindow; sub: boolean): longint;
var
   i: longint;

begin
   Result := -1;

   if(pwnd <> nil) and (W.w.n > 0) then begin
      {try to find in the current window}
      for i := 0 to (w.w.n - 1) do begin
         if(w.w[i] = pwnd) then
            exit(uiTWindow(w.w[i]).Level);
      end;

      {otherwise search through sub-windows}
      if(sub) then begin
         for i := 0 to (W.w.n - 1) do
            if(w.w[i] <> nil) then
               Result := uiTWindow(W.w[i]).Exists(pwnd, true);
      end;
   end;
end;

function uiTWindowHelper.ExistChild(pwnd: uiTWindow): longint;
var
   i: longint;

begin
   if(pwnd <> nil) then begin
      {try to find in the current window}
      for i := 0 to (W.w.n - 1) do begin
         if(W.w[i] = pwnd) then
            exit(i);
      end;
   end;

   Result := -1;
end;

procedure uiTWindowHelper.SetOpacity(newOpacity: single);
begin
   opacity := newOpacity;
end;

procedure uiTWindowHelper.InsertWindow(child: uiTWindow);
begin
   if(ExistChild(child) = -1) then
      W.Insert(child);
end;

procedure uiTWindowHelper.ReparentTo(target: uiTWindow);
begin
   {remove from parent}
   if(Parent <> nil) then
      uiTWindow(Parent).RemoveSubWindow(Self);

   {add to target window}
   target.InsertWindow(Self);

   Self.Parent := target;
   Self.oxwParent := target.oxwParent;
   Self.Level := target.Level + 1;
end;

function uiTWindowGlobal.GetSelectedTopLevelParent(): uiTWindow;
var
   wnd: uiTWindow;

begin
   wnd := oxui.Select.GetSelectedWnd();

   if(wnd <> nil) then
      Result := wnd.GetTopLevel()
   else
      Result := nil;
end;

{ WINDOW RENDERING }

procedure uiTWindowHelper.RenderSubWindows();
var
   i: longint;
   pwnd: uiTWindow;

begin
   for i := 0 to (w.z.Entries.n - 1) do begin
      pwnd := uiTWindow(w.z.Entries[i]);

      if(pwnd <> nil) then
         pwnd.RenderWindow();
   end;
end;

procedure uiTWindowHelper.RenderWindow();
var
   width,
   fw,
   fh: longint;
   f: oxTFont;
   wSelected: boolean;
   colors: uiPWindowSkinColors;

procedure RenderWnd();
var
   r: oxTRect;
   tx: array[0..3] of TVector2f;

procedure renderBackgroundBox();
begin
   uiDraw.Box(RPosition.x, RPosition.y - Dimensions.h + 1, RPosition.x + Dimensions.w - 1, RPosition.y);
end;

procedure renderBackground();
var
   texture: oxTTexture;

begin
   if(Background.Typ = uiwBACKGROUND_SOLID) then begin
      SetColor(Background.Color);
      renderBackgroundBox();
   end else if(Background.Typ = uiwBACKGROUND_TEX) then begin
      SetColor(Background.Color);
      texture := oxTTexture(Background.Texture);

      if(oxTTexture(Background.Texture).HasAlpha()) then
         oxRender.EnableBlend()
      else
         oxRender.DisableBlend();

      {assign background texture}
      if(Background.Fit = uiwBACKGROUND_TEX_FIT) then begin
         oxTex.CoordsQuadWH(texture.Width, texture.Height, Dimensions.w, Dimensions.h, tx);
      end else if(Background.Fit = uiwBACKGROUND_TEX_TILE) then begin
         tx := QuadTexCoords;
         vmScale(tx[0], 4, Background.Tile[0], Background.Tile[1]);

         if(Background.Offset[0] <> 0.0) or (Background.Offset[1] <> 0.0) then
            vmOffset(tx[0], 4, Background.Offset[0], Background.Offset[1]);
      end else begin
         tx := QuadTexCoords;
         vmScale(tx[0], 4, Background.Tile[0], Background.Tile[1]);

         if(Background.Offset[0] <> 0.0) or (Background.Offset[1] <> 0.0) then
            vmOffset(tx[0], 4, Background.Offset[0], Background.Offset[1]);
      end;

      oxui.Material.ApplyTexture('texture', texture);
      oxRender.TextureCoords(tx[0]);

      {render background}
      renderBackgroundBox();
   end;
end;

procedure renderNiceFrame();
begin
   {title}
   if(wSelected) then
      SetColor(colors^.cTitle)
   else
      SetColor(colors^.cTitle);

   uiDraw.Box(Aposition.x + 1, RPosition.y + 1, Aposition.x + width - 2, Aposition.y - 1);
   uiDraw.HLine(Aposition.x + 2, Aposition.y, Aposition.x + width - 3);

   {frame}
   SetColor(colors^.cFrame);

   {left}
   uiDraw.Box(Aposition.x + 1, RPosition.y - Dimensions.h + 1, Aposition.x + fw - 1, RPosition.y);
   {right}
   uiDraw.Box(Aposition.x + width - fw, RPosition.y - Dimensions.h + 1, Aposition.x + width - 2, RPosition.y);
   {bottom}
   uiDraw.Box(Aposition.x + 1, RPosition.y - Dimensions.h - fh + 2, Aposition.x + width - 2, RPosition.y - Dimensions.h);
   {left line}
   uiDraw.VLine(Aposition.x, Aposition.y - 2, RPosition.y - Dimensions.h - 1);
   {right line}
   uiDraw.VLine(Aposition.x + width - 1, Aposition.y - 2, RPosition.y - Dimensions.h - 1);
   {bottom line}
   uiDraw.HLine(Aposition.x + 2, RPosition.y - Dimensions.h - fh + 1, Aposition.x + width - 3);

   {inner frame}
   SetColor(colors^.cInnerFrame);

   uiDraw.Rect(Aposition.x + fw - 1, RPosition.y + 1, Aposition.x + width - fw, RPosition.y - Dimensions.h);
end;

procedure renderSimpleFrame();
begin
   {title}
   SetColor(colors^.cTitle);

   uiDraw.Box(Aposition.x, RPosition.y + 1, Aposition.x + width - 1, Aposition.y);

   {frame}
   SetColor(colors^.cFrame);

   {left}
   uiDraw.Box(Aposition.x, RPosition.y - Dimensions.h + 1, Aposition.x + fw - 1, RPosition.y);
   {right}
   uiDraw.Box(Aposition.x + width - fw, RPosition.y - Dimensions.h + 1, Aposition.x + width - 1, RPosition.y);
   {bottom}
   uiDraw.Box(Aposition.x, RPosition.y - Dimensions.h - fh + 1, Aposition.x + width - 1, RPosition.y - Dimensions.h);
end;

begin
   {render background}
   renderBackground();

   {render frame}
   if(Frame <> uiwFRAME_STYLE_NONE) then begin
      if(Skin.Window.Frames[ord(Frame)].FrameForm = uiwFRAME_FORM_NICE) then begin
         renderNiceFrame();
      end else
         renderSimpleFrame();

      {write title}
      if(f <> nil) then begin
         f.Start();
         SetColorBlended(colors^.cTitleText);

         r.x := APosition.x + fw + (f.GetWidth() div 2);
         r.y := APosition.y;
         r.w := width - GetNonClientWidth();
         r.h := GetTitleHeight();

         f.WriteCentered(Title, r, [oxfpCenterVertical]);
         oxf.Stop();
      end;
   end;
end;

procedure RenderShadow();
var
   shadowSize: loopint;
   r: oxTRect;

begin
   shadowSize := Skin.Window.ShadowSize;

   r.x := APosition.x + shadowSize;
   r.w := GetTotalWidth() - shadowSize - fw;
   r.y := APosition.y - GetTotalHeight();
   r.h := shadowSize;

   SetColor(colors^.Shadow);
   uiDraw.Box(r);

   r.x := APosition.x + GetTotalWidth() - fw;
   r.w := shadowSize + fw;
   r.y := APosition.y - shadowSize;
   r.h := GetTotalHeight();

   uiDraw.Box(r);
end;

begin
   {check if we can render the window}
   if(IsVisible()) then begin
      {determine if the window is selected}
      wSelected := IsSelected();

      if(wSelected) then
         colors := @Skin.Window.Colors
      else
         colors := @Skin.Window.InactiveColors;

      {if it's a sub-window we can render it's shape}
      if(Parent <> nil) then begin
         f := oxui.GetDefaultFont();

         width  := GetTotalWidth();
         fw := GetFrameWidth();
         fh := GetFrameHeight();

         if(uiwndpDROP_SHADOW in Properties) then
            RenderShadow();

         RenderWnd();

         uiDraw.Scissor(RPosition.x, RPosition.y, Dimensions.w, Dimensions.h);
      end;

      {notify of surface rendering}
      Notification(uiWINDOW_RENDER_SURFACE);

      {render the window}
      Render();

      {render window widgets}
      uiWidget.Render(uiTWidgets(Widgets));

      {render sub-windows}
      if(self.W.w.n > 0) then
         RenderSubWindows();

      if(Parent <> nil) then
         uiDraw.DoneScissor();

      {render non-client widgets}
      uiWidget.RenderNonClient(uiTWidgets(Widgets));

      uiWindow.OnPostRender.Call(Self);
      OnPostRender();

      Notification(uiWINDOW_RENDER_POST);
   end;
end;

procedure uiTWindowHelper.SetColor(r, g, b, a: byte);
begin
   a := round(opacity * a);

   oxui.Material.ApplyColor('color', r, g, b, a);
end;

procedure uiTWindowHelper.SetColor(r, g, b, a: single);
begin
   a := opacity * a;

   oxui.Material.ApplyColor('color', r, g, b, a);
end;

procedure uiTWindowHelper.SetColor(color: TColor4ub);
begin
   color[3] := round(opacity * color[3]);

   oxui.Material.ApplyColor('color', color);
end;

procedure uiTWindowHelper.SetColor(color: TColor4f);
begin
   oxui.Material.ApplyColor('color', color);
end;

procedure uiTWindowHelper.SetColorBlended(r, g, b, a: byte);
begin
   a := round(opacity * a);

   oxui.Material.ApplyColor('color', r, g, b, a);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetColorBlended(r, g, b, a: single);
begin
   a := opacity * a;

   oxui.Material.ApplyColor('color', r, g, b, a);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetColorBlended(color: TColor4ub);
begin
   color[3] := round(opacity * color[3]);

   oxui.Material.ApplyColor('color', color);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetColorBlended(color: TColor4f);
begin
   color[3] := opacity * color[3];

   oxui.Material.ApplyColor('color', color);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetSkin(newSkin: uiTSkin);
begin
   Skin := newSkin;
end;

procedure uiTWindowGlobal.RenderPrepare(wnd: oxTWindow);
var
   m: TMatrix4f;

begin
   m := oxTTransform.OrthoFrustum(0 + 0.375, wnd.Dimensions.w + 0.375, 0 + 0.375, wnd.Dimensions.h + 0.375, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);
   oxui.Material.Apply();

   uiDraw.Start();
end;

procedure uiTWindowGlobal.Render(wnd: oxTWindow);
begin
   if(uiwndpVISIBLE in uiTWindow(wnd).Properties) then begin
      RenderPrepare(wnd);
      uiTWindow(wnd).RenderWindow();
      uiWindow.OxwPostRender.Call(wnd);
   end;
end;

procedure uiTWindowGlobal.RenderAll();
var
   i: longint;

begin
   for i := 0 to (oxWindows.n - 1) do
      Render(oxWindows.w[i]);
end;

{ INTERNAL }
procedure uiTWindowHelper.UpdatePositions();
var
   i: longint;
   child,
   ext: uiTWindow;

begin
   if(Parent <> nil) then begin
      {update relative positions}
      RPosition := Parent.RPosition;

      inc(RPosition.x, Position.x + GetFrameWidth());
      dec(RPosition.y, (parent.Dimensions.h - Position.y - 1) + GetTitleHeight());

      APosition.x := RPosition.x - GetFrameWidth();
      APosition.y := RPosition.y + GetTitleHeight();
   end else begin
      ext := oxTWindow(wnd).ExternalWindow;

      if(ext = nil) then begin
         RPosition.x := 0;
         RPosition.y := Dimensions.h - 1;
      end else begin
         RPosition.x := 0;
         RPosition.y := ext.Dimensions.h - 1;
      end;

      APosition := RPosition;
   end;

   {update the widgets}
   for i := 0 to (Widgets.w.n - 1) do
      uiTWidget(Widgets.w[i]).PositionUpdate();

   {update the children windows}
   for i := 0 to (W.w.n - 1) do begin
      child := uiTWindow(W.w[i]);

      if(child <> nil) then
         child.UpdatePositions();
   end;

   RPositionChanged();
end;

procedure uiTWindowHelper.UpdateParentSize(selfNotify: boolean = true);
var
   i: longint;
   child: uiTWindow;

begin
   {update the widgets}
   for i := 0 to (Widgets.w.n - 1) do
      uiTWidget(Widgets.w[i]).UpdateParentSize();

   {update the children windows}
   for i := 0 to (W.w.n - 1) do begin
      child := uiTWindow(W.w[i]);

      if(child <> nil) then
         child.UpdateParentSize();
   end;

   if(selfNotify) then
      ParentSizeChange();
end;

procedure uiTWindowHelper.AdjustPosition();
begin
   inc(Position.x, GetFrameWidth());
   dec(Position.y, GetTitleHeight());
end;

procedure uiTWindowHelper.AdjustPosition(x, y: longint; var p: oxTPoint);
begin
   p.x := x + GetFrameWidth();
   p.y := y - GetTitleHeight();
end;

procedure uiTWindowHelper.AdjustDimensions(var d: oxTDimensions);
begin
   d.w := d.w - GetNonClientWidth();
   d.h := d.h - GetNonClientHeight();
end;

function uiTWindowHelper.GetCenterPosition(): oxTPoint;
var
   d: oxTDimensions;

begin
   d := GetTotalDimensions();

   if(Parent <> nil) then begin
      Result.x := (Parent.Dimensions.w div 2) - (d.w div 2);
      Result.y := (Parent.Dimensions.h div 2) + (d.h div 2);
   end else begin
      {TODO: Get screen center position}
      Result.x := 0;
      Result.y := 0;
   end;
end;

procedure uiTWindowHelper.AutoCenter();
begin
   if(Parent <> nil) then
      Move(GetCenterPosition());
end;

procedure uiTWindowHelper.QuitOnEscape();
begin
   Exclude(Properties, uiwndpNO_ESCAPE_KEY);
   Include(Properties, uiwndpQUIT_ON_CLOSE);
end;

procedure uiTWindowHelper.LockPointer();
begin
   LockPointer(0, 0);
end;

procedure uiTWindowHelper.LockPointer(x, y: single);
begin
   if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_NONE) then begin
      oxui.PointerCapture.Typ := uiPOINTER_CAPTURE_WINDOW;
      oxui.PointerCapture.Wnd := Self;
      oxui.PointerCapture.Point.Assign(x, y);

      oxui.PointerCapture.LockWindow();
   end;
end;

procedure uiTWindowHelper.UnlockPointer();
begin
   if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_WINDOW) then begin
      oxui.PointerCapture.Clear();
   end;
end;

procedure uiTWindowHelper.SetPointerCentered();
var
   x, y: single;

begin
   x := RPosition.x + Dimensions.w / 2;
   y := (oxwParent.Dimensions.h - 1 - RPosition.y) + (Dimensions.h / 2);

   appm.SetPosition(oxwParent, x, y);
end;

function uiTWindowHelper.FindHorizontalLineup(fitWithin: boolean): uiTPreallocatedWindowListArray;
var
   i: loopint;
   source,
   cur: uiTWindow;

begin
   Result.Initialize(Result);

   source := uiTWindow(Parent);
   for i := 0 to (source.W.w.n - 1) do begin
      cur := uiTWindow(source.W.w[i]);

      if(cur <> nil) and (cur <> Self) and (cur.IsVisible()) then begin
         if(not fitWithin) and (cur.Dimensions.h = Dimensions.h) and (cur.Position.y = Position.y) then
            Result.Add(cur)
         else if(fitWithin) and (cur.Position.y <= Position.y) and (cur.Position.y - cur.Dimensions.h >= Position.y - Dimensions.h) then
            Result.Add(cur);
      end;
   end;
end;

function uiTWindowHelper.FindVerticalLineup(fitWithin: boolean): uiTPreallocatedWindowListArray;
var
   i: loopint;
   source,
   cur: uiTWindow;

begin
   Result.Initialize(Result);

   source := uiTWindow(Parent);
   for i := 0 to (source.W.w.n - 1) do begin
      cur := uiTWindow(source.W.w[i]);

      if(cur <> nil) and (cur <> Self) and (cur.IsVisible()) then begin
         if(not fitWithin) and (cur.Dimensions.w = Dimensions.w) and (cur.Position.x = Position.x) then
            Result.Add(cur)
         else if(fitWithin) and (cur.Position.x >= Position.x) and (cur.Position.x + cur.Dimensions.w <= Position.x + Dimensions.w) then
            Result.Add(cur);
      end;
   end;
end;

function uiTWindowHelper.FindType(wndType: uiTWindowClass): uiTPreallocatedWindowListArray;
var
   i: loopint;
   cur: uiTWindow;

begin
   Result.Initialize(Result);

   for i := 0 to (W.w.n - 1) do begin
      cur := uiTWindow(W.w[i]);

      if(cur <> nil) then begin
         if(cur.IsType(wndType)) then
            Result.Add(cur);
      end;
   end;
end;

procedure uiTWindowHelper.FindTypeRecursive(wndType: uiTWindowClass; var windows: uiTPreallocatedWindowListArray);
var
   i: loopint;
   cur: uiTWindow;

begin
   for i := 0 to (W.w.n - 1) do begin
      cur := uiTWindow(W.w[i]);

      if(cur <> nil) then begin
         if(cur.IsType(wndType)) then begin
            windows.Add(cur);
         end;
      end;
   end;

   for i := 0 to (W.w.n - 1) do begin
      cur := uiTWindow(W.w[i]);

      if(cur <> nil) then begin
         cur.FindTypeRecursive(wndType, windows);
      end;
   end;
end;

function uiTWindowHelper.GetParentOfType(whatType: uiTWindowClass): uiTWindow;
begin
   Result := uiTWindow(uiTControl(Self).GetParentOfType(whatType));
end;

function uiTWindowHelper.IsType(whatType: uiTWindowClass): boolean;
begin
   Result := uiTControl(Self).IsType(whatType);
end;

{ Z Order}

function uiTWindowHelper.GetTitleHeight(): longint;
begin
   Result := Skin.Window.Frames[ord(Frame)].TitleHeight;
end;

function uiTWindowHelper.GetFrameWidth(): longint;
begin
   Result := Skin.Window.Frames[ord(Frame)].FrameWidth;
end;

function uiTWindowHelper.GetFrameHeight(): longint;
begin
   Result := Skin.Window.Frames[ord(Frame)].FrameHeight;
end;

function uiTWindowHelper.GetNonClientHeight(): longint; inline;
begin
   if(Frame <> uiwFRAME_STYLE_NONE) then
      Result := GetTitleHeight() + GetFrameHeight()
   else
      Result := 0;
end;

function uiTWindowHelper.GetNonClientWidth(): longint; inline;
begin
   if(Frame <> uiwFRAME_STYLE_NONE) then
      Result := GetFrameWidth() * 2
   else
      Result := 0;
end;

function uiTWindowHelper.GetTotalWidth(): loopint;
begin
   Result := Dimensions.w + GetNonClientWidth();
end;

function uiTWindowHelper.GetTotalHeight(): loopint;
begin
   Result := Dimensions.h + GetNonClientHeight();
end;


procedure uiTWindowHelper.GetRect(out r: oxTRect);
begin
   r.x := Position.x;
   r.y := Position.y;
   r.w := Dimensions.w + GetNonClientWidth();
   r.h := Dimensions.h + GetNonClientHeight();
end;

function uiTWindowHelper.GetTotalDimensions(): oxTDimensions;
begin
   Result.w := Dimensions.w + GetNonClientWidth();
   Result.h := Dimensions.h + GetNonClientHeight();
end;

function uiTWindowHelper.ContentDimensions(spacing: loopint): oxTDimensions;
var
   i,
   lx, {left y}
   ty, {top y}
   rx, {right x}
   by: {bottom y} loopint;
   wdg: uiTWidget;

   first: boolean;

begin
   Result := oxNullDimensions;

   if(Widgets.w.n > 0) then begin
      first := false;
      lx := 0;
      ty := 0;
      rx := 0;
      by := 0;

      for i := 0 to Widgets.w.n - 1 do begin
         wdg := uiTWidget(Widgets.w[i]);

         if(not (wdgpNON_CLIENT in wdg.Properties)) then begin
            if(first) then begin
               if(wdg.Position.x < lx) then
                  lx := wdg.Position.x;

               if(wdg.Position.y > ty) then
                  ty := wdg.Position.y;

               if(wdg.Position.x + wdg.Dimensions.w - 1 > rx) then
                  rx := wdg.Position.x + wdg.Dimensions.w - 1;

               if(wdg.Position.y - wdg.Dimensions.h + 1 < by) then
                  by := wdg.Position.y - wdg.Dimensions.h + 1;
            end else begin
               lx := wdg.Position.x;
               ty := wdg.Position.y;
               rx := wdg.Position.x + wdg.Dimensions.w - 1;
               by := wdg.Position.y - wdg.Dimensions.h + 1;

               first := true;
            end;
         end;
      end;

      if(spacing = -1) then
         spacing := wdgDEFAULT_SPACING * 2;

      Result.w := rx - lx - 1 + spacing;
      Result.h := ty - by - 1 + spacing;
   end;
end;

procedure uiTWindowHelper.ContentAutoSize();
var
   d: oxTDimensions;

begin
   d := ContentDimensions();

   Resize(d);
   UpdatePositions();
end;

{ EVENTS }

{is a window visible}
function uiTWindowHelper.IsVisible(): boolean;
begin
   Result :=
      (not (uiwndpCLOSED in Properties)) and
           (uiwndpVISIBLE in Properties) and
      (not (uiwndpMINIMIZED in Properties));
end;

function uiTWindowHelper.IsOpen(): boolean;
begin
   Result := not (uiwndpCLOSED in Properties);
end;

function uiTWindowGlobal.GetNotification(const event: appTEvent): uiTWindowEvents;
begin
   if(event.hID = uievhpWINDOW) then
      exit(uiTWindowEvents(event.evID));

   Result := uiWINDOW_EVENT_NONE;
end;

procedure Initialize();
begin
   uiWindow.EscapeKeys := appTKeyList.Create('uiWindow.EscapeKeys');
   {list of confirmation keys, used for the default confirmation action}
   uiWindow.ConfirmationKeys := appTKeyList.Create('uiWindow.ConfirmationKeys');

   uiWindow.EscapeKeys.Add(uiWindow.DefaultEscapeKey);
   uiWindow.EscapeKeys.Add(uiWindow.BackEscapeKey);
   uiWindow.ConfirmationKeys.Add(uiWindow.DefaultConfirmationKey);
end;

procedure DeInitialize();
begin
   FreeObject(uiWindow.EscapeKeys);
   FreeObject(uiWindow.ConfirmationKeys);
end;

procedure actionHandler(var ev: appTEvent);
begin
   if(ev.evID = wndevDISPOSE) then
      uiWindow.Dispose(uiTWindow(ev.wnd))
   else if(ev.evID = wndevSELECT) then
      uiTWindow(ev.wnd).Select()
   else if(ev.evID = wndevCLOSE) then
      uiTWindow(ev.wnd).Close();
end;

INITIALIZATION
   {set defaults}
   uiWindow.AutoRender := true;
   uiWindow.ListenerAllocationStep := 8;
   uiWindow.DefaultButtons := uiwbCLOSE or uiwbMINIMIZE or uiwbMAXIMIZE;

   {this is done here instead of in uiuWindow because of circular reference}
   uiTWindowGlobalOn.Initialize(uiWindow.OnCreate);
   uiTWindowGlobalOn.Initialize(uiWindow.OnDestroy);
   uiTWindowGlobalOn.Initialize(uiWindow.OnPostRender);
   uiTWindowGlobalOn.Initialize(uiWindow.OxwPostRender);

   if(uiWindow.OnCreate.Increment = 0) then
      uiTWindowGlobalOn.Initialize(uiWindow.OnCreate);
   if(uiWindow.OnDestroy.Increment = 0) then
      uiTWindowGlobalOn.Initialize(uiWindow.OnDestroy);
   if(uiWindow.OnPostRender.Increment = 0) then
      uiTWindowGlobalOn.Initialize(uiWindow.OnPostRender);
   if(uiWindow.OxwPostRender.Increment = 0) then
      uiTWindowGlobalOn.Initialize(uiWindow.OxwPostRender);

   uiWindow.DefaultProperties := [uiwndpENABLED,
      uiwndpVISIBLE,
      uiwndpMOVABLE,
      uiwndpRESIZABLE,
      uiwndpMOVE_BY_SURFACE,
      uiwndpSELECTABLE,
      uiwndpCLOSE_SELECT,
      uiwndpDROP_SHADOW];

   uiWindow.RootDefaultButtons    := 0;
   uiWindow.SizeBorder := 6;

   uiWindow.RootDefaultProperties := uiWindow.defaultProperties;
   uiWindow.RootDefaultProperties := uiWindow.RootDefaultProperties +
      [uiwndpQUIT_ON_CLOSE,
      uiwndpAUTO_CENTER];
   uiWindow.RootDefaultProperties := uiWindow.RootDefaultProperties -
      [uiwndpRESIZABLE,
      uiwndpMOVE_BY_SURFACE];

   uiWindow.DefaultEscapeKey        := defaultEscapeKey;
   uiWindow.BackEscapeKey           := backEscapeKey;
   uiWindow.DefaultConfirmationKey  := defaultConfirmationKey;
   uiWindow.DefaultBackground       := defaultBackground;

   {initialize default values}
   uiWindow.RestoreCreateDefaults();

   uiWindow.CloseKey.Assign(kcF4, kmCONTROL);
   uiWindow.NextWindowKey.Assign(kcTAB, kmCONTROL);
   uiWindow.PreviousWindowKey.Assign(kcTAB, kmCONTROL or kmSHIFT);

   oxui.BaseInitializationProcs.Add('window', @Initialize, @DeInitialize);

   {events}
   uiWindow.evhp := appEvents.AddHandler(uiWindow.evh, 'ox.uiwindow', @actionHandler);

END.
