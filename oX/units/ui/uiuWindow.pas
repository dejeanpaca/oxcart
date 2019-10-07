{
   uiuWindow, UI window management
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuWindow;

INTERFACE

   USES
      uStd, uLog, uColors,
      {app}
      uApp, appuEvents, appuKeys, appuActionEvents, appuMouse,
      {oX}
      oxuRunRoutines, oxuTypes, oxuWindows, oxuResourcePool,
      oxuWindowTypes, oxuRender,
      oxuTexture, oxuTextureGenerate,
      {ui}
      uiuBase, oxuUI, uiuSkin, uiuZOrder, uiuTypes, uiuControl, uiuSkinTypes,
      uiuWindowTypes, uiuWidget, uiWidgets;

CONST
   wndevDISPOSE = 1;
   wndevSELECT = 2;
   wndevCLOSE = 3;

   WINDOW_HIGHLIGHT_MULTIPLIER: single = 1.25;

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
      {base UI object}
      UIBase: oxTUI;

      {minimum size for the created window}
      MinimumSize,
      {maximum size for the created window}
      MaximumSize: oxTDimensions;
   end;

   { uiTWindowHelper }

   uiTWindowHelper = class helper for uiTWindow
      {get the base UI object}
      function GetUI(): oxTUI;

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
      function GetPointerPosition(x, y: loopint): oxTPoint;

      {moves a window}
      procedure Move(x, y: loopint);
      procedure Move(position: oxTPoint);

      procedure MoveAdjusted(x, y: loopint);
      procedure MoveAdjusted(const p: oxTPoint);
      {move a the window for a relative position}
      procedure MoveRelative(x, y: loopint);
      procedure MoveRelative(p: oxTPoint);

      {resizes a window}
      procedure Resize(w, h: loopint; ignoreRestrictions: boolean = false);
      procedure Resize(newSize: oxTDimensions; ignoreRestrictions: boolean = false);

      procedure ResizeAdjusted(w, h: loopint; ignoreRestrictions: boolean = false);
      procedure ResizeAdjusted(const newSize: oxTDimensions; ignoreRestrictions: boolean = false);

      {adjust width and height according to window restrictions}
      procedure AdjustSizesWithRestrictions(var w, h: loopint);
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

      procedure SetHandler(listener: uiTWindowListenerMethod);

      {adds a listener to the list, returns true if added}
      function AddListener(listener: uiTWindowListenerMethod): boolean;
      {removes a listener from the list, returns true if the listener specified was found in the list}
      function RemoveListener(listener: uiTWindowListenerMethod): boolean;
      {removes all listeners}
      procedure RemoveListeners();

      { size }

      {get the title height}
      function GetTitleHeight(): loopint;
      {get the frame width and height}
      function GetFrameWidth(): loopint;
      function GetFrameHeight(): loopint;
      {get the total non-client height of the window}
      function GetNonClientHeight(): loopint;
      {get the total non-client width of the window}
      function GetNonClientWidth(): loopint;
      {get total width (including non-client)}
      function GetTotalWidth(): loopint;
      {get total height (including non-client)}
      function GetTotalHeight(): loopint;
      {gets a rectangle for the specified window}
      procedure GetRect(out r: oxTRect);

      {get the window icon dimensions}
      function GetIconDimensions(): oxTDimensions;

      {get total dimensions, both client and non-client area}
      function GetTotalDimensions(): oxTDimensions;
      {compute dimensions required to fit all content (widgets)}
      function ContentDimensions(spacing: loopint = -1): oxTDimensions;
      {auto size to fit all content}
      procedure ContentAutoSize();

      {move widgets by offset}
      procedure MoveWidgetsOffset(x, y: loopint);
      procedure MoveNonClientWidgetsOffset(x, y: loopint);

      { window rendering }
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
      function SetBackground(const fn: StdString): loopint;

      {background texture type}
      procedure SetBackgroundFit(fit: uiTWindowBackgroundFit);
      procedure SetBackgroundTexture(tex: oxTTexture; fit: uiTWindowBackgroundFit);
      procedure SetBackgroundTextureTiling(tileX, tileY: single);

      {dispose of the background}
      procedure DisposeBackground();

      {set window texture}
      procedure SetIcon(tex: oxTTexture);
      {set window texture from file}
      function SetIcon(const fn: string): loopint;
      {dispose of the icon}
      procedure DisposeIcon();

      { finding windows }

      {finds a window and returns selection}
      procedure Find(x, y: loopint; var s: uiTSelectInfo);
      {find the first child of the specified class, specifying recursive if you want to all levels}
      function Find(c: uiTWindowClass; recursive: boolean = false): uiTWindow;

      {returns the top level parent window, or the specified window if it has no parent}
      function GetTopLevel(): uiTWindow;
      {checks whether a window exists at any level within this window and returns its level}
      function Exists(pwnd: uiTWindow; sub: boolean = true): loopint;
      {checks whether a window exists in this window and returns its index}
      function ExistChild(pwnd: uiTWindow): loopint;

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
      procedure AdjustPosition(x, y: loopint; var p: oxTPoint);
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
      function FindHorizontalLineup(fitWithin: boolean = false): uiTSimpleWindowList;
      {find all windows lined up horizontally with us}
      function FindVerticalLineup(fitWithin: boolean = false): uiTSimpleWindowList;

      {find all windows of a given type}
      function FindType(wndType: uiTWindowClass): uiTSimpleWindowList;
      {find all windows of a given type recursively}
      procedure FindTypeRecursive(wndType: uiTWindowClass; var windows: uiTSimpleWindowList);

      {find a parent of the specified type, otherwise returns nil}
      function GetParentOfType(whatType: uiTWindowClass): uiTWindow;
      {checks if the window is of the specified type}
      function IsType(whatType: uiTWindowClass): boolean;
   end;


   { uiTWindowGlobalOn }

   uiTWindowOnRoutine = procedure(wnd: uiTWindow);

   {handles window oncreate callbacks}
   uiTWindowGlobalOn = specialize TSimpleList<uiTWindowOnRoutine>;

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
      ListenerAllocationStep: loopint;

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
      DefaultDimensions: oxTDimensions;

      {routines to call whenever a window is created}
      OnCreate,
      {routines to call whenever a window is destroyed}
      OnDestroy,
      {routines to call whenever a window rendering has finished}
      OnPostRender,
      {routines to call whenever an ox window rendering has finished}
      OxwPostRender: uiTWindowGlobalOn;

      {default icon}
      DefaultIcon: oxTTexture;
      {use default icon if no other icon is set}
      UseDefaultIcon: boolean;

      {checks if the window is of the specified type}
      function IsType(wnd, whatType: uiTWindowClass): boolean;

      { WINDOW CREATION }
      {setup a created window}
      procedure SetupCreatedWindow(wnd: uiTWindow; var createData: uiTWindowCreateData);

      {creates a window}
      function Make(var createData: uiTWindowCreateData; out wnd: uiTWindow; const title: StdString;
               position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod = nil): loopint;
      function Make(wnd: uiTWindow; const title: StdString;
               position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod = nil): loopint;
      {creates a child window whose parent is wnd}
      function MakeChild(var createData: uiTWindowCreateData; wnd: uiTWindow; const title: StdString;
               const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod = nil): uiTWindow;
      function MakeChild(wnd: uiTWindow; const title: StdString;
               const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod = nil): uiTWindow;
      function MakeChild(wnd: uiTWindow): uiTWindow;

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
      function SelectionEqu(const s1, s2: uiTSelectInfo): loopint;

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


{ uiTWindowGlobalOnCreateHelper }

procedure uiTWindowGlobalOnHelper.Call(wnd: uiTWindow);
var
   i: loopint;

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
   {set window parent}
   if(createData.Parent <> nil) then begin
      wnd.Parent := createData.Parent;

      createData.oxwParent := oxTWindow(createData.Parent.oxwParent);
   end;

   wnd.oxwParent := createData.oxwParent;

   {set the base UI object if this is an oxTWindow}
   if(wnd.oxwParent = wnd) or (wnd.oxwParent = nil) then
      oxTWindow(wnd).UIBase := createData.UIBase;

   {setup properties}

   assert(wnd.GetUI() <> nil, 'Tried to create a window with no base ui set in creation data');

   wnd.SetSkin(wnd.GetUI().DefaultSkin);

   wnd.Background       := uiWindow.DefaultBackground;

   if(uiTSkin(wnd.Skin).Window.Textures.Background <> nil) then
      wnd.SetBackgroundTexture(uiTSkin(wnd.Skin).Window.Textures.Background, uiwBACKGROUND_TEX_FIT);

   wnd.SetBackgroundColor(uiTSkin(wnd.Skin).Window.Colors.cBackground);

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

   {set window data}
   uiSkin.SetWindowDefault(wnd);
   wnd.Frame := createData.Frame;

   if(uiWindow.UseDefaultIcon) then
      wnd.SetIcon(uiWindow.DefaultIcon);

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
   if(wnd.GetUI().Select.GetSelectedWnd() = nil) then
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

function uiTWindowGlobal.Make(var createData: uiTWindowCreateData; out wnd: uiTWindow; const title: StdString;
      position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod): loopint;

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
      wnd.SetHandler(wHandler);

      uiWidget.LastRect.Assign(wnd);
   end else
      exit(eNO_MEMORY);
end;

function uiTWindowGlobal.Make(wnd: uiTWindow; const title: StdString;
      position: oxTPoint; dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod): loopint;
begin
   Result := Make(Create, wnd, title, position, dimensions, wHandler);
end;

function uiTWindowGlobal.MakeChild(var createData: uiTWindowCreateData; wnd: uiTWindow; const title: StdString;
         const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod): uiTWindow;
var
   errcode: loopint;
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

function uiTWindowGlobal.MakeChild(wnd: uiTWindow; const title: StdString;
         const position: oxTPoint; const dimensions: oxTDimensions; wHandler: uiTWindowListenerMethod): uiTWindow;
begin
   Result := MakeChild(Create, wnd, title, position, dimensions, wHandler);
end;

function uiTWindowGlobal.MakeChild(wnd: uiTWindow): uiTWindow;
begin
   Result := MakeChild(Create, wnd, '', oxNullPoint, uiWindow.DefaultDimensions);
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

   {starting to destroy}
   wnd.OnDestroy();

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

   wnd.GetUI().Select.Deselect(uiTControl(wnd));
   wnd.GetUI().mSelect.Deselect(uiTControl(wnd));

   Destroyed(wnd);

   wnd.DisposeBackground();
   wnd.DisposeIcon();

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

   if(wnd.GetUI().UseWindow = wnd) then
      wnd.GetUI().UseWindow := nil;

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

function uiTWindowHelper.AddListener(listener: uiTWindowListenerMethod): boolean;
begin
   Result := Listeners.Add(uiTWindowListener(listener));
end;

function uiTWindowHelper.RemoveListener(listener: uiTWindowListenerMethod): boolean;
var
   i: loopint;
   where: loopint = -1;

begin
   for i := 0 to Listeners.n - 1 do begin
      if(Listeners[i] = uiTWindowListener(listener)) then begin
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
   i: loopint;

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
      if(GetUI().PointerCapture.Wnd = Self) then
         GetUI().PointerCapture.Clear();

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

         Move(p);
         Resize(d);

         SetFrameStyle(uiwFRAME_STYLE_NONE);

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

   if(not (uiwndpDESTRUCTION_IN_PROGRESS in Properties)) then
      UpdatePositions();
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
   i: loopint;
   wdg: uiTWidget;
   x,
   rightX,
   y,
   bottomY,
   w,
   h: loopint;

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

function uiTWindowHelper.GetPointerPosition(x, y: loopint): oxTPoint;
begin
   Result.x := x - (RPosition.x + GetFrameWidth());
   Result.y := y - RPosition.y + Dimensions.h - 1;
end;

{ WINDOW MANAGEMENT }
procedure uiTWindowHelper.Move(x, y: loopint);
begin
   if(x <> Position.x) or (y <> Position.y) then begin
      Position.x := x;
      Position.y := y;

      Notification(uiWINDOW_MOVE);
      UpdatePositions();
   end;
end;

procedure uiTWindowHelper.Move(position: oxTPoint);
begin
   Move(position.x, position.y);
end;

procedure uiTWindowHelper.MoveAdjusted(x, y: loopint);
begin
   Move(x + GetFrameWidth() - 1, y - GetTitleHeight() - 1);
end;

procedure uiTWindowHelper.MoveAdjusted(const p: oxTPoint);
begin
   MoveAdjusted(p.x, p.y);
end;

procedure uiTWindowHelper.MoveRelative(x, y: loopint);
begin
   if(x <> 0) or (y <> 0) then
      Move(Position.x + x, Position.y + y)
end;

procedure uiTWindowHelper.MoveRelative(p: oxTPoint);
begin
   if(p.x <> 0) or (p.y <> 0) then
      Move(Position.x + p.x, Position.y + p.y);
end;

procedure uiTWindowHelper.Resize(w, h: loopint; ignoreRestrictions: boolean);
var
   horizontalMove: boolean;

begin
   if(not ignoreRestrictions) then begin
      AdjustSizesWithRestrictions(w, h);
   end else begin
      if(w < 0) then
         w := 0;

      if(h < 0) then
         h := 0;
   end;

   horizontalMove := h <> Dimensions.h;

   if(w <> Dimensions.w) or (horizontalMove) then begin
      PreviousDimensions := Dimensions;
      Dimensions.w := w;
      Dimensions.h := h;

      Notification(uiWINDOW_RESIZE);
      SizeChanged();

      if(horizontalMove) then
         {we have to update RPositions and other data}
         UpdatePositions();

      UpdateParentSize(false);
   end;
end;

procedure uiTWindowHelper.Resize(newSize: oxTDimensions; ignoreRestrictions: boolean = false);
begin
   Resize(newSize.w, newSize.h, ignoreRestrictions);
end;

procedure uiTWindowHelper.ResizeAdjusted(w, h: loopint; ignoreRestrictions: boolean = false);
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

procedure uiTWindowHelper.AdjustSizesWithRestrictions(var w, h: loopint);
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

   data.UIBase := oxui;
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

function uiTWindowHelper.SetBackground(const fn: StdString): loopint;
begin
   Result := oxTextureGenerate.Generate(fn, oxTTexture(Background.Texture));

   if(Result = 0) then begin
      Background.Typ := uiwBACKGROUND_TEX;
      Background.Color := cWhite4ub;
   end;
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

procedure uiTWindowHelper.SetIcon(tex: oxTTexture);
begin
   DisposeIcon();

   Icon := tex;
end;

function uiTWindowHelper.SetIcon(const fn: string): loopint;
var
   tex: oxTTexture;

begin
   Result := oxTextureGenerate.Generate(fn, tex);
   SetIcon(tex);

   {TODO: Set system icon}
end;

procedure uiTWindowHelper.DisposeIcon();
begin
   if(Icon <> nil) and (uiWindow.DefaultIcon <> Icon) then
      oxResource.Destroy(Icon);

   {TODO: Dispose system icon}
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
   Result := (Level <= GetUI().Select.l) and (GetUI().Select.s[Level] = Self);
end;

function uiTWindowHelper.GetUI(): oxTUI;
begin
   if(oxwParent <> nil) then
      Result := oxTUI(oxTWindow(oxwParent).UIBase)
   else
      Result := oxTUI(oxTWindow(Self).UIBase);
end;

procedure uiTWindowHelper.Select();
var
   i: loopint;
   selected: uiTControl;
   previouslySelected: uiTWindow;
   previouslySelectedWdg: uiTWidget;

begin
   selected := GetUI().Select.Selected;
   previouslySelected := GetUI().Select.GetSelectedWnd();
   previouslySelectedWdg := GetUI().Select.GetSelectedWdg();

   if(selected <> Self) then begin
      GetUI().Select.Assign(uiTControl(Self));

      GetUI().UseWindow := Self;

      if(previouslySelected <> Self) then begin
         {move the window and all it's parents to the top of the z order}
         for i := 0 to GetUI().Select.l do begin
            if(i > 0) and (GetUI().Select.s[i - 1].ControlType = uiCONTROL_WINDOW) then
               uiTWindow(GetUI().Select.s[i - 1]).w.z.MoveToTop(GetUI().Select.s[i])
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
   sWnd,
   pWnd: uiTWindow;

begin
   GetUI().mSelect.Deselect(uiTControl(Self));

   if(not IsSelected()) then
      exit;

   GetUI().Select.Deselect(uiTControl(Self));

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

function uiTWindowGlobal.SelectionEqu(const s1, s2: uiTSelectInfo): loopint;
var
   i,
   rep_end: loopint;

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
procedure uiFindNext(parentWdg: uiTWidget; const widgets: uiTWidgets; x, y: loopint; var s: uiTSelectInfo);
var
   r: oxTRect;
   i: loopint;
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

procedure uiFindNext(wnd: uiTWindow; x, y: loopint; var s: uiTSelectInfo);
var
   r: oxTRect;
   i: loopint;
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


procedure uiTWindowHelper.Find(x, y: loopint; var s: uiTSelectInfo);
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
function uiTWindowHelper.Exists(pwnd: uiTWindow; sub: boolean): loopint;
var
   i: loopint;

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

function uiTWindowHelper.ExistChild(pwnd: uiTWindow): loopint;
var
   i: loopint;

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

{ WINDOW RENDERING }

procedure uiTWindowHelper.SetColor(r, g, b, a: byte);
begin
   a := round(opacity * a);

   GetUI().Material.ApplyColor('color', r, g, b, a);
end;

procedure uiTWindowHelper.SetColor(r, g, b, a: single);
begin
   a := opacity * a;

   GetUI().Material.ApplyColor('color', r, g, b, a);
end;

procedure uiTWindowHelper.SetColor(color: TColor4ub);
begin
   color[3] := round(opacity * color[3]);

   GetUI().Material.ApplyColor('color', color);
end;

procedure uiTWindowHelper.SetColor(color: TColor4f);
begin
   GetUI().Material.ApplyColor('color', color);
end;

procedure uiTWindowHelper.SetColorBlended(r, g, b, a: byte);
begin
   a := round(opacity * a);

   GetUI().Material.ApplyColor('color', r, g, b, a);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetColorBlended(r, g, b, a: single);
begin
   a := opacity * a;

   GetUI().Material.ApplyColor('color', r, g, b, a);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetColorBlended(color: TColor4ub);
begin
   color[3] := round(opacity * color[3]);

   GetUI().Material.ApplyColor('color', color);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetColorBlended(color: TColor4f);
begin
   color[3] := opacity * color[3];

   GetUI().Material.ApplyColor('color', color);
   oxRender.EnableBlend();
end;

procedure uiTWindowHelper.SetSkin(newSkin: uiTSkin);
begin
   Skin := newSkin;
end;

{ INTERNAL }
procedure uiTWindowHelper.UpdatePositions();
var
   i: loopint;
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
   i: loopint;
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

procedure uiTWindowHelper.AdjustPosition(x, y: loopint; var p: oxTPoint);
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
   if(GetUI().PointerCapture.Typ = uiPOINTER_CAPTURE_NONE) then begin
      GetUI().PointerCapture.Typ := uiPOINTER_CAPTURE_WINDOW;
      GetUI().PointerCapture.Wnd := Self;
      GetUI().PointerCapture.Point.Assign(x, y);

      GetUI().PointerCapture.LockWindow();
   end;
end;

procedure uiTWindowHelper.UnlockPointer();
begin
   if(GetUI().PointerCapture.Typ = uiPOINTER_CAPTURE_WINDOW) then begin
      GetUI().PointerCapture.Clear();
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

function uiTWindowHelper.FindHorizontalLineup(fitWithin: boolean): uiTSimpleWindowList;
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

function uiTWindowHelper.FindVerticalLineup(fitWithin: boolean): uiTSimpleWindowList;
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

function uiTWindowHelper.FindType(wndType: uiTWindowClass): uiTSimpleWindowList;
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

procedure uiTWindowHelper.FindTypeRecursive(wndType: uiTWindowClass; var windows: uiTSimpleWindowList);
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

function uiTWindowHelper.GetTitleHeight(): loopint;
begin
   Result := uiTSkin(Skin).Window.Frames[ord(Frame)].TitleHeight;
end;

function uiTWindowHelper.GetFrameWidth(): loopint;
begin
   Result := uiTSkin(Skin).Window.Frames[ord(Frame)].FrameWidth;
end;

function uiTWindowHelper.GetFrameHeight(): loopint;
begin
   Result := uiTSkin(Skin).Window.Frames[ord(Frame)].FrameHeight;
end;

function uiTWindowHelper.GetNonClientHeight(): loopint; inline;
begin
   if(Frame <> uiwFRAME_STYLE_NONE) then
      Result := GetTitleHeight() + GetFrameHeight()
   else
      Result := 0;
end;

function uiTWindowHelper.GetNonClientWidth(): loopint; inline;
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

function uiTWindowHelper.GetIconDimensions(): oxTDimensions;
begin
   if(Icon <> nil) then begin
      Result.w := round(GetTitleHeight() * 0.5);
      Result.h := Result.w;
   end else begin
      Result.w := 0;
      Result.h := 0;
   end;
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
   offsetY: loopint;

begin
   d := ContentDimensions();

   offsetY := d.h - Dimensions.h;

   Resize(d);
   MoveWidgetsOffset(0, offsetY);
end;

procedure uiTWindowHelper.MoveWidgetsOffset(x, y: loopint);
var
   i: loopint;

begin
   for i := 0 to Widgets.w.n - 1 do begin
      if(not (wdgpNON_CLIENT in uiTWidget(Widgets.w[i]).Properties)) then
         uiTWidget(Widgets.w[i]).MoveOffset(x, y);
   end;
end;

procedure uiTWindowHelper.MoveNonClientWidgetsOffset(x, y: loopint);
var
   i: loopint;

begin
   for i := 0 to Widgets.w.n - 1 do begin
      if(wdgpNON_CLIENT in uiTWidget(Widgets.w[i]).Properties) then
         uiTWidget(Widgets.w[i]).MoveOffset(x, y);
   end;
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

procedure uiTWindowHelper.SetHandler(listener: uiTWindowListenerMethod);
begin
   wHandler := uiTWindowListener(listener);
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

VAR
   initRoutines: oxTRunRoutine;

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
   uiWindow.DefaultDimensions.Assign(320, 240);
   uiWindow.UseDefaultIcon := true;

   {initialize default values}
   uiWindow.RestoreCreateDefaults();

   uiWindow.CloseKey.Assign(kcF4, kmCONTROL);
   uiWindow.NextWindowKey.Assign(kcTAB, kmCONTROL);
   uiWindow.PreviousWindowKey.Assign(kcTAB, kmCONTROL or kmSHIFT);

   ui.BaseInitializationProcs.Add(initRoutines, 'window', @Initialize, @DeInitialize);

   {events}
   uiWindow.evhp := appEvents.AddHandler(uiWindow.evh, 'ox.uiwindow', @actionHandler);

END.
