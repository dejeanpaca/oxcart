{
   wdguTabs, tabs widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
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
      oxuUI, uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuDraw, uiuTypes,
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

      constructor Create(); override;
      procedure OnDestroy(); override;
      procedure DeInitialize(); override;

      procedure Point(var {%H-}e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      function Key(var k: appTKeyEvent): boolean; override;
      procedure Hover(x, y: longint; what: uiTHoverEvent); override;

      procedure RenderHorizontal();
      procedure RenderVertical();
      procedure Render(); override;

      procedure SetSelectedColor(associated: uiTControl = nil);

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

      {get height for the tabs widget}
      function GetHeight(): loopint;
      {get width for the tabs widget}
      function GetWidth(): loopint;

      {set the external reference}
      procedure SetReference(index: LongInt; ref: pointer);
      {get the external reference}
      function GetReference(index: LongInt): pointer;

      {called when a tab has a secondary click}
      procedure OnTabSecondaryClick({%H-}index: loopint); virtual;

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
      HeaderWidth,
      HeaderNonSelectedDecrease: loopint; static;

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
begin
   if(not Vertical) then
      RenderHorizontal()
   else
      RenderVertical();
end;

procedure wdgTTabs.SetSelectedColor(associated: uiTControl);
begin
   if(IsSelected()) then
      SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Highlight)
   else begin
      if((associated <> nil) and (oxui.Select.IsIn(associated) > -1)) then
         SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Highlight)
      else
         SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Highlight.Darken(0.3));
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

procedure wdgTTabs.RenderHorizontal();
var
   i,
   x,
   y: longint;

   current: wdgPTabEntry;

   r: oxTRect;
   f: oxTFont;

   pSkin: uiTSkin;

begin
   pSkin := GetSkinObject();

   if(RenderSurface) then begin
      {render surface border}
      SetColor(pSkin.Colors.Border);
      uiDraw.Rect(RPosition.x, RPosition.y - HeaderHeight,
         RPosition.x + Dimensions.w - 1, RPosition.y - Dimensions.h + 1);

      {fill surface}
      SetColor(pSkin.Colors.Surface);
      uiDraw.Box(RPosition.x + 1, RPosition.y - HeaderHeight - 1,
         RPosition.x + Dimensions.w - 2, RPosition.y - Dimensions.h + 2);
   end;

   if(Tabs.t.n < 1) then
      exit;

   {render tab titles}
   for i := 0 to (Tabs.t.n - 1) do begin
      current :=  @Tabs.t.List[i];
      x := RPosition.x + current^.x;
      y := RPosition.y;

      {draw the tab title border}
      SetColor(pSkin.Colors.Border);

      if(Tabs.Selected <> i) then begin
         uiDraw.Rect(x, y - wdgTabs.HeaderNonSelectedDecrease, x + current^.TotalWidth - 1, y - HeaderHeight + 1)
      end else
         uiDraw.Rect(x, y, x + current^.TotalWidth - 1, y - HeaderHeight + 1);

      {fill the tab title surface}
      if(Tabs.Selected <> i) then begin
         if(Tabs.Highlighted <> i) then
            SetColor(pSkin.Colors.Surface.Darken(0.3))
         else
            SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Focal);

         uiDraw.Box(x + 1, y - wdgTabs.HeaderNonSelectedDecrease - 1,
            x + current^.TotalWidth - 2, y - HeaderHeight + 1);
      end else begin
         SetSelectedColor(current^.AssociatedSelectedControl);

         uiDraw.Box(x + 1, y - 1, x + current^.TotalWidth - 2, y - HeaderHeight + 1);
      end;
   end;

   {now render tab title text}
   f := CachedFont;

   for i := 0 to (Tabs.t.n - 1) do begin
      current := @Tabs.t.List[i];
      r.x := RPosition.x + current^.x;
      r.y := RPosition.y;
      r.w := current^.TotalWidth;

      r.h := HeaderHeight;
      if(Tabs.Selected <> i) then begin
         dec(r.y, wdgTabs.HeaderNonSelectedDecrease);
         dec(r.h, wdgTabs.HeaderNonSelectedDecrease);
      end;

      f.Start();
         if(Tabs.Selected <> i) then
            SetColorBlended(pSkin.Colors.Text)
         else
            SetColorBlended(pSkin.Colors.TextInHighlight);

         f.WriteCentered(current^.Title, r);

      oxf.Stop();
   end;
end;

procedure wdgTTabs.RenderVertical();
var
   i,
   x,
   y: loopint;

   current: wdgPTabEntry;

   f: oxTFont;
   r: oxTRect;

   pSkin: uiTSkin;

begin
   pSkin := GetSkinObject();

   if(RenderSurface) then begin
      {render surface border}
      SetColor(pSkin.Colors.Border);
      uiDraw.Rect(RPosition.x + HeaderWidth, RPosition.y,
         RPosition.x + Dimensions.w - 1, RPosition.y - Dimensions.h + 1);

      {fill surface}
      SetColor(pSkin.Colors.Surface);
      uiDraw.Box(RPosition.x + HeaderWidth + 1, RPosition.y - 1,
         RPosition.x + Dimensions.w - 2, RPosition.y - Dimensions.h + 2);
   end;

   if(Tabs.t.n < 1) then
      exit;

   {render tab titles}
   for i := 0 to (Tabs.t.n - 1) do begin
      current :=  @Tabs.t.List[i];
      x := RPosition.x + current^.x;
      y := RPosition.y - current^.y;

      {draw the tab title border}
      SetColor(pSkin.Colors.Border);

      if(Tabs.Selected <> i) then begin
         uiDraw.Rect(x + wdgTabs.HeaderNonSelectedDecrease, y,
            x + current^.TotalWidth - 1, y - current^.TotalHeight + 1)
      end else
         uiDraw.Rect(x, y, x + current^.TotalWidth - 1, y - current^.TotalHeight + 1);

      {fill the tab title surface}
      if(Tabs.Selected <> i) then begin
         if(Tabs.Highlighted <> i) then
            SetColor(pSkin.Colors.Surface.Darken(0.3))
         else
            SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Focal);

         uiDraw.Box(x + 1 + wdgTabs.HeaderNonSelectedDecrease, y - 1,
            x + current^.TotalWidth - 2, y - current^.TotalHeight + 1)
      end else begin
         SetSelectedColor(current^.AssociatedSelectedControl);

         uiDraw.Box(x + 1, y - 1, x + current^.TotalWidth - 2, y - current^.TotalHeight + 1);
      end;
   end;

   {now render tab title text}
   f := CachedFont;

   for i := 0 to (Tabs.t.n - 1) do begin
      current := @Tabs.t.List[i];
      r.x := RPosition.x + current^.x;
      r.y := RPosition.y - current^.y;

      r.h := HeaderHeight;
      if(Tabs.Selected <> i) then
         dec(r.h, wdgTabs.HeaderNonSelectedDecrease);

      r.w := current^.TotalWidth;

      f.Start();
         if(Tabs.Selected <> i) then
            SetColorBlended(pSkin.Colors.Text)
         else
            SetColorBlended(pSkin.Colors.TextInHighlight);

         f.WriteCentered(current^.Title, r);

      oxf.Stop();
   end;
end;

procedure InitWidget();
begin
   wdgTabs.Internal.Done(wdgTTabs);

   wdgTabs := wdgTTabsGlobal.Create(wdgTabs.Internal);
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
      Container.Move(GetWidth(), GetHeight());
      Container.Resize(Dimensions.w - GetWidth(), GetHeight() + 1);
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
   Result.Vertical := vertical;

   if(vertical) then
      Result.HeaderWidth := wdgTabs.HeaderWidth;
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

   uiWidget.LastRect.SetDefault(GetHeight());
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

function wdgTTabs.GetHeight(): loopint;
begin
   if(not Vertical) then
      Result := Dimensions.h - HeaderHeight
   else
      Result := Dimensions.h - 1;
end;

function wdgTTabs.GetWidth(): loopint;
begin
   if(not Vertical) then
      Result := 0
   else
      Result := HeaderWidth;
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

INITIALIZATION
   wdgTabs.HeaderHeight := 40;
   wdgTabs.HeaderWidth := 80;
   wdgTabs.HeaderNonSelectedDecrease := 2;

   wdgTabs.internal.Register('widget.tabs', @InitWidget);

END.
