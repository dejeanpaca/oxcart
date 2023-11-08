{
   uiuWindowTypes, UI window
   Copyright (C) 2013. Dejan Boras

   Started On:    07.01.2013.
}

{$INCLUDE oxdefines.inc}
UNIT uiuWindowTypes;

INTERFACE

   USES
      uStd, uColors, vmVector, uTypeHelper,
      {app}
      appuEvents, appuKeys, appuMouse,
      {oX}
      oxuTypes,
      {ui}
      uiuControl, uiuControls, uiuTypes;

TYPE
   { WINDOWS }
   uiPWindowReference = ^uiTWindowReference;
   uiTWindowReference = record
      idx: longint;
      uid: QWord;
      wnd: TObject;
   end;

   {window background}
   uiTWindowBackground = record
      Typ: uiTWindowBackgroundType;
      Color: TColor4ub;
      Texture: TObject;
      Fit: uiTWindowBackgroundFit;
      Tile,
      Offset: TVector2f;
   end;

   {the window handler procedure}
   uiTWindowListener = function(wnd: uiTControl; const event: appTEvent): loopint;
   uiTWindowListeners = specialize TSimpleList<uiTWindowListener>;

   {a window}

   uiTWindowProperty = (
      uiwndpSYSTEM,
      uiwndpENABLED,
      uiwndpINITIALIZED,
      uiwndpVISIBLE,
      uiwndpMINIMIZED,
      uiwndpMAXIMIZED,
      uiwndpTRAYED,
      uiwndpRENDER_BACKGROUND,
      uiwndpRENDER_BEGIN_END,
      uiwndpMANUAL_RENDER,
      uiwndpRESIZABLE,
      uiwndpMOVABLE,
      uiwndpMOVE_BY_SURFACE,
      uiwndpMOVED,
      uiwndpQUIT_ON_CLOSE,
      uiwndpCLOSED,
      uiwndpNO_ESCAPE_KEY,
      uiwndpNO_CONFIRMATION_KEY,
      uiwndpNO_DISPOSE_OF_EXT_DATA,
      uiwndpAUTO_CENTER,
      uiwndpSELECTABLE,
      uiwndpCLOSE_SELECT,
      uiwndpDESTRUCTION_IN_PROGRESS,
      uiwndpDROP_SHADOW,
      uiwndpDISPOSED
   );

   uiTWindowProperties = set of uiTWindowProperty;

   { uiTWindowPropertiesHelper }

   uiTWindowPropertiesHelper = type helper for uiTWindowProperties
      procedure Immovable();
      function ToString(): StdString;
   end;

   uiPWindow = ^uiTWindows;
   { uiTWindows }
   uiTWindows = type uiTControls;

   { uiTWindow }

   uiTWindow = class(uiTControl)
      Title: StdString;

      {properties, internal properties and windows owner properties}
      Properties: uiTWindowProperties;

      {window ID and reference}
      ID: uiTControlID;

      {parent}
      wHandler: uiTWindowListener;

      {absolute position}
      APosition,
      {dimensions before maximization}
      MaximizedPosition: oxTPoint;
      {dimensions before maximization}
      MaximizedDimensions,
      {minimum size (if 0 no maximum size enforced)}
      MinimumSize,
      {maximum size (if 0 no maximum size enforced)}
      MaximumSize: oxTDimensions;

      {skin}
      Skin: TObject;
      {window icon}
      Icon: TObject;

      {properties}
      Background: uiTWindowBackground;
      Buttons: longword;
      Frame,
      MaximizedFrame: uiTWindowFrameStyle;
      Opacity: single;

      {window listeners}
      Listeners: uiTWindowListeners;

      {sub}
      W: uiTWindows;
      Widgets: uiTControls;

      {error code}
      ErrorCode: loopint;

      constructor Create(); override;

      procedure Action({%H-}action: uiTWindowEvents); virtual;

      {set the window ID}
      function SetTitle(const newTitle: StdString): uiTWindow; virtual;

      {set the window ID}
      function SetID(const wID: uiTControlID): uiTWindow;
      {get color of the underlying parent surface}
      function GetSurfaceColor: TColor4ub; override;

      public
         {called when window is maximized}
         procedure OnMaximize(); virtual;
         {called when window is minimized and can override the minimization by returning false}
         procedure OnMinimize(); virtual;
         {called when the window is closed}
         procedure OnOpen(); virtual;
         {called when the window is closed}
         procedure OnClose(); virtual;

         {called when dragging starts}
         procedure OnStartDrag(); virtual;
         {called when dragged}
         procedure OnDrag(); virtual;
         {called when dragging stops}
         procedure OnStopDrag(); virtual;
   end;

   uiTWindowListenerMethod = function(wnd: uiTWindow; const event: appTEvent): loopint;

   uiTSimpleWindowList = specialize TSimpleList<uiTWindow>;

   { WINDOW HANDLERS }
   uiTWindowKeyHandler  = function(var key: appTKeyEvent; wnd: uiTWindow): boolean;
   uiTPointerHandler    = procedure(var p: appTMouseEvent; wnd: uiTWindow);

   uiTWindowProcedure   = procedure(wnd: uiTWindow);

IMPLEMENTATION

{ uiTWindowPropertiesHelper }

procedure uiTWindowPropertiesHelper.Immovable;
begin
   Self := Self - [uiwndpMOVE_BY_SURFACE, uiwndpMOVABLE];
end;

function uiTWindowPropertiesHelper.ToString: StdString;
begin
   Result := GetSetValues(TypeInfo(Self));
end;

{ uiTWindow }

constructor uiTWindow.Create();
begin
   inherited;

   ControlType := uiCONTROL_WINDOW;
   Opacity := 1.0;
   wnd := Self;

   W.Initialize();
   Widgets.Initialize();

   uiTWindowListeners.InitializeValues(Listeners);
end;

procedure uiTWindow.Action(action: uiTWindowEvents);
begin

end;

function uiTWindow.SetTitle(const newTitle: StdString): uiTWindow;
begin
   Title := newTitle;

   Result := Self;
end;

function uiTWindow.SetID(const wID: uiTControlID): uiTWindow;
begin
   ID := wID;
   Result := self;
end;

function uiTWindow.GetSurfaceColor: TColor4ub;
begin
   Result := Background.Color;
end;

procedure uiTWindow.OnMaximize();
begin
end;

procedure uiTWindow.OnMinimize();
begin
end;

procedure uiTWindow.OnOpen();
begin

end;

procedure uiTWindow.OnClose();
begin
end;

procedure uiTWindow.OnStartDrag();
begin

end;

procedure uiTWindow.OnDrag();
begin

end;

procedure uiTWindow.OnStopDrag();
begin

end;

END.
