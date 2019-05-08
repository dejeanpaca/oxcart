{
   wdguMenubar, menu bar
   Copyright (C) 2016. Dejan Boras

   Started On:    24.11.2016.
}

{$INCLUDE oxdefines.inc}
UNIT wdguMenubar;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuMouse, appuEvents, appuKeys,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuTypes, uiuSkinTypes,
      uiuWindow, uiuWidget, uiWidgets, uiuControl, uiuDraw,
      {}
      uiuContextMenu, wdguWorkbar;

TYPE
   { wdgTMenubar }

   wdgTMenubar = class(wdgTWorkbar)
      Separation,
      SelectedMenu: loopint;
      {a more compact mode with a single button}
      HamburgerMode: boolean;

      {list of all items}
      Menus: uiTContextMenu;

      constructor Create(); override;
      procedure Initialize; override;
      destructor Destroy; override;

      function Add(const menuCaption: string): uiTContextMenu;

      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; x, y: longint); override;

      function Key(var k: appTKeyEvent): boolean; override;

      procedure DeInitialize; override;

      function HasItems(index: loopint): boolean;

      protected
         function OnWhere(x, y: loopint): loopint;
         procedure ShowMenu(idx: loopint);
   end;

   { wdgTMenubarGlobal }

   wdgTMenubarGlobal = record
      Color: TColor4ub;

      {default height}
      Height,
      {separation between menus}
      Separation,
      {horizontal padding}
      Padding,
      {bottom padding}
      BottomPadding: loopint;

      class function Add(wnd: uiTWindow): wdgTMenubar; static;
      class function Add(): wdgTMenubar; static;
   end;

VAR
   wdgMenubar: wdgTMenubarGlobal;

IMPLEMENTATION

CONST
   MENUBAR_HEIGHT = 20;
   MENUBAR_SEPARATION = 15;
   MENUBAR_PADDING = 5;
   MENUBAR_BOTTOM_PADDING = 2;
   MENUBAR_SELECTION_HIGHLIGHT_HEIGHT = 4;

   BAR_SPACING = 2;
   HAMBURGER_BAR_COUNT = 3;

TYPE
   wdgTMenubarContextWindow = class(uiTContextMenuWindow)
      Menubar: wdgTMenubar;
   end;

VAR
   internal: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := wdgTMenubar;
   internal.Done();
end;

{ wdgTMenubar }

constructor wdgTMenubar.Create();
begin
   inherited;

   Height := wdgMenubar.Height;
   Separation := wdgMenubar.Separation;

   SetPadding(wdgMenubar.Padding);
   PaddingBottom := wdgMenubar.BottomPadding;

   Menus := uiTContextMenu.Create('');

   SelectedMenu := -1;
end;

procedure wdgTMenubar.Initialize;
begin
   inherited Initialize;

   Color := wdgMenubar.Color;
end;

destructor wdgTMenubar.Destroy;
begin
   inherited Destroy;

   FreeObject(Menus);
end;

function wdgTMenubar.Add(const menuCaption: string): uiTContextMenu;
begin
   Result := Menus.AddSub(menuCaption);
end;

procedure wdgTMenubar.Render();
var
   f: oxTFont;
   r: oxTRect;
   selectedItemCount,
   i: loopint;
   colors: uiPSkinColorSet;
   selected,
   current: uiPContextMenuItem;
   dim,
   barSize: loopint;

begin
   colors := GetColorset();

   SetColor(Color);
   uiDraw.Box(RPosition, Dimensions);

   if(HamburgerMode) then begin
      if(Dimensions.w > Dimensions.h) then
         dim := Dimensions.h
      else
         dim := Dimensions.w;

      SetColor(colors^.Text);

      barSize := (dim - ((HAMBURGER_BAR_COUNT + 1) * BAR_SPACING)) div HAMBURGER_BAR_COUNT;

      r.x := RPosition.x + BAR_SPACING;
      r.y := RPosition.y - BAR_SPACING;
      r.w := dim - BAR_SPACING * 2;
      r.h := barSize;

      for i := 0 to HAMBURGER_BAR_COUNT - 1 do begin
         uiDraw.Box(r);
         dec(r.y, barSize + BAR_SPACING);
      end;

      SetColor(colors^.Text.Darken(0.3));
      r.y := RPosition.y - BAR_SPACING;

      for i := 0 to HAMBURGER_BAR_COUNT - 1 do begin
         uiDraw.HLine(r.x, r.y - barSize + 1, r.x + r.w - 1);
         dec(r.y, barSize + BAR_SPACING);
      end;

      exit;
   end;

   if(Menus.Items.n > 0) then begin
      f := CachedFont;
      r.x := RPosition.x + PaddingLeft;

      selectedItemCount := 0;

      selected := nil;
      if(SelectedMenu <> -1) then begin
         selected := @Menus.Items.List[SelectedMenu];

         if(selected^.Sub <> nil) then
            selectedItemCount := uiTContextMenu(Menus.Items[SelectedMenu].Sub).Items.n
      end;


      if(selectedItemCount > 0) and ((IsSelected()) or (uiContextMenu.Owner = Self)) then begin
         if(SelectedMenu > 0) then begin
            for i := 0 to (SelectedMenu - 1) do
               inc(r.x, f.GetLength(Menus.Items.List[i].Caption) + Separation);

            dec(r.x, Separation div 2);
         end;

         r.h := MENUBAR_SELECTION_HIGHLIGHT_HEIGHT;
         r.y := RPosition.y - Dimensions.h + MENUBAR_SELECTION_HIGHLIGHT_HEIGHT;
         r.w := f.GetLength(selected^.Caption);
         if(SelectedMenu > 0) then
            inc(r.w, Separation)
         else begin
            dec(r.x, PaddingLeft);
            inc(r.w, Separation div 2);
         end;

         SetColor(colors^.Highlight);
         uiDraw.Box(r);
      end;

      {return to start position}
      r.x := RPosition.x + PaddingLeft;
      r.h := Dimensions.h;
      r.y := RPosition.y;
      r.w := Dimensions.w;

      f.Start();

      for i := 0 to (Menus.Items.n - 1) do begin
         current := @Menus.Items.List[i];

         if(current^.Properties.IsSet(uiCONTEXT_MENU_ITEM_ENABLED)) and
         (uiTContextMenu(current^.Sub).Items.n > 0) then
            SetColorBlended(colors^.Text)
         else
            SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).DisabledColors.Text);

         f.Write(r.x, r.y - r.h + 1 + PaddingBottom, current^.Caption);

         inc(r.x, f.GetLength(current^.Caption) + Separation);
      end;

      oxf.Stop();
   end;
end;

function contextWindowListener({%H-}wnd: uiTControl; const event: appTEvent): longint;
begin
   Result := -1;

   {when primary context window closes, we unselect any menu}
   if(uiWindow.GetNotification(event) = uiWINDOW_CLOSE) then
      wdgTMenubarContextWindow(wnd).Menubar.SelectedMenu := -1;
end;

procedure wdgTMenubar.Point(var e: appTMouseEvent; x, y: longint);
var
   idx: longint;

begin
   if(not HamburgerMode) then begin
      if(e.Action.IsSet(appmcPRESSED)) then begin
         idx := OnWhere(x, y);
         SelectedMenu := idx;
      end else if(e.Action.IsSet(appmcRELEASED)) then begin
         idx := OnWhere(x, y);

         if(idx > -1) and (HasItems(idx)) then
            ShowMenu(idx);

         SelectedMenu := idx;
      end;
   end else begin
      if(e.Action.IsSet(appmcRELEASED)) then begin
         idx := OnWhere(x, y);

         if(idx = 0) then
            ShowMenu(0);
      end;
   end;
end;

function wdgTMenubar.Key(var k: appTKeyEvent): boolean;
begin
   Result := true;

   if k.Key.Equal(kcLEFT) then begin
      if(SelectedMenu > 0) and k.Key.Released() then
         dec(SelectedMenu);
   end else if k.Key.Equal(kcRIGHT) then begin
      if(SelectedMenu < Menus.Items.n - 1) and k.Key.Released() then
         Inc(SelectedMenu);
   end else if k.Key.Equal(kcSPACE) or k.Key.Equal(kcENTER) then begin
      if(k.Key.Released()) then
         ShowMenu(SelectedMenu);
   end else
      Result := false;
end;

procedure wdgTMenubar.DeInitialize;
begin
   uiContextMenu.ClearOwner(Self);
end;

function wdgTMenubar.HasItems(index: loopint): boolean;
begin
   Result := (Menus.Items.List[index].Sub <> nil) and (uiTContextMenu(Menus.Items.List[index].Sub).Items.n > 0);
end;

function wdgTMenubar.OnWhere(x, y: loopint): loopint;
var
   f: oxTFont;
   rx,
   i: loopint;
   hamburgerClicked: boolean;

begin
   if(Menus.Items.n > 0) then begin
      if(not HamburgerMode) then begin
         rx := 0;
         inc(rx, PaddingLeft);

         f := CachedFont;

         for i := 0 to (Menus.Items.n - 1) do begin
            if(x >= rx) and (x < rx + f.GetLength(Menus.Items.List[i].Caption)) then begin
               exit(i);
            end;

            inc(rx, f.GetLength(Menus.Items.List[i].Caption) + Separation);
         end;
      end else begin
         if(Dimensions.w > Dimensions.h) then
            hamburgerClicked := x < Dimensions.h
         else
            hamburgerClicked := y >= Dimensions.h - Dimensions.w;

         if(hamburgerClicked) then
            exit(0);
      end;
   end;

   Result := -1;
end;

procedure wdgTMenubar.ShowMenu(idx: loopint);
var
   r: oxTRect;
   dim: oxTDimensions;
   i,
   rx: loopint;
   f: oxTFont;
   current: uiTContextMenu;

begin
   if(HamburgerMode) then begin
      dim := Menus.GetDimensions();

      r.x := RPosition.x + 2;
      r.y := RPosition.y - Dimensions.h;
      r.w := dim.w;
      r.h := dim.h;

      uiContextMenu.Instance := wdgTMenubarContextWindow;
      Menus.Show(r, Self);

      wdgTMenubarContextWindow(uiContextMenu.Windows[0].wnd).Menubar := Self;
      wdgTMenubarContextWindow(uiContextMenu.Windows[0].wnd).AddListener(@contextWindowListener);
      uiContextMenu.Owner := Self;

      exit;
   end;

   if(Menus.Items.n > 0) and (Menus.Items[idx].Properties.IsSet(uiCONTEXT_MENU_ITEM_ENABLED)) then begin
      rx := 0;
      inc(rx, PaddingLeft);

      f := CachedFont;

      for i := 0 to idx do begin
         current := uiTContextMenu(Menus.Items[idx].Sub);

         if(i = idx) then begin
            dim := current.GetDimensions();

            r.x := RPosition.x + rx;
            r.y := RPosition.y - Dimensions.h;
            r.w := dim.w;
            r.h := dim.h;

            uiContextMenu.Instance := wdgTMenubarContextWindow;
            current.Show(r, Self);

            wdgTMenubarContextWindow(uiContextMenu.Windows[0].wnd).Menubar := Self;
            wdgTMenubarContextWindow(uiContextMenu.Windows[0].wnd).AddListener(@contextWindowListener);
            uiContextMenu.Owner := Self;

            exit;
         end;

         inc(rx, f.GetLength(Menus.Items[i].Caption) + Separation);
      end;
   end;
end;

{ wdgTMenubarGlobal }

class function wdgTMenubarGlobal.Add(wnd: uiTWindow): wdgTMenubar;
begin
   uiWidget.SetTarget(wnd);
   Result := Add();
end;

class function wdgTMenubarGlobal.Add(): wdgTMenubar;
begin
   Result := wdgTMenubar(uiWidget.Add(internal, oxNullPoint, oxNullDimensions));

   Result.AutoPosition();
end;

INITIALIZATION
   internal.Register('widget.menubar', @initializeWidget);

   wdgMenubar.Color.Assign(24, 24, 32, 255);
   wdgMenubar.Height := MENUBAR_HEIGHT;
   wdgMenubar.Separation := MENUBAR_SEPARATION;
   wdgMenubar.Padding := MENUBAR_PADDING;
   wdgMenubar.BottomPadding := MENUBAR_BOTTOM_PADDING;

END.
