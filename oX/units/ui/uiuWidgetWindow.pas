{
   uiuWidgetWindow, helper to create windows for widgets
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuWidgetWindow;

INTERFACE

   USES
      uStd, oxuTypes,
      {ui}
      uiuTypes, uiuControl, uiuWidget, uiuWindowTypes, uiuWindow,
      uiWidgets;

CONST
   WDG_WINDOW_CREATE_BELOW = $1;
   WDG_WINDOW_CREATE_ABOVE = $2;
   WDG_WINDOW_CREATE_RIGHT = $4;
   WDG_WINDOW_CREATE_LEFT  = $8;

   WDG_WINDOW_SEPARATION = 2;

TYPE
   uiTWidgetWindowOriginType = (
      WDG_WINDOW_ORIGIN_POINT,
      WDG_WINDOW_ORIGIN_CONTROL,
      WDG_WINDOW_ORIGIN_RECT
   );

   { uiTWidgetWindowOrigin }

   uiTWidgetWindowOrigin = record
      OriginType: uiTWidgetWindowOriginType;

      Rect: oxTRect;
      Control: uiTControl;
      Properties: TBitSet;

      class procedure Initialize(out origin: uiTWidgetWindowOrigin); static;

      procedure SetControl(newControl: uiTControl);
      procedure SetPoint(const newPoint: oxTPoint; newControl: uiTControl);
      procedure SetRect(const newRect: oxTRect; newControl: uiTControl);
   end;

   { uiTWidgetWindow }

   uiPWidgetWindow = ^uiTWidgetWindow;
   uiTWidgetWindow = record
      wnd: uiTWindow;
      wdg: uiTWidget;

      ExternalData: TObject;
      {can be used to insance an extended window, which must be based on uiTWidgetWindowInternal}
      Instance: uiTWindowClass;

      procedure CreateFrom(const from: uiTWidgetWindowOrigin; const wc: uiTWidgetClass; width: longint = 80; height: longint = 140);

      procedure Destroy();
      procedure Destroyed();
   end;

   { uiTWidgetWindowInternal }

   uiTWidgetWindowInternal = class(uiTWindow)
      DestroyOnDeactivate: boolean;

      WidgetWindow: uiPWidgetWindow;
      ExternalData: TObject;

      constructor Create(); override;
      procedure OnDeactivate(); override;
      procedure OnClose(); override;
      procedure DeInitialize(); override;
   end;

   uiTWidgetWindowGlobal = record
      ZIndex: loopint;
   end;

VAR
   uiWidgetWindow: uiTWidgetWindowGlobal;

IMPLEMENTATION

{ uiTWidgetWindowOrigin }

class procedure uiTWidgetWindowOrigin.Initialize(out origin: uiTWidgetWindowOrigin);
begin
   ZeroOut(origin, SizeOf(origin));
end;

procedure uiTWidgetWindowOrigin.SetControl(newControl: uiTControl);
begin
   OriginType := WDG_WINDOW_ORIGIN_CONTROL;

   Control := newControl;
   Rect.Assign(Control.RPosition, Control.Dimensions);
end;

procedure uiTWidgetWindowOrigin.SetPoint(const newPoint: oxTPoint; newControl: uiTControl);
begin
   OriginType := WDG_WINDOW_ORIGIN_POINT;

   Rect.x := newPoint.x;
   Rect.y := newPoint.y;
   Rect.w := 1;
   Rect.h := 1;
   Control := newControl;
end;

procedure uiTWidgetWindowOrigin.SetRect(const newRect: oxTRect; newControl: uiTControl);
begin
   OriginType := WDG_WINDOW_ORIGIN_RECT;

   Rect := newRect;
   Control := newControl;
end;

{ uiTWidgetWindowInternal }

constructor uiTWidgetWindowInternal.Create();
begin
   inherited;

   DestroyOnDeactivate := true;
end;

procedure uiTWidgetWindowInternal.OnDeactivate();
begin
   inherited;

   if(DestroyOnDeactivate) and (IsOpen()) then
      Close();
end;

procedure uiTWidgetWindowInternal.OnClose();
var
   ww: uiPWidgetWindow;

begin
   inherited;

   {avoid circular destruction}
   ww := WidgetWindow;
   WidgetWindow := nil;
   ww^.Destroy();

end;

procedure uiTWidgetWindowInternal.DeInitialize();
begin
   inherited DeInitialize;
end;

{ uiTWidgetWindow }

procedure uiTWidgetWindow.CreateFrom(const from: uiTWidgetWindowOrigin; const wc: uiTWidgetClass; width: longint; height: longint);
var
   top: uiTWindow;
   origin: oxTPoint;
   newX, newY: longint;
   r: oxTRect;

begin
   top := uiTWindow(from.Control.wnd).GetTopLevel();
   r := from.Rect;

   Destroy();

   if(Instance = nil) then
      uiWindow.Create.Instance := uiTWidgetWindowInternal
   else
      uiWindow.Create.Instance := Instance;

   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;

   uiWindow.Create.Properties := uiWindow.Create.Properties + [uiwndpMOVE_BY_SURFACE, uiwndpRESIZABLE];
   uiWindow.Create.ZIndex := uiWidgetWindow.ZIndex;
   Include(uiWindow.Create.Properties, uiwndpNO_DISPOSE_OF_EXT_DATA);

   origin.x := r.x;
   origin.y := r.y;

   if(from.Properties.IsSet(WDG_WINDOW_CREATE_BELOW)) then
      dec(origin.y, r.h);

   if(from.Properties.IsSet(WDG_WINDOW_CREATE_ABOVE)) then
      inc(origin.y, height + WDG_WINDOW_SEPARATION);

   if(from.Properties.IsSet(WDG_WINDOW_CREATE_RIGHT)) then
      inc(origin.x, r.w + WDG_WINDOW_SEPARATION);

   if(from.Properties.IsSet(WDG_WINDOW_CREATE_LEFT)) then
      inc(origin.x, width + WDG_WINDOW_SEPARATION);

   wnd := uiWindow.MakeChild(top, 'context', origin, oxDimensions(width, height));
   wnd.Background.Typ := uiwBACKGROUND_NONE;

   uiTWidgetWindowInternal(wnd).WidgetWindow := @Self;
   uiTWidgetWindowInternal(wnd).ExternalData := ExternalData;

   {correct window position if it is obscured due to its position}
   newX := origin.x;

   if(origin.x <= 0) then
      newX := 0;

   if(origin.x + width - 1 >= top.Dimensions.w) then
      newX := top.Dimensions.w - width - 1;

   newY := origin.y;

   if(origin.y > top.Dimensions.h - 1) then
      newY := top.Dimensions.h - 1;

   if(origin.y - height + 1 < 0) then
      newY := 0 + height - 1;

   {if position corrected, move window to new position}
   if(newX <> origin.x) or (newY <> origin.y) then
      wnd.Move(newX, newY);

   {add the widget from the specified class to the window}
   wdg := uiWidget.Add(wc, oxPoint(0, height), oxDimensions(width, height));
   wdg.Select();
end;

procedure uiTWidgetWindow.Destroy();
var
   w: uiTWindow;

begin
   if(wnd <> nil) then begin
      {avoid circular references by removing window reference immediately}
      w := wnd;
      Destroyed();

      {dispose of the window}
      uiWindow.DisposeQueue(w);
   end;
end;

procedure uiTWidgetWindow.Destroyed();
begin
   wdg := nil;
   wnd := nil;
end;

END.
