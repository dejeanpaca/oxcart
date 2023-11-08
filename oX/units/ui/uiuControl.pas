{
   uiuControl, Basis for all ui controls (windows and widgets)
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuControl;

INTERFACE

   USES
      uStd, StringUtils, uColors,
      {app}
      appuKeys, appuMouse,
      {oX}
      uOX, oxuTypes, uiuTypes;

TYPE
   { uiTControl }

   uiTControlTypes = (
      {control was not properly set}
      uiCONTROL_UNDEFINED,
      {control is a widget}
      uiCONTROL_WIDGET,
      {control is a window}
      uiCONTROL_WINDOW
   );

   uiTControlMaximizationObscureType = (
      uiCONTROL_MAXIMIZATION_OBSCURE_NONE,
      uiCONTROL_MAXIMIZATION_OBSCURE_HORIZONTAL,
      uiCONTROL_MAXIMIZATION_OBSCURE_VERTICAL
   );

   uiPControlID = ^uiTControlID;

   { uiTControlID }

   uiTControlID = record
      Name: StdString;
      {control Id (negative Ids may indicate external reference)}
      ID: loopint;

      function ToString(): StdString;
      procedure Destroy();
   end;


   uiTControlGridPositions = (
      uiCONTROL_GRID_TOP,
      uiCONTROL_GRID_LEFT,
      uiCONTROL_GRID_MIDDLE,
      uiCONTROL_GRID_MIDDLE_HORIZONTAL,
      uiCONTROL_GRID_RIGHT,
      uiCONTROL_GRID_BOTTOM
   );

   uiTControlGridPosition = set of uiTControlGridPositions;

   uiTControlClass = class of uiTControl;

   uiTControl = class
      {the parent control}
      Parent,
      {the top parent oX window}
      oxwParent,
      {Part of what window. If window should reference self, if widget its first parent window.}
      wnd: uiTControl;

      ControlType: uiTControlTypes;

      {position within the parent}
      Position,
      {position relative to the client area of the parent oX window, used to easily render at the proper location.
      Could also be considered as the controls absolute position on rendering window.}
      RPosition: oxTPoint;
      PreviousDimensions,
      Dimensions: oxTDimensions;

      {what nesting level this control is part of, should be properly set when reparented}
      Level,
      {how many pixels of border this widget has}
      Border,
      {how much padding this widget has}
      PaddingTop,
      PaddingRight,
      PaddingBottom,
      PaddingLeft,
      {z index of the control}
      ZIndex: loopint;

      {are dimensions set, if not they're determined automatically from GetComputedDimensions}
      DimensionsSet: boolean;
      {determines whether this control obscures maximization}
      ObscuresMaximization: uiTControlMaximizationObscureType;

      {cursor type for this control}
      CursorType: uiTCursorType;
      {custom cursor type, 0 and less means disabled}
      CustomCursorType: loopint;

      constructor Create(); virtual;

      {find a parent of the specified type, otherwise returns nil}
      function GetParentOfType(parentType: uiTControlClass): uiTControl;
      {checks if the window is of the specified type}
      function IsType(whatType: uiTControlClass): boolean;
      {checks if the window is of the specified type}
      class function IsType(control, whatType: uiTControlClass): boolean; static;

      {set a relative point as absolute (similar to RPosition)}
      procedure SetAbsolute(var p: oxTPoint);
      procedure SetAbsolute(var r: oxTRect);

      {gets a rectangle for the specified window}
      procedure GetRect(out r: oxTRect);
      {gets a relative rectangle for the specified window, based on RPosition}
      procedure GetRelativeRect(out r: oxTRect);
      {get computed dimensions}
      procedure GetComputedDimensions(out d: oxTDimensions); virtual;
      function GetComputedDimensionsf(): oxTDimensions;
      function GetComputedWidth(): loopint;
      function GetComputedHeight(): loopint;
      {set padding for every side}
      procedure SetPadding(p: loopint);
      {set padding for top, right, bottom, left}
      procedure SetPadding(t, r, b, l: loopint);
      {set padding for top and bottm}
      procedure SetHorizontalPadding(p: loopint);
      {set padding for top and bottm}
      procedure SetVerticalPadding(p: loopint);
      {set padding}
      procedure SetBorder(p: loopint);
      {get the visible vertical space}
      function GetVisibleVerticalSpace(): int64;
      {get the visible horizontal space}
      function GetVisibleHorizontalSpace(): int64;

      {automatically set computed dimensions if dimensions are not set}
      procedure AutoSetDimensions(force: boolean = false);

      {initialize this control (called when it is created)}
      procedure Initialize(); virtual;
      {deinitialize this control (called when it is destroyed)}
      procedure DeInitialize(); virtual;
      {update control periodically}
      procedure Update(); virtual;

      function GetSurfaceColor(): TColor4ub; virtual;

      function GetPointerPosition(x, y: loopint): oxTPoint; virtual;
      function GetAbsolutePointer(x, y: loopint): oxTPoint; virtual;
      function GetAbsolutePointer(p: oxTPoint): oxTPoint; virtual;

      {render this control}
      procedure Render(); virtual;
      {key event}
      function Key(var {%H-}k: appTKeyEvent): boolean; virtual;
      {pointer event}
      procedure Point(var {%H-}e: appTMouseEvent; {%H-}x, {%H-}y: longint); virtual;
      {hover event}
      procedure Hover({%H-}x, {%H-}y: longint; {%H-}what: uiTHoverEvent); virtual;

      {called when a control is activated}
      procedure OnActivate(); virtual;
      {called when a control is deactivated}
      procedure OnDeactivate(); virtual;

      {called when a control is set visible}
      procedure OnVisible(); virtual;
      {called when a control is set invisible}
      procedure OnInvisible(); virtual;

      {called after rendering}
      procedure OnPostRender(); virtual;

      {called when started destroying this control}
      procedure OnDestroy(); virtual;

      {set a new parent and call the ParentChanged event}
      procedure SetParent(newParent: uiTControl);

   protected
      {unusable width and height}
      UnusableHeight,
      UnusableWidth: longint;

      procedure PaddingChanged(); virtual;
      procedure BorderChanged(); virtual;
      procedure PositionChanged(); virtual;
      procedure RPositionChanged(); virtual;
      procedure SizeChanged(); virtual;
      procedure ParentSizeChange(); virtual;
      {called when the parent of this control is changed}
      procedure ParentChanged(); virtual;
      {when padding or border height changes, update the unusable size (dimensions) numbers}
      procedure SetupUnusableSize(); virtual;
   end;

   uiTSimpleControlList = specialize TSimpleList<uiTControl>;

   { uiTControlGlobal }

   uiTControlGlobal = record
      nilID: uiTControlID;

      idCount: loopint;

      function GetID(): longword;
      function GetID(const Name: StdString): uiTControlID;
      function GetPlainID(): uiTControlID;
      function GetIDs(count: longint): longint;
   end;

VAR
   uiControl: uiTControlGlobal;

{ ID OPERATORS }
operator = (var a: uiTControlID; var b: uiTControlID): boolean;

IMPLEMENTATION

operator = (var a: uiTControlID; var b: uiTControlID): boolean;
begin
   Result := a.ID = b.ID;
end;

{ uiTControlID }

function uiTControlID.ToString(): StdString;
begin
  if(Name <> '') then
     Result := Name + ', ' + sf(ID)
  else
     Result := sf(ID);
end;

procedure uiTControlID.Destroy();
begin
   Name := '';
   ID := 0;
end;

{ uiTControlIDs }
function uiTControlGlobal.GetID(): longword;
begin
   inc(idCount);
   Result := idCount;
end;

function uiTControlGlobal.GetID(const Name: StdString): uiTControlID;
begin
   Result.Name := Name;
   Result.ID   := GetID();
end;

function uiTControlGlobal.GetPlainID(): uiTControlID;
begin
   inc(idCount);
   Result.Name := '';
   Result.ID   := idCount;
end;

function uiTControlGlobal.GetIDs(count: longint): longint;
begin
   inc(idCount, count);

   Result := idCount;
end;


{ uiTControl }

constructor uiTControl.Create();
begin
   CursorType := uiCURSOR_TYPE_DEFAULT;
   inherited;
end;

function uiTControl.GetParentOfType(parentType: uiTControlClass): uiTControl;
var
   cur: uiTControl;

begin
   cur := Parent;

   repeat
     if(ox.IsType(cur, parentType)) then
        exit(cur);

     cur := cur.Parent;
   until (cur = nil);

   Result := nil;
end;

function uiTControl.IsType(whatType: uiTControlClass): boolean;
begin
   Result := ox.IsType(Self, whatType);
end;

class function uiTControl.IsType(control, whatType: uiTControlClass): boolean;
begin
   Result := ox.IsType(control, whatType);
end;

procedure uiTControl.SetAbsolute(var p: oxTPoint);
begin
   p.x := p.x + (RPosition.x - Position.x);
   p.y := p.y + (RPosition.x - Position.y);
end;

procedure uiTControl.SetAbsolute(var r: oxTRect);
begin
   r.x := r.x + (RPosition.x - Position.x);
   r.y := r.y + (RPosition.y - Position.y);
end;

procedure uiTControl.GetRect(out r: oxTRect);
begin
   r.x := Position.x;
   r.y := Position.y;
   r.w := Dimensions.w;
   r.h := Dimensions.h;
end;

procedure uiTControl.GetRelativeRect(out r: oxTRect);
begin
   r.x := RPosition.x;
   r.y := RPosition.y;
   r.w := Dimensions.w;
   r.h := Dimensions.h;
end;

procedure uiTControl.GetComputedDimensions(out d: oxTDimensions);
begin
   d := Dimensions;
end;

function uiTControl.GetComputedDimensionsf(): oxTDimensions;
begin
   GetComputedDimensions(Result);
end;

function uiTControl.GetComputedWidth(): loopint;
begin
   Result := GetComputedDimensionsf().w;
end;

function uiTControl.GetComputedHeight(): loopint;
begin
   Result := GetComputedDimensionsf().h;
end;

procedure uiTControl.SetPadding(p: loopint);
begin
   PaddingTop := p;
   PaddingRight := p;
   PaddingBottom := p;
   PaddingLeft := p;
   PaddingChanged();
end;

procedure uiTControl.SetPadding(t, r, b, l: loopint);
begin
   PaddingTop := t;
   PaddingRight := r;
   PaddingBottom := b;
   PaddingLeft := l;
   PaddingChanged();
end;

procedure uiTControl.SetHorizontalPadding(p: loopint);
begin
   PaddingLeft := p;
   PaddingRight := p;
end;

procedure uiTControl.SetVerticalPadding(p: loopint);
begin
   PaddingTop := p;
   PaddingBottom := p;
end;

procedure uiTControl.SetBorder(p: loopint);
begin
   Border := p;
   BorderChanged();
end;

function uiTControl.GetVisibleVerticalSpace(): int64;
begin
   Result := int64(Dimensions.h) - int64(UnusableHeight);
end;

function uiTControl.GetVisibleHorizontalSpace(): int64;
begin
   Result := int64(Dimensions.w) - int64(UnusableWidth);
end;

procedure uiTControl.AutoSetDimensions(force: boolean);
begin
   if(force) then
      DimensionsSet := false;

   if(not DimensionsSet) then begin
      GetComputedDimensions(Dimensions);

      SizeChanged();
   end;
end;

procedure uiTControl.Initialize();
begin

end;

procedure uiTControl.DeInitialize();
begin

end;

procedure uiTControl.Update();
begin

end;

function uiTControl.GetSurfaceColor(): TColor4ub;
begin
   Result := cWhite4ub;
end;

function uiTControl.GetPointerPosition(x, y: loopint): oxTPoint;
begin
   Result.x := x - RPosition.x;
   Result.y := y - RPosition.y + Dimensions.h - 1;
end;

function uiTControl.GetAbsolutePointer(x, y: loopint): oxTPoint;
begin
   Result.x := RPosition.x + x;
   Result.y := RPosition.y - (Dimensions.h - 1 - y);
end;

function uiTControl.GetAbsolutePointer(p: oxTPoint): oxTPoint;
begin
   Result := GetAbsolutePointer(p.x, p.y);
end;

procedure uiTControl.Render();
begin

end;

function uiTControl.Key(var k: appTKeyEvent): boolean;
begin
   Result := false;
end;

procedure uiTControl.Point(var e: appTMouseEvent; x, y: longint);
begin

end;

procedure uiTControl.Hover(x, y: longint; what: uiTHoverEvent);
begin

end;

procedure uiTControl.OnActivate();
begin

end;

procedure uiTControl.OnDeactivate();
begin

end;

procedure uiTControl.OnVisible();
begin

end;

procedure uiTControl.OnInvisible();
begin

end;

procedure uiTControl.OnPostRender();
begin

end;

procedure uiTControl.OnDestroy();
begin

end;

procedure uiTControl.SetParent(newParent: uiTControl);
begin
   Parent := newParent;
   ParentChanged();
end;

procedure uiTControl.PaddingChanged();
begin
   SetupUnusableSize();
end;

procedure uiTControl.BorderChanged();
begin
   SetupUnusableSize();
end;

procedure uiTControl.PositionChanged();
begin
end;

procedure uiTControl.RPositionChanged();
begin

end;

procedure uiTControl.SizeChanged();
begin

end;

procedure uiTControl.ParentSizeChange();
begin

end;

procedure uiTControl.ParentChanged();
begin

end;

procedure uiTControl.SetupUnusableSize();
begin
   UnusableWidth := PaddingLeft + PaddingRight;
   UnusableHeight := PaddingTop + PaddingBottom;

   if(Border > 0) then begin
      inc(UnusableWidth, Border * 2);
      inc(UnusableHeight, Border * 2);
   end;
end;

END.
