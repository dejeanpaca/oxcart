{
   uiuDockableWindow, dockable ui windows
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuDockableWindow;

INTERFACE

   USES
      uColors,
      {oX}
      uStd, oxuTypes, oxuWindow,
      {ui}
      uiuWindow, uiuUI, uiuWindowTypes, uiuTypes, uiuSkinTypes,
      uiuDraw, uiWidgets, uiuWidgetWindow, uiuWidget, uiuSimpleWindowList,
      wdguTabs, wdguBlock;

TYPE
   uiTDockableWindowEdge = (
      uiDOCKABLE_WINDOW_EDGE_NONE,
      uiDOCKABLE_WINDOW_EDGE_UP,
      uiDOCKABLE_WINDOW_EDGE_DOWN,
      uiDOCKABLE_WINDOW_EDGE_LEFT,
      uiDOCKABLE_WINDOW_EDGE_RIGHT,
      uiDOCKABLE_WINDOW_EDGE_CENTER
   );

   { uiTDockableWindow }
   uiTDockableWindow = class(uiTWindow)
      {render an edge as currently dockable}
      RenderEdge: uiTDockableWindowEdge;
      {is the window docked}
      Docked,
      {can the window be tabbed}
      CanTab: boolean;
      {does this window have a dockable window parent (if not nil, then the window is tabbed)}
      TabParent: uiTDockableWindow;

      {properties before the window was docked}
      DockedProperties: record
         Frame: uiTWindowFrameStyle;
         Resizable,
         DropShadow,
         NoEscapeKey: boolean;
      end;

      {frame style before the wndow was tabbed}
      TabbedFrame: uiTWindowFrameStyle;
      {should the window self-destroy}
      SelfDestroy: boolean;

      constructor Create(); override;

      procedure Initialize(); override;

      {check if the specified window is a dockable window}
      class function IsDockableWindow(what: uiTWindow): boolean; static;
      class function IsDockableArea(what: uiTWindow): boolean; static;

      {get the docking area window in parent (if any), otherwise returns nil}
      function GetDockingArea(): uiTDockableWindow;

      {dock}
      function Dock(): uiTDockableWindow;
      function Dock(const p: oxTPoint; const d: oxTDimensions): uiTDockableWindow;

      function DockLeft(ofWnd: uiTDockableWindow; ratio: single = 0.5): uiTDockableWindow;
      function DockRight(ofWnd: uiTDockableWindow; ratio: single = 0.5): uiTDockableWindow;
      function DockUp(ofWnd: uiTDockableWindow; ratio: single = 0.5): uiTDockableWindow;
      function DockDown(ofWnd: uiTDockableWindow; ratio: single = 0.5): uiTDockableWindow;
      function DockCenter(ofWnd: uiTDockableWindow): uiTDockableWindow;

      {tab to a dockable window, returns the dockable parent}
      function TabTo(ofWnd: uiTDockableWindow): uiTDockableWindow;
      {remove window from a tabbed parent back to the docking area}
      procedure Float();
      {close tab window}
      procedure CloseTab();

      {undock the window}
      procedure SetDocked();
      procedure SetUndocked();
      procedure Undock();

      procedure OnPostRender(); override;
      procedure OnRenderEdge();

      procedure OnAnyDrag();
      procedure OnStartDrag(); override;
      procedure OnDrag(); override;
      procedure OnStopDrag(); override;

      procedure OnClose(); override;

      procedure OnActivate(); override;

      {called when a window is docked}
      procedure OnDocked(); virtual;
      {called when a window is undocked}
      procedure OnUndocked(); virtual;
      {called when a window is tabbed}
      procedure OnTabbed(); virtual;
      {called when a window is floated (removed from tabs)}
      procedure OnFloat(); virtual;
   end;

   { uiTDockableArea }

   uiTDockableArea = class(uiTDockableWindow)
      procedure Initialize; override;

      class procedure Fit(const wnds: uiTSimpleWindowList; ofsX, ofsY, newWidth, newHeight, dimW, dimH: loopint; exclude: uiTWindow = nil); static;
      class procedure FitWindow(dockableWnd: uiTDockableWindow; ofsX, ofsY, newWidth, newHeight, dimW, dimH: loopint); static;

      {make all existing windows in the given area}
      procedure Fit(ofsX, ofsY, newWidth, newHeight: longint; exclude: uiTWindow = nil);
      procedure FitWindow(dockableWnd: uiTDockableWindow; ofsX, ofsY, newWidth, newHeight: longint);

      procedure ParentSizeChange(); override;
      procedure SizeChanged(); override;
   end;

   uiTDockableAreaWindowClass = class of uiTDockableArea;

   { wdgTDockableTabs }

   wdgTDockableTabs = class(wdgTTabs)
      constructor Create; override;

      procedure OnTabSelectChange(index: longint); override;
      procedure ResizeWindows();
      procedure RemoveTabWindow(ofWnd: uiTDockableWindow);
      procedure RemoveTabWindow(index: loopint);
      procedure Float(ofWnd: uiTDockableWindow);
      procedure Float(index: loopint);
      procedure CloseTabWindow(index: loopint);
      procedure SelectWindow(ofWnd: uiTDockableWindow);

      procedure OnTabSecondaryClick(index: loopint); override;
   end;

   { uiTDockableTabWindow }

   uiTDockableTabWindow = class(uiTDockableWindow)
      TabWidget: wdgTDockableTabs;
      BlockWidget: wdgTBlock;

      procedure Initialize(); override;

      {tab a window}
      procedure Tab(ofWnd: uiTDockableWindow);
      {set the tabbed window to an appropriate size}
      procedure SizeWindow(ofWnd: uiTDockableWindow);
      {remove the specified tabbed window from list of tabs}
      procedure Float(ofWnd: uiTDockableWindow);
      {select a window}
      procedure SelectWindow(ofWnd: uiTDockableWindow);

      procedure SizeChanged(); override;
   end;

   uiTDockableWindowOpenContextMenuRoutine = procedure(var from: uiTWidgetWindowOrigin; wdg: wdgTDockableTabs; index: loopint);

   { uiTDockableWindowGlobal }

   uiTDockableWindowGlobal = record
      Found: uiTDockableWindow;
      SelfDestroy: boolean;

      OpenContextMenu: uiTDockableWindowOpenContextMenuRoutine;

      procedure ClearFound();

      class function CreateDockableArea(): uiTDockableArea; static;
   end;

VAR
   uiDockableWindow: uiTDockableWindowGlobal;

IMPLEMENTATION

CONST
   BORDER_DIVISOR = 4;
   TAB_HEIGHT = 20;
   TAB_SEPARATION = 2;

{ wdgTDockableTabs }

constructor wdgTDockableTabs.Create;
begin
   inherited Create;

   HeaderHeight := TAB_HEIGHT;

   RenderSurface := false;
   RequiresWidgets := false;
end;

procedure wdgTDockableTabs.OnTabSelectChange(index: longint);
var
   t: wdgPTabEntry;
   i: loopint;
   w: uiTDockableWindow;
   tabWnd: uiTDockableWindow;

begin
   tabWnd := uiTDockableWindow(wnd);

   if(uiwndpDESTRUCTION_IN_PROGRESS in tabWnd.Properties) then
      exit;

   for i := 0 to (Tabs.t.n - 1) do begin
      if(i <> index) then begin
         t := @Tabs.t.List[i];

         if(t^.External <> nil) then
            uiTDockableWindow(t^.External).Hide();
      end;
   end;

   t := @Tabs.t.List[index];

   w := uiTDockableWindow(t^.External);
   if(w <> nil) then begin
      w.Show();

      if(not w.IsSelected()) then
         w.Select();

      w.TabParent.Title := w.Title;
   end;
end;

procedure wdgTDockableTabs.ResizeWindows();
var
   t: wdgPTabEntry;
   i: loopint;
   w: uiTDockableWindow;

begin
   for i := 0 to (tabs.t.n - 1) do begin
      t := @tabs.t.List[i];
      w := uiTDockableWindow(t^.External);

      uiTDockableTabWindow(Parent).SizeWindow(w);
   end;
end;

procedure wdgTDockableTabs.RemoveTabWindow(ofWnd: uiTDockableWindow);
var
   i: loopint;

begin
   for i := 0 to Tabs.t.n - 1 do begin
      if(uiTDockableWindow(Tabs.t.List[i].External) = ofWnd) then begin
         RemoveTabWindow(i);
         exit;
      end;
   end;
end;

procedure wdgTDockableTabs.RemoveTabWindow(index: loopint);
begin
   if(index > -1) and (index < Tabs.t.n) then begin
      RemoveTabByNum(index);
   end;
end;

procedure wdgTDockableTabs.Float(ofWnd: uiTDockableWindow);
var
   i: loopint;

begin
   for i := 0 to Tabs.t.n - 1 do begin
      if(uiTDockableWindow(Tabs.t.List[i].External) = ofWnd) then begin
         Float(i);
         exit;
      end;
   end;
end;

procedure wdgTDockableTabs.Float(index: loopint);
var
   ofWnd: uiTDockableWindow;

begin
   if(index > -1) and (index < Tabs.t.n) then begin
      ofWnd := uiTDockableWindow(Tabs.t.List[index].External);

      ofWnd.Float();
   end;
end;

procedure wdgTDockableTabs.CloseTabWindow(index: loopint);
var
   ofWnd: uiTDockableWindow;

begin
   if(index > -1) and (index < Tabs.t.n) then begin
      ofWnd := uiTDockableWindow(Tabs.t.List[index].External);

      if(ofWnd <> nil) then
         ofWnd.CloseTab();
   end;
end;

procedure wdgTDockableTabs.SelectWindow(ofWnd: uiTDockableWindow);
var
   i: loopint;

begin
   for i := 0 to tabs.t.n - 1 do begin
      if(uiTDockableWindow(tabs.t.List[i].External) = ofWnd) then begin
         SelectByNum(i);
         exit;
      end;
   end;
end;

procedure wdgTDockableTabs.OnTabSecondaryClick(index: loopint);
var
   p: oxTPoint;
   origin: uiTWidgetWindowOrigin;

begin
   if(uiDockableWindow.OpenContextMenu <> nil) then begin
      p := GetAbsolutePointer(LastPointerPosition);

      origin.Initialize(origin);
      origin.SetPoint(p, Self);

      uiDockableWindow.OpenContextMenu(origin, Self, index);
   end;
end;

{ uiTDockableTabWindow }

procedure uiTDockableTabWindow.Initialize();
begin
   inherited Initialize;

   uiWidget.Create.Instance := wdgTDockableTabs;
   TabWidget := wdgTDockableTabs(wdgTabs.Add(oxPoint(0, Dimensions.h - 1), oxDimensions(Dimensions.w, TAB_HEIGHT)));
   TabWidget.Done();

   BlockWidget :=
      wdgTBlock(wdgBlock.Add(oxPoint(0, TabWidget.BelowOf(0)), oxDimensions(Dimensions.w, TAB_SEPARATION)));

   BlockWidget.Color.Assign(0, 0, 0, 255);
end;

procedure uiTDockableTabWindow.Tab(ofWnd: uiTDockableWindow);
var
   t: wdgPTabEntry;
   p: oxTPoint;
   d: oxTDimensions;

begin
   ofWnd.TabbedFrame := ofWnd.Frame;
   ofWnd.SetDocked();
   ofWnd.SetFrameStyle(uiwFRAME_STYLE_NONE);
   ofWnd.ReparentTo(Self);

   if(w.w.n = 1) then begin
      d := GetTotalDimensions();
      p := Position;

      Self.Properties := Self.Properties + [uiwndpMOVE_BY_SURFACE, uiwndpMOVABLE];

      SetFrameStyle(uiwFRAME_STYLE_NONE);

      Resize(d);
      Move(p);
   end;

   uiWidget.PushTarget();
   t := TabWidget.AddTab(ofWnd.Title);
   t^.External := ofWnd;
   t^.AssociatedSelectedControl := ofWnd;
   uiWidget.PopTarget();

   SizeWindow(ofWnd);
   ofWnd.TabParent := Self;

   TabWidget.SelectLast();
end;

procedure uiTDockableTabWindow.SizeWindow(ofWnd: uiTDockableWindow);
var
   d: oxTDimensions;
   h: loopint;

begin
   h := Dimensions.h - TAB_HEIGHT - TAB_SEPARATION;

   ofWnd.Move(0, h - 1);
   d.Assign(Dimensions.w, Dimensions.h - TAB_HEIGHT - TAB_SEPARATION);

   ofWnd.Resize(d);
end;

procedure uiTDockableTabWindow.Float(ofWnd: uiTDockableWindow);
begin
   TabWidget.Float(ofWnd);
end;

procedure uiTDockableTabWindow.SelectWindow(ofWnd: uiTDockableWindow);
begin
   if(TabWidget <> nil) then
      TabWidget.SelectWindow(ofWnd);
end;

procedure uiTDockableTabWindow.SizeChanged();
begin
   inherited SizeChanged;

   TabWidget.Move(0, Dimensions.h - 1);
   TabWidget.Resize(Dimensions.w, TAB_HEIGHT);

   BlockWidget.Move(0, TabWidget.BelowOf(0));
   BlockWidget.Resize(Dimensions.w, TAB_SEPARATION);

   TabWidget.ResizeWindows();
end;

{ uiTDockableArea }

procedure uiTDockableArea.Initialize;
begin
   inherited Initialize;

   Properties := Properties -
      [uiwndpMOVABLE, uiwndpMOVE_BY_SURFACE, uiwndpDROP_SHADOW, uiwndpRESIZABLE];

   Background.Color.Assign(32, 32, 64, 255);
end;

class procedure uiTDockableArea.Fit(const wnds: uiTSimpleWindowList; ofsX, ofsY, newWidth, newHeight, dimW, dimH: loopint; exclude: uiTWindow = nil);
var
   i: loopint;
   dockableWnd: uiTDockableWindow;

begin
   for i := 0 to (wnds.n - 1) do begin
      if(uiTWindow(wnds.List[i]).IsType(uiTDockableWindow)) then begin
         dockableWnd := uiTDockableWindow(wnds.List[i]);

         if(dockableWnd <> exclude) and (dockableWnd.Docked) then
            FitWindow(dockableWnd, ofsX, ofsY, newWidth, newHeight, dimW, dimH);
      end;
   end;
end;

function getRatio(new, old: loopint): single;
begin
   if(new <> old) and (old <> 0) then
      Result := (1 / old) * new
   else
      Result := 1;
end;

class procedure uiTDockableArea.FitWindow(dockableWnd: uiTDockableWindow; ofsX, ofsY, newWidth, newHeight, dimW, dimH: loopint);
var
   ratioWidth,
   ratioHeight: single;

   newW, newH,
   pX, pY: loopint;

   p: oxTPoint;
   d: oxTDimensions;

begin
   ratioWidth := getRatio(newWidth, dimW);
   ratioHeight := getRatio(newHeight, dimH);

   p := dockableWnd.Position;
   d := dockableWnd.GetTotalDimensions();

   newW := round(d.w * ratioWidth);
   newH := round(d.h * ratioHeight);

   pX := p.x;

   if(ratioWidth <> 1) then begin
      if(ofsX = 1) then
         pX := round(p.x + (dimW - p.x) * (1 - ratioWidth))
      else if(ofsX = -1) then
         pX := round(p.x * ratioWidth)
   end;

   pY := p.y;

   if(ratioHeight <> 1) then begin
      if(ofsY = 1) then
         pY := round(p.y + (dimH - 1 - p.y) * (1 - ratioHeight))
      else if(ofsY = -1) then
         pY := round(dockableWnd.Position.y * ratioHeight)
   end;

   dockableWnd.ResizeAdjusted(newW, newH);
   dockableWnd.Move(pX, pY);
end;

procedure uiTDockableArea.Fit(ofsX, ofsY, newWidth, newHeight: longint; exclude: uiTWindow);
var
   i: loopint;
   dockableWnd: uiTDockableWindow;

begin
   for i := 0 to (W.w.n - 1) do begin
      if(uiTWindow(W.w[i]).IsType(uiTDockableWindow)) then begin
         dockableWnd := uiTDockableWindow(W.w[i]);

         if(dockableWnd <> exclude) and (dockableWnd.Docked) then begin
            FitWindow(dockableWnd, ofsX, ofsY, newWidth, newHeight);
         end;
      end;
   end;
end;

procedure uiTDockableArea.FitWindow(dockableWnd: uiTDockableWindow; ofsX, ofsY, newWidth, newHeight: longint);
var
   ratioWidth,
   ratioHeight: single;

   newW, newH,
   pX, pY: loopint;

   p: oxTPoint;
   d: oxTDimensions;

begin
   ratioWidth := getRatio(newWidth, Dimensions.w);
   ratioHeight := getRatio(newHeight, Dimensions.h);

   p := dockableWnd.Position;
   d := dockableWnd.GetTotalDimensions();

   newW := round(d.w * ratioWidth);
   newH := round(d.h * ratioHeight);

   pX := p.x;

   if(ratioWidth <> 1) then begin
      if(ofsX = 1) then
         pX := round(p.x + (Dimensions.w - p.x) * (1 - ratioWidth))
      else if(ofsX = -1) then
         pX := round(p.x * ratioWidth)
   end;

   pY := p.y;

   if(ratioHeight <> 1) then begin
      if(ofsY = 1) then
         pY := round(p.y + (Dimensions.h - 1 - p.y) * (1 - ratioHeight))
      else if(ofsY = -1) then
         pY := round(dockableWnd.Position.y * ratioHeight)
   end;

   dockableWnd.ResizeAdjusted(newW, newH);
   dockableWnd.Move(pX, pY);
end;

procedure uiTDockableArea.ParentSizeChange();
var
   p: oxTPoint;
   d: oxTDimensions;

begin
   inherited ParentSizeChange;

   uiTWindow(Parent).GetMaximizationCoords(p, d);

   if(d.w = Dimensions.w) and (d.h = Dimensions.h) then
      exit;

   Move(p);
   Resize(d);
end;

procedure uiTDockableArea.SizeChanged();
var
   ofsX, ofsY: longint;
   wnds: uiTSimpleWindowList;

begin
   inherited SizeChanged;

   ofsX := 0;
   if(Dimensions.w < previousDimensions.w) or (Dimensions.w > previousDimensions.w) then
      ofsX := -1;

   ofsY := 0;
   if(Dimensions.h < previousDimensions.h) or (Dimensions.h > previousDimensions.h) then
      ofsY := -1;

   wnds := Self.FindType(uiTDockableWindow);
   Fit(wnds, ofsX, ofsY, Dimensions.w, Dimensions.h, PreviousDimensions.w, PreviousDimensions.h);
end;

{ uiTDockableWindowGlobal }

procedure uiTDockableWindowGlobal.ClearFound;
begin
   if(Found <> nil) then begin
      Found.RenderEdge := uiDOCKABLE_WINDOW_EDGE_NONE;
      Found := nil;
   end;
end;

class function uiTDockableWindowGlobal.CreateDockableArea(): uiTDockableArea;
var
   parent: uiTWindow;
   p: oxTPoint;
   d: oxTDimensions;

begin
   parent := oxWindow.Current;

   uiWindow.Create.Properties :=  uiWindow.Create.Properties + [uiwndpNO_ESCAPE_KEY, uiwndpNO_CONFIRMATION_KEY];

   parent.GetMaximizationCoords(p, d);

   uiWindow.Create.MinimumInstanceType := uiTDockableArea;

   if(uiWindow.Create.Instance = nil) then
      uiWindow.Create.Instance := uiTDockableArea;

   Result := uiTDockableArea(uiWindow.MakeChild(parent, 'Dockable Area', p, d));

   Result.Maximize();
end;

{ uiTDockableWindow }

constructor uiTDockableWindow.Create();
begin
   inherited Create;

   CanTab := true;
   RenderEdge := uiDOCKABLE_WINDOW_EDGE_NONE;
   SelfDestroy := uiDockableWindow.SelfDestroy;
end;

procedure uiTDockableWindow.Initialize();
begin
   inherited Initialize;

   Frame := uiwFRAME_STYLE_DOCKABLE;

   Exclude(Properties, uiwndpMOVE_BY_SURFACE);
   Buttons := uiwbCLOSE;
   DockedProperties.Frame := Frame;
   DockedProperties.Resizable := uiwndpRESIZABLE in Properties;
end;

class function uiTDockableWindow.IsDockableWindow(what: uiTWindow): boolean;
begin
   Result := what.IsType(uiTDockableWindow);
end;

class function uiTDockableWindow.IsDockableArea(what: uiTWindow): boolean;
begin
   Result := what.IsType(uiTDockableArea);
end;

function uiTDockableWindow.GetDockingArea(): uiTDockableWindow;
begin
   Result := uiTDockableArea(GetParentOfType(uiTDockableArea));
end;

function uiTDockableWindow.Dock(): uiTDockableWindow;
var
   p: oxTPoint;
   d: oxTDimensions;

begin
   uiTWindow(Parent).GetMaximizationCoords(p, d);
   AdjustDimensions(d);

   Dock(p, d);
   Result := Self;
end;

function uiTDockableWindow.Dock(const p: oxTPoint; const d: oxTDimensions): uiTDockableWindow;
begin
   Move(p);
   Resize(d);

   SetDocked();

   Result := Self;
end;

function uiTDockableWindow.DockLeft(ofWnd: uiTDockableWindow; ratio: single): uiTDockableWindow;
var
   d: oxTDimensions;
   newSize: loopint;

begin
   d := ofWnd.GetTotalDimensions();
   newSize := trunc(d.w * ratio);

   if(not IsDockableArea(ofWnd)) then begin
      ofWnd.ResizeAdjusted(d.w - newSize, d.h);
      Move(ofWnd.Position.x, ofWnd.Position.y);

      ofWnd.Move(ofWnd.Position.x + newSize, ofWnd.Position.y);
      ResizeAdjusted(newSize, d.h);
   end else begin
      Move(0, d.h - 1);
      ResizeAdjusted(newSize, d.h);

      uiTDockableArea(ofWnd).Fit(1, 0, d.w - newSize, d.h, Self);
   end;

   SetDocked();
   Result := Self;
end;

function uiTDockableWindow.DockRight(ofWnd: uiTDockableWindow; ratio: single): uiTDockableWindow;
var
   d: oxTDimensions;
   newSize: loopint;

begin
   d := ofWnd.GetTotalDimensions();
   newSize := trunc(d.w * ratio);

   if(not IsDockableArea(ofWnd)) then begin
      ofWnd.ResizeAdjusted(d.w - newSize, d.h);
      Move(ofWnd.Position.x + (d.w - newSize), ofWnd.Position.y);

      ResizeAdjusted(newSize, d.h);
   end else begin
      Move(d.w - newSize, d.h - 1);
      ResizeAdjusted(newSize, d.h);

      uiTDockableArea(ofWnd).Fit(-1, 0, d.w - newSize, d.h, Self);
   end;

   SetDocked();
   Result := Self;
end;

function uiTDockableWindow.DockUp(ofWnd: uiTDockableWindow; ratio: single): uiTDockableWindow;
var
   newSize: loopint;
   d: oxTDimensions;

begin
   d := ofWnd.GetTotalDimensions();
   newSize := trunc(d.h * ratio);

   if(not IsDockableArea(ofWnd)) then begin
      Move(ofWnd.Position.x, ofWnd.Position.y);
      ResizeAdjusted(d.w, newSize);

      ofWnd.ResizeAdjusted(d.w, ofWnd.GetTotalDimensions().h - newSize);
      ofWnd.Move(ofWnd.Position.x, ofWnd.Position.y - newSize);
   end else begin
      Move(0, ofWnd.Dimensions.h - 1);
      ResizeAdjusted(d.w, newSize);

      uiTDockableArea(ofWnd).Fit(0, -1, d.w, d.h - newSize, Self);
   end;

   SetDocked();
   Result := Self;
end;

function uiTDockableWindow.DockDown(ofWnd: uiTDockableWindow; ratio: single): uiTDockableWindow;
var
   newSize: loopint;
   d: oxTDimensions;

begin
   d := ofWnd.GetTotalDimensions();
   newSize := trunc(d.h * ratio);

   if(not IsDockableArea(ofWnd)) then begin
      ofWnd.ResizeAdjusted(d.w, d.h - newSize);

      Move(ofWnd.Position.x, ofWnd.Position.y - ofWnd.GetTotalDimensions().h);
      ResizeAdjusted(d.w, newSize);
   end else begin
      Move(0, newSize - 1);
      ResizeAdjusted(d.w, newSize);

      uiTDockableArea(ofWnd).Fit(0, 1, d.w, d.h - newSize, Self);
   end;

   SetDocked();

   Result := Self;
end;

function uiTDockableWindow.DockCenter(ofWnd: uiTDockableWindow): uiTDockableWindow;
var
   d: oxTDimensions;

begin
   d := ofWnd.Dimensions;
   ofWnd.AdjustDimensions(d);

   if(IsDockableArea(ofWnd)) then begin
      Dock();
   end else begin
      if(ofWnd.TabParent <> nil) then
         uiTDockableTabWindow(ofWnd.TabParent).Tab(Self)
      else begin
         if(ofWnd.CanTab) then
            Self.TabTo(ofWnd);
      end;
   end;

   Result := Self;
end;

function uiTDockableWindow.TabTo(ofWnd: uiTDockableWindow): uiTDockableWindow;
var
   tParent: uiTDockableTabWindow;

begin
   Result := nil;

   if(ofWnd.TabParent <> nil) then
      tParent := uiTDockableTabWindow(ofWnd.TabParent)
   else begin
      if(not ofWnd.IsType(uiTDockableTabWindow)) then begin
         {create a tab parent if one doesn't exist}
         uiWindow.Create.MinimumInstanceType := uiTDockableTabWindow;
         if(uiWindow.Create.Instance = nil) then
            uiWindow.Create.Instance := uiTDockableTabWindow;

         tParent := uiTDockableTabWindow(
            uiWindow.MakeChild(uiTWindow(ofWnd.Parent), 'Tab Parent', ofWnd.Position, ofWnd.Dimensions));

         tParent.SetDocked();

         if(ofWnd.Docked) then
            tParent.Dock(ofWnd.Position, ofWnd.Dimensions);

         tParent.Tab(ofWnd);
      end else
         tParent := uiTDockableTabWindow(ofWnd);
   end;

   tParent.Tab(Self);

   Self.OnTabbed();
end;

procedure uiTDockableWindow.Float();
var
   dockingArea: uiTDockableArea;
   tabWnd: uiTDockableTabWindow;

begin
   if(TabParent <> nil) then begin
      dockingArea := uiTDockableArea(GetDockingArea());

      if(dockingArea <> nil) then begin
         tabWnd := uiTDockableTabWindow(TabParent);
         tabWnd.TabWidget.RemoveTabWindow(Self);

         ReparentTo(dockingArea);
         SetFrameStyle(TabbedFrame);

         TabParent := nil;

         {Float last window in the list}
         if(tabWnd.W.w.n = 0) then begin
            {we're the last window in the list}
            Move(tabWnd.Position);
            ResizeAdjusted(tabWnd.Dimensions);

            {destroy the tab holder}
            tabWnd.SetUndocked();
            uiWindow.DisposeQueue(uiTWindow(tabWnd));

            exit;
         {Float any window in the list}
         end else begin
            Resize(Dimensions);
            {move to a central place}
            AutoCenter();
         end;

         SetUndocked();

         {Float last window in list (which causes the below one to call automatically in next Float())}
         if(tabWnd.W.w.n = 1) then
            uiTDockableWindow(tabWnd.W.w[0]).Float();

         Self.Select();
         Self.OnFloat();
      end;
   end;
end;

procedure uiTDockableWindow.CloseTab();
var
   dockingArea: uiTDockableArea;
   tabWnd: uiTDockableTabWindow;

begin
   if(TabParent <> nil) then begin
      tabWnd := uiTDockableTabWindow(Parent);
      dockingArea := uiTDockableArea(tabWnd.GetDockingArea());

      if(dockingArea <> nil) then
         ReparentTo(dockingArea)
      else
         ReparentTo(uiTWindow(tabWnd.oxwParent));

      Close();

      {one window left, we'll float the last one}
      if(TabParent.W.w.n = 1) then
         uiTDockableWindow(TabParent.W.w[0]).Float;
   end;
end;

procedure uiTDockableWindow.SetDocked();
begin
   if(not Docked) then begin
      DockedProperties.Resizable := uiwndpRESIZABLE in Properties;
      DockedProperties.DropShadow := uiwndpDROP_SHADOW in Properties;
      DockedProperties.NoEscapeKey := uiwndpNO_ESCAPE_KEY in Properties;

      Properties := Properties - [uiwndpRESIZABLE, uiwndpDROP_SHADOW];
      Properties := Properties + [uiwndpNO_ESCAPE_KEY];

      Docked := true;

      OnDocked();
   end;
end;

procedure uiTDockableWindow.SetUndocked();
begin
   if(Docked) then begin
      Docked := False;
      Frame := DockedProperties.Frame;

      if(DockedProperties.Resizable) then
         Include(Properties, uiwndpRESIZABLE)
      else
         Exclude(Properties, uiwndpRESIZABLE);

      if(DockedProperties.DropShadow) then
         Include(Properties, uiwndpDROP_SHADOW)
      else
         Exclude(Properties, uiwndpDROP_SHADOW);

      if(DockedProperties.NoEscapeKey) then
         Include(Properties, uiwndpDROP_SHADOW)
      else
         Exclude(Properties, uiwndpNO_ESCAPE_KEY);

      OnUndocked();
   end;
end;

procedure uiTDockableWindow.Undock();
var
   cur: uiTWindow;
   d: oxTDimensions;

   {windows in a line up (horizontal or vertical)}
   lineup,
   {windows on one side of the lineup}
   side,
   {windows on the other side of the lineup}
   other: uiTSimpleWindowList;

function ProcessHorizontal(all: boolean = false): boolean;
var
   i: loopint;

begin
   uiWindowList.FindHorizontalLineup(Self, lineup, all);

   if(lineup.n > 0) then begin
      lineup.FindContactsLeft(Self, side);
      lineup.FindContactsRight(Self, other);

      Result := (side.n > 0) or (other.n > 0);

      if(Result) then begin
         if(side.n > 0) then begin
            for i := 0 to side.n - 1 do begin
               cur := side.List[i];
               cur.Resize(cur.Dimensions.w + d.w, cur.Dimensions.h);
            end;
         end else if(other.n > 0) then begin
            for i := 0 to other.n - 1 do begin
               cur := other.List[i];
               cur.Move(Position.x, cur.Position.y);
               cur.Resize(cur.Dimensions.w + d.w, cur.Dimensions.h);
            end;
         end;
      end;
   end else
      Result := false;
end;

function ProcessVertical(all: boolean = false): boolean;
var
   i: loopint;

begin
   uiWindowList.FindVerticalLineup(Self, lineup, all);

   if(lineup.n > 0) then begin
      lineup.FindContactsAbove(Self, side);
      lineup.FindContactsBelow(Self, other);

      Result := (side.n > 0) or (other.n > 0);

      if(Result) then begin
         if(side.n > 0) then begin
            for i := 0 to side.n - 1 do begin
               cur := side.List[i];
               cur.Resize(cur.Dimensions.w, cur.Dimensions.h + d.h);
            end;
         end else if(other.n > 0) then begin
            for i := 0 to other.n - 1 do begin
               cur := other.List[i];
               cur.Move(cur.Position.x, Position.y);
               cur.Resize(cur.Dimensions.w, cur.Dimensions.h + d.h);
            end;
         end;
      end;
   end else
      Result := false;
end;

begin
   if(Docked) and (not (uiwndpDESTRUCTION_IN_PROGRESS in Properties)) then begin
      d := GetTotalDimensions();

      uiTSimpleWindowList.Initialize(lineup);
      uiTSimpleWindowList.Initialize(side);
      uiTSimpleWindowList.Initialize(other);

      if(not ProcessHorizontal(false)) then begin
         if(not ProcessVertical(false)) then begin
            if(not ProcessVertical(true)) then begin
               ProcessHorizontal(true);
            end;
         end;
      end;

      side.Dispose();
      other.Dispose();
   end;

   SetUndocked();
end;

procedure uiTDockableWindow.OnPostRender();
begin
   OnRenderEdge();
end;

procedure uiTDockableWindow.OnRenderEdge();
var
  p: oxTPoint;
  d: oxTDimensions;

begin
   if(RenderEdge <> uiDOCKABLE_WINDOW_EDGE_NONE) then begin
      p := RPosition;
      d := Dimensions;

      if(RenderEdge = uiDOCKABLE_WINDOW_EDGE_UP) or (RenderEdge = uiDOCKABLE_WINDOW_EDGE_DOWN) then {up/down}
         d.h := Dimensions.h div BORDER_DIVISOR
      else if(RenderEdge = uiDOCKABLE_WINDOW_EDGE_LEFT) or (RenderEdge = uiDOCKABLE_WINDOW_EDGE_RIGHT) then {left/right}
         d.w := Dimensions.w div BORDER_DIVISOR;

      if(RenderEdge = uiDOCKABLE_WINDOW_EDGE_DOWN) then {down}
         p.y := p.y - Dimensions.h + (Dimensions.h div BORDER_DIVISOR) - 1
      else if(RenderEdge = uiDOCKABLE_WINDOW_EDGE_RIGHT) then {right}
         p.x := p.x + Dimensions.w - (Dimensions.w div BORDER_DIVISOR);

      SetColorBlended(uiTSkin(Skin).Colors.Highlight[0],
         uiTSkin(Skin).Colors.Highlight[1],
         uiTSkin(Skin).Colors.Highlight[2], 0.5);

      uiDraw.Box(p, d);
   end;
end;

procedure uiTDockableWindow.OnAnyDrag();
var
   s: uiTSelectInfo;
   p: oxTPoint;
   found: uiTWindow;
   edge: uiTDockableWindowEdge;
   isArea: boolean;
   foundDockingArea: uiTDockableArea;

procedure CheckEdge(borderDivisor: longint);
begin
   edge := uiDOCKABLE_WINDOW_EDGE_NONE;

   {if out of bounds of the found window, ignore}
   if(s.x < 0) or (s.y < 0) or (s.x >= found.Dimensions.w) or (s.y >= found.Dimensions.h) then
      exit;

   if(s.y > found.Dimensions.h - (found.Dimensions.h div borderDivisor)) then
      edge := uiDOCKABLE_WINDOW_EDGE_UP
   else if(s.y < found.Dimensions.h div borderDivisor) then
      edge := uiDOCKABLE_WINDOW_EDGE_DOWN;

   if(s.x < found.Dimensions.w div borderDivisor) then
      edge := uiDOCKABLE_WINDOW_EDGE_LEFT
   else if(s.x > found.Dimensions.w - found.Dimensions.w div borderDivisor) then
      edge := uiDOCKABLE_WINDOW_EDGE_RIGHT;

   if(edge = uiDOCKABLE_WINDOW_EDGE_NONE) then
      edge := uiDOCKABLE_WINDOW_EDGE_CENTER;

   if(edge <> uiDOCKABLE_WINDOW_EDGE_NONE) then begin
      uiDockableWindow.Found := uiTDockableWindow(found);
      uiDockableWindow.Found.RenderEdge := edge;
   end;
end;

begin
   Docked := false;

   uiDockableWindow.ClearFound();

   s.Init();
   s.OnlyWindows := true;
   s.Exclude := wnd;

   isArea := false;
   foundDockingArea := nil;
   edge := uiDOCKABLE_WINDOW_EDGE_NONE;

   {check for dockable area first}
   if(IsDockableWindow(uiTWindow(Parent))) then begin
      p := uiTWindow(Parent).GetPointerPosition(GetUI().mSelect.startPoint.x, GetUI().mSelect.startPoint.y);

      s.x := p.x;
      s.y := p.y;

      found := uiTDockableWindow(Parent);
      isArea := found.IsType(uiTDockableArea);

      CheckEdge(BORDER_DIVISOR * 8);

      if((found <> nil) and isArea) then begin
         {if there are no children in dockable area, then always dock to the whole area}
         if(found.W.w.n <= 1) then begin
            if(found.ExistChild(Self) > -1) then
               edge := uiDOCKABLE_WINDOW_EDGE_CENTER;
         end;

         if(edge = uiDOCKABLE_WINDOW_EDGE_CENTER) then begin
            {found center of docking area, but we're still gonna check if there's a dockable window in that position}
            foundDockingArea := uiTDockableArea(uiDockableWindow.Found);
            uiDockableWindow.ClearFound();
         end else
            exit;
      end;
   end;

   if(uiDockableWindow.Found = nil) then begin
      {if not in dockable area, then check the found window}
      uiTWindow(oxwParent).Find(GetUI().mSelect.startPoint.x, GetUI().mSelect.startPoint.y, s);

      found := s.GetSelectedWnd();
      if(found <> nil) and (IsDockableWindow(found)) and (not found.IsType(uiTDockableArea)) then begin
         if(uiTDockableWindow(found).TabParent <> nil) then
            found := uiTDockableWindow(found).TabParent;

         CheckEdge(BORDER_DIVISOR);

         if(uiDockableWindow.Found <> nil) then
            foundDockingArea := nil;
      end;
   end;

   {if there is a docking area to dock to}
   if(foundDockingArea <> nil) then begin
      uiDockableWindow.Found := foundDockingArea;
      uiDockableWindow.Found.RenderEdge := edge;
   end;
end;

procedure uiTDockableWindow.OnStartDrag();
begin
   Undock();

   OnAnyDrag();
end;

procedure uiTDockableWindow.OnDrag();
begin
   OnAnyDrag();
end;

procedure uiTDockableWindow.OnStopDrag();
begin
   if(uiDockableWindow.Found <> nil) then begin
      if(uiDockableWindow.Found.RenderEdge = uiDOCKABLE_WINDOW_EDGE_CENTER) then
         DockCenter(uiDockableWindow.Found)
      else if(uiDockableWindow.Found.RenderEdge = uiDOCKABLE_WINDOW_EDGE_LEFT) then
         DockLeft(uiDockableWindow.Found)
      else if(uiDockableWindow.Found.RenderEdge = uiDOCKABLE_WINDOW_EDGE_RIGHT) then
         DockRight(uiDockableWindow.Found)
      else if(uiDockableWindow.Found.RenderEdge = uiDOCKABLE_WINDOW_EDGE_UP) then
         DockUp(uiDockableWindow.Found)
      else if(uiDockableWindow.Found.RenderEdge = uiDOCKABLE_WINDOW_EDGE_DOWN) then
         DockDown(uiDockableWindow.Found);
   end;

   uiDockableWindow.ClearFound();
end;

procedure uiTDockableWindow.OnClose();
begin
   inherited OnClose;

   if(TabParent <> nil) then begin
      {if tab parent exists, remove from it}
      uiTDockableTabWindow(TabParent).TabWidget.RemoveTabWindow(Self);

      {no tabbed windows in container, then destroy it}
      if(TabParent.W.w.n = 1) then
         uiWindow.DisposeQueue(TabParent);
   end else
      Undock();

   uiDockableWindow.ClearFound();

   {destroy ourselves if instructed to do so}
   if(SelfDestroy) and (not (uiwndpDESTRUCTION_IN_PROGRESS in Properties)) then
      uiWindow.DisposeQueue(Self);
end;

procedure uiTDockableWindow.OnActivate();
begin
   inherited OnActivate;

   if(TabParent <> nil) then
      uiTDockableTabWindow(TabParent).SelectWindow(Self);
end;

procedure uiTDockableWindow.OnDocked();
begin

end;

procedure uiTDockableWindow.OnUndocked();
begin

end;

procedure uiTDockableWindow.OnTabbed();
begin

end;

procedure uiTDockableWindow.OnFloat();
begin

end;

INITIALIZATION
   {self destroy windows by default}
   uiDockableWindow.SelfDestroy := true;

END.
