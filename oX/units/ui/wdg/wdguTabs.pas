{
   wdguTabs, tabs widget for the UI
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguTabs;

INTERFACE

   USES
      uStd, uColors,
      appuKeys, appuMouse,
      {oX}
      oxuFont, oxuTypes,
      {ui}
      uiuControl, uiuControls, uiuWindowTypes, uiuSkinTypes,
      oxuUI, uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuDraw, uiuTypes, uiuWidgetRender,
      wdguBase, wdguEmpty;

TYPE

   { wdgTTabContainer }

   wdgTTabContainer = class(uiTWidget)
      {container parent}
      TabsParent: uiTWidget;

      procedure DeInitialize(); override;
   end;


   wdgPTabEntry = ^wdgTTabEntry;
   wdgTTabEntry = record
      {tab title}
      Title,
      {tab ID}
      ID: StdString;

      {does this entry require a surface to be rendered (disable if surface is overdrawn)}
      RequiresSurfaceRender: boolean;

      {relative horizontal position}
      x,
      {relative vertical position}
      y,
      {width of the title}
      TotalWidth,
      {title height}
      TotalHeight: longint;

      {control associated with this tab}
      AssociatedSelectedControl: uiTControl;

      {for external references required per tab, not used by the widget itself}
      External: pointer;

      Widgets: uiTWidgets;
   end;

   wdgTTabsSimpleList = specialize TSimpleList<wdgTTabEntry>;

   { wdgTTabs }

   wdgTTabs = class(uiTWidget)
      public
         Vertical: boolean;
         RenderSurface,
         RequiresWidgets: boolean;
         HeaderHeight,
         HeaderWidth: loopint;
         Container: wdgTTabContainer;

         LastPointerPosition: oxTPoint;
         SurfaceOffset: oxTPoint;
         SurfaceDimensions: oxTDimensions;

      constructor Create(); override;
      procedure OnDestroy(); override;
      procedure DeInitialize(); override;

      procedure Point(var {%H-}e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      function Key(var k: appTKeyEvent): boolean; override;
      procedure Hover(x, y: longint; what: uiTHoverEvent); override;

      procedure Render(); override;
      procedure RenderTabHeader(const r: oxTRect; tabIndex: loopint; tabPosition: uiTControlGridPosition);

      procedure GetHeaderColor(tabIndex: loopint; out usedColor: TColor4ub);
      procedure GetSelectedColor(out usedColor: TColor4ub; associated: uiTControl = nil);

      {add a tab}
      function AddTab(const Title: StdString; const tabID: StdString = ''): wdgPTabEntry;
      {should be called when done adding widgets completely}
      procedure Done();
      {checks if there is a tab with the specified id, and returns its index}
      function HasTab(const tabID: StdString): longint;
      {selects the specified tab}
      function Select(const tabID: StdString): boolean;
      {select tab by its index number}
      function SelectByNum(index: longint): boolean;
      {select tab by its index number}
      procedure SelectLast();
      {select next tab}
      procedure SelectNext();
      {select previous tab}
      procedure SelectPrevious();

      {removes tab at the specified index}
      procedure RemoveTabByNum(index: loopint);

      function GetContainerDimensions(): oxTDimensions;

      {set the external reference}
      procedure SetReference(index: LongInt; ref: pointer);
      {get the external reference}
      function GetReference(index: LongInt): pointer;

      {called when a tab has a secondary click}
      procedure OnTabSecondaryClick({%H-}index: loopint); virtual;

      {set tabs as vertical}
      procedure SetVertical(useVertical: boolean);

      protected
         Tabs: record
            Highlighted,
            Selected,
            Spacer,
            TotalWidth,
            TotalHeight: loopint;

            t: wdgTTabsSimpleList;
         end;

         function OnWhat(x, y: longint; out tabIndex: loopint): loopint;
         {recalculate and store various aspects of the tabs widget}
         procedure Recalculate();
         {setup the container holding the widgets}
         procedure SetupContainer();
         {called when selected tab changes}
         procedure OnTabSelectChange({%H-}index: longint); virtual;
         procedure SizeChanged(); override;
   end;

   { wdgTTabsGlobal }

   wdgTTabsGlobal = class(specialize wdgTBase<wdgTTabs>)
      Internal: uiTWidgetClass; static;

      HeaderHeight,
      HeaderWidth: loopint; static;

      {adds a tabs widget to a window}
      function Add(const Pos: oxTPoint; const Dim: oxTDimensions; vertical: boolean = false): wdgTTabs;
   end;

VAR
   wdgTabs: wdgTTabsGlobal;

IMPLEMENTATION

CONST
   ON_TAB_SURFACE    = -1; {point is on the tab surface}
   ON_NOTHING        = 0; {point is nowhere on the tab}
   ON_TAB_HEADER     = 1; {point is on the tab header}
   {ON_TAB_HEADER + number of tab (0..n-1) is returned by onWhat}

{ wdgTTabContainer }

procedure wdgTTabContainer.DeInitialize();
var
   tabs: wdgTTabs;

begin
   inherited DeInitialize;

   tabs := wdgTTabs(TabsParent);

   if(tabs <> nil) then begin
      if(tabs.Tabs.t.n > 0) then
         Widgets := Tabs.Tabs.t.List[0].Widgets;

      tabs.Container := nil;
   end;
end;

function wdgTTabs.OnWhat(x, y: longint; out tabIndex: loopint): loopint;
var
   current: wdgPTabEntry;
   i: loopint;

begin
   Result := ON_NOTHING;
   tabIndex := -1;

   if(not Vertical) then begin
      {if the point is below headers then this must mean were on the tab surface}
      if(y < (Dimensions.h - HeaderHeight + 1)) then
         exit(ON_TAB_SURFACE)
      {otherwise we'll check if the point is over any tab headers}
      else begin
         for i := 0 to (Tabs.t.n - 1) do begin
            current := @Tabs.t.List[i];

            {check each tab}
            if(x >= current^.x) and (x < current^.x + current^.TotalWidth) then begin
               tabIndex := i;
               exit(ON_TAB_HEADER);
            end;
         end;
      end;
   end else begin
      {if the point is below headers then this must mean were on the tab surface}
      if(x > HeaderWidth + 1) then
         exit(ON_TAB_SURFACE)
      {otherwise we'll check if the point is over any tab headers}
      else begin
         for i := 0 to (Tabs.t.n - 1) do begin
            current := @Tabs.t.List[i];

            {check each tab}
            if(y < Dimensions.h - current^.y) and (y > Dimensions.h - current^.y - current^.TotalHeight) then begin
               tabIndex := i;
               exit(ON_TAB_HEADER);
            end;
         end;
      end;
   end;
end;

constructor wdgTTabs.Create();
begin
   inherited;

   RenderSurface := true;
   RequiresWidgets := true;
   HeaderHeight := wdgTabs.HeaderHeight;

   Tabs.t.InitializeValues(Tabs.t);
   Tabs.Highlighted := -1;
end;

procedure wdgTTabs.OnDestroy();
var
   i: loopint;

begin
   inherited;

   if(not RequiresWidgets) then
      exit;

   SelectByNum(0);

   {destroy all tab widgets, except the first one as that's used by container widgets}
   if(Tabs.t.n > 0) then begin
      {destroy the rest}
      for i := 1 to (Tabs.t.n - 1) do begin
         Container.Widgets := Tabs.t.List[i].Widgets;

         uiWidget.Dispose(Container.Widgets);
      end;

      Container.Widgets := Tabs.t.List[0].Widgets;
   end;

   Tabs.t.Dispose();
end;


procedure wdgTTabs.DeInitialize();
begin
   Container := nil;
end;

procedure wdgTTabs.Point(var e: appTMouseEvent; x, y: longint);
var
   tabIndex,
   whaton: loopint;

begin
   LastPointerPosition.x := x;
   LastPointerPosition.y := y;

   if(e.Action = appmcRELEASED) and (e.Button = appmcLEFT) then begin
      whaton := OnWhat(x, y, tabIndex);

      if(whaton = ON_TAB_HEADER) then begin
         SelectByNum(tabIndex);
      end;
   end else if(e.Action = appmcRELEASED) and (e.Button = appmcRIGHT) then begin
      whaton := OnWhat(x, y, tabIndex);

      if(whaton = ON_TAB_HEADER) then begin
         OnTabSecondaryClick(tabIndex);
      end;
   end;
end;

procedure wdgTTabs.Render();
var
   i: loopint;

   requiresSurface: boolean;
   current: wdgPTabEntry;

   f: oxTFont;
   r: oxTRect;

   pSkin: uiTSkin;

begin
   pSkin := GetSkinObject();

   requiresSurface := RenderSurface;

   {don't render if this tab doesn't require it}
   if(Tabs.Selected > 0) then
      requiresSurface := requiresSurface and Tabs.t[Tabs.Selected].RequiresSurfaceRender;

   if(requiresSurface) then begin
      r.x := RPosition.x + SurfaceOffset.x;
      r.y := RPosition.y - SurfaceOffset.y;
      r.w := SurfaceDimensions.w;
      r.h := SurfaceDimensions.h;

      {render surface border}
      SetColor(pSkin.Colors.Border);
      uiDraw.Rect(r);

      {fill surface}
      SetColor(pSkin.Colors.Surface);
      r.x := r.x + 1;
      r.y := r.y - 1;
      r.w := r.w - 2;
      r.h := r.h - 2;

      uiDraw.Box(r);
   end;

   if(Tabs.t.n < 1) then
      exit;

   {render tab titles}
   for i := 0 to (Tabs.t.n - 1) do begin
      current :=  @Tabs.t.List[i];
      r.x := RPosition.x + current^.x;
      r.y := RPosition.y - current^.y;
      r.w := current^.TotalWidth;
      r.h := current^.TotalHeight;

      if(Vertical) then
         RenderTabHeader(r, i, [uiCONTROL_GRID_LEFT])
      else
         RenderTabHeader(r, i, [uiCONTROL_GRID_TOP])
   end;

   {now render tab title text}
   f := CachedFont;

   for i := 0 to (Tabs.t.n - 1) do begin
      current := @Tabs.t.List[i];
      r.x := RPosition.x + current^.x;
      r.y := RPosition.y - current^.y;
      r.w := current^.TotalWidth;
      r.h := current^.TotalHeight;

      f.Start();
         if(Tabs.Selected <> i) then
            SetColorBlended(pSkin.Colors.Text)
         else
            SetColorBlended(pSkin.Colors.TextInHighlight);

         f.WriteCentered(current^.Title, r);

      oxf.Stop();
   end;
end;

procedure wdgTTabs.RenderTabHeader(const r: oxTRect; tabIndex: loopint; tabPosition: uiTControlGridPosition);
var
   renderProperties: TBitSet;
   usedColor: TColor4ub;

begin
   GetHeaderColor(tabIndex, usedColor);

   renderProperties := wdgRENDER_BLOCK_SURFACE or wdgRENDER_BLOCK_BORDER or wdgRENDER_CORNERS;

   renderProperties := renderProperties or uiRenderWidget.GetCurvedFrameProperties(tabPosition);
   uiRenderWidget.Box(r, usedColor, usedColor, renderProperties, uiTWindow(wnd).opacity);
end;

procedure wdgTTabs.GetHeaderColor(tabIndex: loopint; out usedColor: TColor4ub);
begin
   {fill the tab title surface}
   if(Tabs.Selected <> tabIndex) then begin
      if(Tabs.Highlighted <> tabIndex) then
         usedColor := uiTSkin(uiTWindow(wnd).Skin).Colors.Surface.Darken(0.3)
      else
         usedColor := uiTSkin(uiTWindow(wnd).Skin).Colors.Focal;
   end else
      GetSelectedColor(usedColor, Tabs.t.List[tabIndex].AssociatedSelectedControl);
end;

procedure wdgTTabs.GetSelectedColor(out usedColor: TColor4ub; associated: uiTControl = nil);
begin
   usedColor := uiTSkin(uiTWindow(wnd).Skin).Colors.Surface.Darken(0.3);

   if(IsSelected()) then
      usedColor := uiTSkin(uiTWindow(wnd).Skin).Colors.Highlight
   else begin
      if((associated <> nil) and (oxui.Select.IsIn(associated) > -1)) then
         usedColor := uiTSkin(uiTWindow(wnd).Skin).Colors.Highlight
      else
         usedColor := uiTSkin(uiTWindow(wnd).Skin).Colors.Highlight.Darken(0.3);
   end;
end;

function wdgTTabs.Key(var k: appTKeyEvent): boolean;
begin
   Result := false;

   if(k.Key.Released()) then begin
      if(k.Key.Equal(kcTAB, kmCONTROL or kmSHIFT)) then begin
         if(k.Key.Released()) then
            SelectPrevious();

         Result := true;
      end else if(k.Key.Equal(kcTAB, kmCONTROL)) then begin
         if(k.Key.Released()) then
            SelectNext();

         Result := true;
      end else if(k.Key.IsContext()) then begin
         if(k.Key.Released()) then begin
            if(Tabs.Selected > -1) then
               LastPointerPosition.x := Tabs.t[Tabs.Selected].x
            else
               LastPointerPosition.x := 0;

            LastPointerPosition.y := Dimensions.h;

            OnTabSecondaryClick(Tabs.Selected);
         end;

         Result := true;
      end;
   end;
end;

procedure wdgTTabs.Hover(x, y: longint; what: uiTHoverEvent);
begin
   if(what <> uiHOVER_NO) then begin
      if(OnWhat(x, y, Tabs.Highlighted) <> ON_TAB_HEADER) then
         Tabs.Highlighted := -1;
   end else
      Tabs.Highlighted := -1;
end;

{recalculate the size of the individual tabs}
procedure wdgTTabs.Recalculate();
var
   i, x, y: longint;
   current: wdgPTabEntry;
   f: oxTFont;

begin
   f := CachedFont;

   {get the size of the spacer (space before and after a tab title)}
   Tabs.Spacer := f.GetWidth() div 2;
   Tabs.TotalWidth := 0;
   Tabs.TotalHeight := 0;
   x := 0;
   y := 0;

   {calculate sizes}
   for i := 0 to (Tabs.t.n - 1) do begin
      {calculate the width of the current tab}
      current := @Tabs.t.List[i];
      current^.TotalWidth := HeaderWidth;
      current^.TotalHeight := HeaderHeight;
      current^.x := 0;
      current^.y := 0;

      if(not Vertical) then begin
         current^.TotalWidth := f.GetLength(current^.Title) + 2 + Tabs.Spacer * 2;
         current^.x := x;
         inc(current^.TotalWidth, Length(current^.Title) * 1);

         {move to the next}
         inc(x, current^.TotalWidth);

         if(i < Tabs.t.n - 1) then
            inc(x, 1);

         {calculate the total width}
         Tabs.TotalWidth := current^.TotalWidth;

         if(i < Tabs.t.n - 1) then
            inc(Tabs.TotalWidth); {we need 1 pixel of space between tabs}
      end else begin
         current^.y := y;

         {move to next}
         inc(y, current^.TotalHeight);

         if(i < Tabs.t.n - 1) then
            inc(y, 1);

         Tabs.TotalHeight := current^.TotalHeight;
      end;
   end;

   if(not Vertical) then
      Tabs.TotalHeight := HeaderHeight
   else
      Tabs.TotalWidth := HeaderWidth;

   SetupContainer();
end;

procedure wdgTTabs.SetupContainer();
begin
   if(Container <> nil) then begin
      Container.Move(SurfaceOffset.x, Dimensions.h - SurfaceOffset.y);
      Container.Resize(GetContainerDimensions());
   end;
end;

procedure wdgTTabs.OnTabSelectChange(index: longint);
begin

end;

procedure wdgTTabs.SizeChanged();
begin
   if(not(wdgpDESTROY_IN_PROGRESS in Properties)) then
      SetupContainer();
end;

function wdgTTabsGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions; vertical: boolean): wdgTTabs;
begin
   Result := wdgTTabs(uiWidget.Add(internal, Pos, Dim));
   Result.SetVertical(vertical);
end;

function wdgTTabs.AddTab(const Title: StdString; const tabID: StdString): wdgPTabEntry;
var
   t: wdgTTabEntry;

begin
   if(Container = nil) and (RequiresWidgets) then begin
      SetTarget();

      uiWidget.Create.Instance := wdgTTabContainer;

      Container := wdgTTabContainer(wdgEmpty.Add(oxNullPoint, oxNullDimensions));
      Container.TabsParent := Self;
      Container.SetTarget();

      SetupContainer();
   end;

   ZeroPtr(@t, SizeOf(t));

   t.Title := Title;
   t.ID := tabID;
   t.RequiresSurfaceRender := true;
   uiTControls.Initialize(uiTControls(t.Widgets));

   Tabs.t.Add(t);

   Result := Tabs.t.GetLast();

   {store current widgets to the tab}
   if(RequiresWidgets) then begin
      if(Tabs.t.n > 1) then begin
         Tabs.t.List[Tabs.t.n - 2].Widgets := uiTWidgets(Container.Widgets);

         uiTControls.Initialize(uiTControls(Container.Widgets));
      end;
   end;

   Recalculate();

   uiWidget.LastRect.SetDefault(Dimensions.h - SurfaceOffset.y);
end;

procedure wdgTTabs.Done();
begin
   uiWidget.SetTarget(uiTWindow(wnd));

   if(Tabs.t.n > 1) then
      Tabs.t.List[Tabs.t.n - 1].Widgets := uiTWidgets(Container.Widgets);

   if(Tabs.t.n > 0) then
      SelectByNum(0);
end;

function wdgTTabs.HasTab(const tabID: StdString): longint;
var
   i: longint;

begin
   for i := 0 to (Tabs.t.n - 1) do
      if(Tabs.t.List[i].ID = tabID) then
         exit(i);

   Result := -1;
end;

{select a tab}
function wdgTTabs.Select(const tabID: StdString): boolean;
var
   i: longint;

begin
   if(tabID <> '') and (Tabs.t.n > 0) then begin
      for i := 0 to (Tabs.t.n - 1) do begin
         if(Tabs.t.List[i].ID = tabID) then
            exit(SelectByNum(i));
      end;
   end;

   Result := false;
end;

{select a tab by it's number (in order of tabs)}
function wdgTTabs.SelectByNum(index: longint): boolean;
begin
   Result := false;

   if(Tabs.t.n > 0) then begin
      if(index < 0) then
         index := 0
      else if(index >= Tabs.t.n) then
         index := Tabs.t.n - 1;

      Tabs.Selected := index;
      Result := true;

      if(RequiresWidgets and (Container <> nil)) then
         Container.Widgets := Tabs.t.List[index].Widgets;

      if(not (wdgpDESTROY_IN_PROGRESS in Properties)) then
         OnTabSelectChange(Tabs.Selected);
   end;
end;

procedure wdgTTabs.SelectLast();
begin
   if(Tabs.t.n > 0) then
      SelectByNum(Tabs.t.n - 1);
end;

procedure wdgTTabs.SelectNext();
begin
   if(Tabs.t.n > 0) then begin
      if(Tabs.Selected < Tabs.t.n - 1) then begin
         SelectByNum(Tabs.Selected + 1);
      end else
         SelectByNum(0);
   end;
end;

procedure wdgTTabs.SelectPrevious();
begin
   if(Tabs.t.n > 0) then begin
      if(Tabs.Selected > 0) then begin
         SelectByNum(Tabs.Selected - 1);
      end else
         SelectByNum(Tabs.t.n - 1);
   end;
end;

procedure wdgTTabs.RemoveTabByNum(index: loopint);
begin
   if(index >= 0) and (index < Tabs.t.n) then begin
      if(RequiresWidgets) then begin
         if(Tabs.t.n > 1) then
            uiWidget.Dispose(Tabs.t.List[index].Widgets)
      end;

      Tabs.t.List[index].External := nil;
      Tabs.t.List[index].AssociatedSelectedControl := nil;
      Tabs.t.Remove(index);

      {reselect since the order might have changed}
      SelectByNum(Tabs.Selected);

      Recalculate();
   end;
end;

function wdgTTabs.GetContainerDimensions(): oxTDimensions;
begin
   {- 2 is here for the borders}
   Result.w := SurfaceDimensions.w - 2;
   Result.h := SurfaceDimensions.h - 2;
end;

procedure wdgTTabs.SetReference(index: LongInt; ref: pointer);
begin
   if(index > -1) and (index < Tabs.t.n) then
      Tabs.t.List[index].External := ref;
end;

function wdgTTabs.GetReference(index: LongInt): pointer;
begin
   if(index > -1) and (index < Tabs.t.n) then
      Result := Tabs.t.List[index].External
   else
      Result := nil;
end;

procedure wdgTTabs.OnTabSecondaryClick(index: loopint);
begin

end;

procedure wdgTTabs.SetVertical(useVertical: boolean);
begin
   Vertical := useVertical;

   SurfaceOffset.x := 0;
   SurfaceOffset.y := 0;

   if(Vertical) then begin
      HeaderWidth := wdgTabs.HeaderWidth;
      SurfaceOffset.x := HeaderWidth;
   end else begin
      SurfaceOffset.y := HeaderHeight;
   end;

   SurfaceDimensions.w := Dimensions.w - SurfaceOffset.x;
   SurfaceDimensions.h := Dimensions.h - SurfaceOffset.y;
end;

procedure init();
begin
   wdgTabs.Internal.Done(wdgTTabs);

   wdgTabs := wdgTTabsGlobal.Create(wdgTabs.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgTabs);
end;

INITIALIZATION
   wdgTabs.HeaderHeight := 40;
   wdgTabs.HeaderWidth := 80;

   wdgTabs.internal.Register('tabs', @init, @deinit);

END.
