{
   uiuWidget, widget functionality
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuWidget;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuRunRoutines, oxuFont,
      {ui}
      uiuControl, uiuControls, uiuTypes, uiuWindowTypes, uiuSkinTypes;

CONST
   {widget position properties}
   wdgPOSITION_HORIZONTAL_LEFT   = $0001;
   wdgPOSITION_HORIZONTAL_RIGHT  = $0002;
   wdgPOSITION_HORIZONTAL_CENTER = $0004;
   wdgPOSITION_VERTICAL_TOP      = $0008;
   wdgPOSITION_VERTICAL_BOTTOM   = $0010;
   wdgPOSITION_VERTICAL_CENTER   = $0020;
   wdgPOSITION_RESIZE            = $0040;

   {widget size properties}
   wdgWIDTH_MAX_HORIZONTAL       = $0001;
   wdgHEIGHT_MAX_VERTICAL        = $0002;

   {default spacing for widgets}
   wdgDEFAULT_SPACING: loopint = 8;
   wdgELEMENT_PADDING: loopint = 16;
   wdgGRID_SIZE: loopint = 8;

TYPE
   uiTWidgetEvents = (
      {widget actions}
      uiwdgACTION_NONE,
      {widget activated (selected)}
      uiwdgACTION_ACTIVATE,
      {widget deactivated (deselected)}
      uiwdgACTION_DEACTIVATE,
      {widget activated (set visible)}
      uiwdgACTION_VISIBLE,
      {widget deactivated (set invisible)}
      uiwdgACTION_INVISIBLE,
      {the widget or window containing the widget has moved}
      uiwdgACTION_MOVE,
      {widget has been resized}
      uiwdgACTION_RESIZE
   );

   { UI }
   uiPWidgetClass       = ^uiTWidgetClass;

   { WIDGETS }
   uiPWidgets = ^uiTWidgets;
   uiTWidgets = type uiTControls;

   {widget control routine, default result should be 0}
   uiTWidgetControlProc = function(wdg: uiTControl; what: loopint): loopint;

   uiTWidgetProperty = (
      {is the widget enabled}
      wdgpENABLED,
      {is the widget visible}
      wdgpVISIBLE,
      {is the widget being hovered over by a pointer currently}
      wdgpHOVERING,
      {determines if the widget state is true (actual meaning depends on the widget class)}
      wdgpTRUE,
      {is this widget selectable}
      wdgpSELECTABLE,
      {this widget is used as a default for the cancel(escape) key group}
      wdgpDEFAULT_ESCAPE,
      {this widget is used as a default for the confirm key group}
      wdgpDEFAULT_CONFIRM,
      {the widget is a nonclient area widget}
      wdgpNON_CLIENT,
      {destruction of the widget is in progress}
      wdgpDESTROY_IN_PROGRESS
   );

   uiTWidgetProperties = set of uiTWidgetProperty;

   { uiTWidget }

   uiTWidget = class(uiTControl)
      {widget caption}
      Caption,
      {hint for the widget}
      Hint: StdString;

      {widget ID}
      ID: uiTControlID;

      {widget properties}
      Properties: uiTWidgetProperties;

      {group the widget belongs to, relevant only for widgets which can be grouped}
      Group: loopint;

      {widget font}
      Font,
      {cached font reference (always use SetFont())}
      CachedFont: oxTFont;

      {colors}
      Color:   TColor4ub;
      BkColor: TColor4ub;

      {class and control info}
      WdgClass:   uiPWidgetClass;
      WdgControl: uiTWidgetControlProc;

      {skin}
      Skin: uiPWidgetSkin;

      {sub widgets}
      Widgets: uiTWidgets;

      constructor Create(); override;

      {get relative position, and dimensions as rect}
      procedure GetRelativeRect(out r: oxTRect);

      procedure Action({%H-}action: uiTWidgetEvents); virtual;

      { selection }
      {get top level widget}
      function GetTopLevel(): uiTWidget;

      { position and size }
      {updates the position of a widget}
      procedure PositionUpdate();
      {notify all children of parent size change}
      procedure UpdateParentSize(selfNotify: boolean = true);

      { modification }

      {set the caption of a widget}
      procedure SetCaption(const newCaption: StdString);

      { actions }
      {notify the widget controller of something}
      function Control(what: loopint): loopint;
      {set a control routine}
      function SetControl(controlProc: uiTWidgetControlProc): uiTWidget; virtual;

      { WIDGET PROPERTIES }
      {enabled property}
      procedure Enable();
      procedure Enable(expression: boolean);
      procedure Disable();
      {are we enabled}
      function IsEnabled(): boolean;

      {visibility}
      procedure SetVisibility(visible: boolean);
      procedure SetVisible();
      procedure SetInvisible();
      {is this widget visible}
      function IsVisible(): boolean;

      { font }
      {gets an appropriate font for the widget}
      function GetFont(): oxTFont;
      {sets a font for a widget to use}
      function SetFont(fnt: oxTFont): uiTWidget;

      function GetColorset(): uiPSkinColorSet;

      {set ID for the widget}
      function SetID(const wdgID: uiTControlID): uiTWidget;
      {set the group the widget belongs to}
      function SetGroup(g: loopint): uiTWidget; virtual;

      {set a new hint}
      function SetHint(const newHint: StdString): uiTWidget;
      {update hint when you changed it}
      procedure UpdateHint();

      {get the widgets container this widget is part of}
      function GetWidgetsContainer(): uiPWidgets;

      function GetSurfaceColor: TColor4ub; override;
      {get right edge position}
      function GetRightEdge(): loopint;
      {get position just right of the widget}
      function RightOf(spacing: loopint = -1): loopint;
      {get position just left of the widget}
      function LeftOf(spacing: loopint = -1): loopint;
      {get position just above the widget}
      function AboveOf(spacing: loopint = -1): loopint;
      {get position just below the widget}
      function BelowOf(spacing: loopint = -1): loopint;

      {get the maximum current width (all to the right)}
      function MaximumWidth(spacing: loopint = -1): loopint;
      {get the maximum current height (all to the bottom)}
      function MaximumHeight(spacing: loopint = -1): loopint;

      {get remaining width (right side)}
      function RemainingWidth(): loopint;
      {get remaining height (below)}
      function RemainingHeight(): loopint;

      procedure FitToGrid(var d: oxTDimensions);
      procedure FitWidthToGrid(var d: oxTDimensions);
      procedure FitHeightToGrid(var d: oxTDimensions);

      protected
         {called when the font changes}
         procedure FontChanged(); virtual;
         {called when the caption changes}
         procedure CaptionChanged(); virtual;
         {called when hint is changed}
         procedure OnHintChanged(); virtual;
   end;

   uiTWidgetCallbackRoutine = procedure(wdg: uiTWidget);
   uiTWidgetObjectCallbackRoutine = procedure(wdg: uiTWidget) of object;

   { uiTWidgetCallback }

   uiTWidgetCallback = record
      Callback: TProcedure;
      ObjectCallback: TObjectProcedure;
      WidgetCallback: uiTWidgetCallbackRoutine;
      WidgetObjectCallback: uiTWidgetObjectCallbackRoutine;

      procedure Use(setCallback: TProcedure);
      procedure Use(setCallback: TObjectProcedure);
      procedure Use(setCallback: uiTWidgetCallbackRoutine);
      procedure Use(setCallback: uiTWidgetObjectCallbackRoutine);

      function Call(): boolean;
      function Call(wdg: uiTWidget): boolean;

      procedure Clear();
   end;

   uiTWidgetClassType = class of uiTWidget;

   {widget class, not a real class,
    only stuff common to a specific type of widget}
   uiTWidgetClass = record
      sName: StdString; {name}
      cID: longword; {ID}

      {settings}
      SelectOnAdd, {select when widget added}
      NonSelectable: boolean; {not a selectable widget}

      SkinDescriptor: uiPWidgetSkinDescriptor;
      InitRoutines: oxTRunRoutine;

      Instance: uiTWidgetClassType;
   end;

   uiTWidgetClasses = array of uiPWidgetClass;

IMPLEMENTATION

USES
   oxuUI;

{ uiTWidgetCallback }

procedure uiTWidgetCallback.Use(setCallback: TProcedure);
begin
   Callback := setCallback;
end;

procedure uiTWidgetCallback.Use(setCallback: TObjectProcedure);
begin
   ObjectCallback := setcallback;
end;

procedure uiTWidgetCallback.Use(setCallback: uiTWidgetCallbackRoutine);
begin
   WidgetCallback := setCallback;
end;

procedure uiTWidgetCallback.Use(setCallback: uiTWidgetObjectCallbackRoutine);
begin
   widgetObjectCallback := setCallback;
end;

function uiTWidgetCallback.Call(): boolean;
begin
   Result := false;

   if(Callback <> nil) then begin
      Callback();
      Result := true;
   end;

   if(ObjectCallback <> nil) then begin
      ObjectCallback();
      Result := true;
   end;
end;

function uiTWidgetCallback.Call(wdg: uiTWidget): boolean;
begin
   Result := false;

   if(WidgetObjectCallback <> nil) then begin
      WidgetObjectCallback(wdg);
      Result := true;
   end;

   if(WidgetCallback <> nil) then begin
      WidgetCallback(wdg);
      Result := true;
   end;

   if(Call()) then
      Result := true;
end;

procedure uiTWidgetCallback.Clear();
begin
   Callback := nil;
   ObjectCallback := nil;
   WidgetCallback := nil;
   WidgetObjectCallback := nil;
end;

{ uiTWidget }

constructor uiTWidget.Create();
begin
   inherited;

   ControlType := uiCONTROL_WIDGET;
   Widgets.Initialize();

   Color := cWhite4ub;
   BkColor := cBlack4ub;
   CachedFont := GetFont();
end;

procedure uiTWidget.GetRelativeRect(out r: oxTRect);
begin
   r.x := RPosition.x;
   r.y := RPosition.y;
   r.w := Dimensions.w;
   r.h := Dimensions.h;
end;

procedure uiTWidget.Action(action: uiTWidgetEvents);
begin
end;

function uiTWidget.GetTopLevel(): uiTWidget;
var
   cur: uiTControl;

begin
   // go through parents until we find a widget with a window as a parent

   if(Parent.ControlType = uiCONTROL_WIDGET) then begin
      cur := Parent;

      repeat
         if(cur.Parent.ControlType = uiCONTROL_WINDOW) then
            exit(uiTWidget(cur));

         cur := cur.Parent;
      until (cur.ControlType = uiCONTROL_WINDOW) or (cur = nil);
   end;

   Result := nil;
end;

procedure uiTWidget.PositionUpdate();
var
   i: loopint;

begin
   RPosition.x := Parent.RPosition.x + Position.x;
   RPosition.y := Parent.RPosition.y - (Parent.Dimensions.h - Position.y) + 1;

   for i := 0 to (Widgets.w.n - 1) do begin
      if(Widgets.w[i] <> nil) then
         uiTWidget(Widgets.w[i]).PositionUpdate();
   end;

   RPositionChanged();
end;

procedure uiTWidget.UpdateParentSize(selfNotify: boolean);
var
   i: loopint;

begin
   for i := 0 to (Widgets.w.n - 1) do begin
      if(Widgets.w[i] <> nil) then
         uiTWidget(Widgets.w[i]).UpdateParentSize();
   end;

   if(selfNotify) then
      ParentSizeChange();
end;

{ MODIFICATION }

procedure uiTWidget.SetCaption(const newCaption: StdString);
begin
   Caption := newCaption;

   CaptionChanged();
end;

{ ACTIONS }

function uiTWidget.Control(what: loopint): loopint;
begin
   if(wdgControl <> nil) then
      Result := wdgControl(self, what)
   else
      Result := -1;
end;

function uiTWidget.SetControl(controlProc: uiTWidgetControlProc): uiTWidget;
begin
   WdgControl := controlProc;

   Result := Self;
end;

{ WIDGET PROPERTIES }
{enabled property}
procedure uiTWidget.Enable();
begin
   Include(Properties, wdgpENABLED);
end;

procedure uiTWidget.Enable(expression: boolean);
begin
   if(expression) then
      Enable()
   else
      Disable();
end;

procedure uiTWidget.Disable();
begin
   Exclude(Properties, wdgpENABLED);
end;

function uiTWidget.IsEnabled(): boolean;
begin
   Result := wdgpENABLED in Properties;
end;

procedure uiTWidget.SetVisibility(visible: boolean);
begin
   if(visible) then
      Include(Properties, wdgpVISIBLE)
   else
      Exclude(Properties, wdgpVISIBLE);
end;

procedure uiTWidget.SetVisible();
begin
   if(not (wdgpVISIBLE in Properties)) then begin
      Include(Properties, wdgpVISIBLE);
      Action(uiwdgACTION_VISIBLE);
      OnVisible();
   end;
end;

procedure uiTWidget.SetInvisible();
begin
   if(wdgpVISIBLE in Properties) then begin
      Exclude(Properties, wdgpVISIBLE);
      Action(uiwdgACTION_INVISIBLE);
      OnInvisible();
   end;
end;

function uiTWidget.IsVisible(): boolean;
begin
   Result := wdgpVISIBLE in Properties;
end;

{ FONT }

function uiTWidget.GetFont(): oxTFont;
begin
   if(Font <> nil) then begin
      Result := Font;
   end else begin
      Result := oxui.GetDefaultFont();
   end;
end;

function uiTWidget.SetFont(fnt: oxTFont): uiTWidget;
begin
   if(fnt <> nil) then
      Font := fnt;

   CachedFont := GetFont();
   FontChanged();
   Result := Self;
end;

function uiTWidget.GetColorset(): uiPSkinColorSet;
begin
   if(wdgpENABLED in Properties) then
      Result := @uiTSkin(uiTWindow(wnd).Skin).Colors
   else
      Result := @uiTSkin(uiTWindow(wnd).Skin).DisabledColors;
end;

function uiTWidget.SetID(const wdgID: uiTControlID): uiTWidget;
begin
   ID := wdgID;

   Result := Self;
end;

function uiTWidget.SetGroup(g: loopint): uiTWidget;
begin
   Group := g;
   Result := Self;
end;

function uiTWidget.SetHint(const newHint: StdString): uiTWidget;
begin
   Hint := newHint;
   UpdateHint();

   Result := Self;
end;

procedure uiTWidget.UpdateHint();
begin
   OnHintChanged();
end;

function uiTWidget.GetWidgetsContainer(): uiPWidgets;
begin
   if(Parent.ControlType = uiCONTROL_WINDOW) then
      Result := uiPWidgets(@uiTWindow(Parent).Widgets)
   else
      Result := uiPWidgets(@uiTWidget(Parent).Widgets);
end;

function uiTWidget.GetSurfaceColor: TColor4ub;
begin
   Result := uiTSkin(uiTWindow(wnd).Skin).Colors.Surface;
end;

function uiTWidget.GetRightEdge(): loopint;
begin
   Result := Position.x + Dimensions.w - 1;
end;

function uiTWidget.RightOf(spacing: loopint): loopint;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Position.x + Dimensions.w + spacing;
end;

function uiTWidget.LeftOf(spacing: loopint): loopint;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Position.x - 1 - spacing;
end;

function uiTWidget.AboveOf(spacing: loopint): loopint;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Position.y + 1 + spacing;
end;

function uiTWidget.BelowOf(spacing: loopint): loopint;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Position.y - Dimensions.h - spacing;
end;

function uiTWidget.MaximumWidth(spacing: loopint): loopint;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Parent.Dimensions.w - Position.x + 1 - spacing;

   if(Result < 0) then
      Result := 0;
end;

function uiTWidget.MaximumHeight(spacing: loopint): loopint;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Position.y + 1 - spacing;

   if(Result < 0) then
      Result := 0;
end;

function uiTWidget.RemainingWidth(): loopint;
begin
   Result := Parent.Dimensions.w - RightOf(0);
end;

function uiTWidget.RemainingHeight(): loopint;
begin
   Result := BelowOf(0) + 1;
end;

procedure uiTWidget.FitToGrid(var d: oxTDimensions);
begin
   FitWidthToGrid(d);
   FitHeightToGrid(d);
end;

procedure uiTWidget.FitWidthToGrid(var d: oxTDimensions);
begin
   if(d.w mod wdgGRID_SIZE > 0) then
      d.w := d.w + (wdgGRID_SIZE - (d.w mod wdgGRID_SIZE));
end;

procedure uiTWidget.FitHeightToGrid(var d: oxTDimensions);
begin
   if(d.h mod wdgGRID_SIZE > 0) then
      d.h := d.h + (wdgGRID_SIZE - (d.h mod wdgGRID_SIZE));
end;

procedure uiTWidget.FontChanged();
begin
end;

procedure uiTWidget.CaptionChanged();
begin
end;

procedure uiTWidget.OnHintChanged();
begin
end;

END.
