{
   wdguDropDownList, drop down list
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguDropDownList;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuDraw, uiuRegisteredWidgets, uiuWidgetWindow, uiuWindow,
      {}
      wdguList, wdguBase;

TYPE
   wdgTDropDownListItems = specialize TSimpleList<string>;

   { wdgTDropDownList }
   {the drop down anchor}
   wdgTDropDownList = class(uiTWidget)
      {currently selected item}
      CurrentItem,
      {width of the drop area}
      DropAreaWidth,
      {height of items}
      ItemHeight,
      {padding for items}
      ItemPadding: longint;
      {list of all items}
      Items: wdgTDropDownListItems;
      {is the source of items external}
      ExternalSource: boolean;

      constructor Create(); override;

      {add an item to the list}
      procedure Add(const item: StdString);
      {select an item by its index}
      procedure SelectItem(item: longint);
      {remove all items}
      procedure Clear();
      {remove the current item}
      procedure RemoveCurrent(); virtual;

      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;

      function GetValue(index: loopint): StdString;
      function GetItemCount(): loopint;

      procedure ShowMenu();
      procedure CloseMenu();
      function GetMenuDimensions(): oxTDimensions;

      procedure DeInitialize; override;

      protected
         MenuWindow: uiTWidgetWindow;
         procedure SelectedItemChanged(); virtual;
   end;

   { wdgTDropDownListMenu }
   {used to handle the drop down menu}
   wdgTDropDownListMenu = class(wdgTStringListBase)
      List: wdgTDropDownList;

      constructor Create(); override;
      procedure Initialize(); override;

      function GetItemCount(): loopint; override;
      procedure RenderItem(index: loopint; r: oxTRect); override;

      protected
         procedure ItemClicked(idx: loopint; button: TBitSet = appmcLEFT); override;
   end;

   { wdgTDropDownListGlobal }

   wdgTDropDownListGlobal = object(specialize wdgTBase<wdgTDropDownList>)
      DropAreaWidth: longint; static;
   end;

   { wdgTDropDownListMenuGlobal }

   wdgTDropDownListMenuGlobal = object(specialize wdgTBase<wdgTDropDownListMenu>)
   end;

VAR
   wdgDropDownList: wdgTDropDownListGlobal;
   wdgDropDownListMenu: wdgTDropDownListMenuGlobal;

IMPLEMENTATION

CONST
   MENU_VERTICAL_SEPARATION   = 0;
   MENU_PADDING_SIZE          = 0;
   MENU_BORDER_SIZE           = 1;
   MENU_ITEM_HEIGHT           = 18;
   MENU_ITEM_PADDING          = 3;

{ wdgTDropDownListMenu }

constructor wdgTDropDownListMenu.Create();
begin
   inherited;

   Clickable := true;
   HighlightHovered := true;
   SelectBorder := false;

   VerticalSeparation := MENU_VERTICAL_SEPARATION;
   SetPadding(MENU_PADDING_SIZE);
   SetBorder(MENU_BORDER_SIZE);
   ItemPadding := MENU_ITEM_PADDING;
end;

procedure wdgTDropDownListMenu.Initialize;
begin
   inherited Initialize;

   {get the menu reference when the widget is created}
   List := wdgTDropDownList(uiTWidgetWindowInternal(Parent).ExternalData);

   ItemsChanged();
   SetItemHeight(List.ItemHeight);
   ItemPadding := List.ItemPadding;
end;

function wdgTDropDownListMenu.GetItemCount: loopint;
begin
   if(List <> nil) then
      result := List.GetItemCount()
   else
      result := 0;
end;

procedure wdgTDropDownListMenu.RenderItem(index: loopint; r: oxTRect);
var
   ir: oxTRect;

begin
   if(HighlightedItem <> index) then
      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text)
   else
      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.TextInHighlight);

   ir := r;
   inc(ir.x, ItemPadding);
   dec(ir.w, ItemPadding * 2);

   oxf.GetSelected().WriteCentered(List.GetValue(index), ir, [oxfpCenterVertical]);
end;

procedure wdgTDropDownListMenu.ItemClicked(idx: loopint;  button: TBitSet);
begin
   if(button = appmcLEFT) then begin
      list.SelectItem(idx);

      uiTWidgetWindowInternal(wnd).WidgetWindow^.Destroy();
   end;
end;

{ wdgTDropDownList }

constructor wdgTDropDownList.Create();
begin
   inherited;

   DropAreaWidth := wdgDropDownList.DropAreaWidth;
   ItemHeight := MENU_ITEM_HEIGHT;
   ItemPadding := MENU_ITEM_PADDING;
   CurrentITem := -1;
   SetPadding(2);

   Items.InitializeValues(Items);
end;

procedure wdgTDropDownList.Add(const item: StdString);
begin
   Items.Add(item);
end;

procedure wdgTDropDownList.SelectItem(item: longint);
begin
   if(item >= 0) and (item < GetItemCount()) then begin
      CurrentItem := item;
      SelectedItemChanged();
   end;
end;

procedure wdgTDropDownList.Clear();
begin
   CloseMenu();
   CurrentItem := -1;

   Items.Dispose();
end;

procedure wdgTDropDownList.RemoveCurrent();
begin
   if(not ExternalSource) then begin
      if(CurrentItem >= 0) then
         Items.Remove(CurrentItem);
   end;
end;

procedure wdgTDropDownList.Render();
var
   r: oxTRect;
   f: oxTFont;
   dropWidth: loopint;
   pSkin: uiTSkin;

begin
   inherited Render;

   pSkin := GetSkinObject();

   {draw surface}
   SetColor(pSkin.Colors.InputSurface);
   uiDraw.Box(RPosition, Dimensions);

   {draw rectangle}
   if(wdgpENABLED in Properties) then begin
      if(not IsSelected()) and (not Hovering()) then
         SetColor(pSkin.Colors.Border)
      else
         SetColor(pSkin.Colors.SelectedBorder);
   end else
      SetColor(pSkin.DisabledColors.Border);

   uiDraw.Rect(RPosition, Dimensions);

   {draw drop area, if possible}
   if(DropAreaWidth > 0) and (DropAreaWidth <= Dimensions.w div 2) then begin
      dropWidth := DropAreaWidth;

      GetRelativeRect(r);
      inc(r.x, Dimensions.w - 1 - dropWidth);
      r.w := dropWidth;

      uiDraw.Box(r);
   end else
      dropWidth := 0;

   {draw selected item}
   if(GetItemCount() > 0) and (CurrentItem > -1) then begin
      Self.GetRelativeRect(r);
      inc(r.x, PaddingLeft);
      dec(r.w, dropWidth + PaddingLeft + PaddingRight);

      f := CachedFont;
      f.Start();
         SetColorBlended(pSkin.Colors.InputText);
         f.WriteCentered(GetValue(CurrentItem), r, [oxfpCenterVertical, oxfpCenterLeft]);
      oxf.Stop();
   end;
end;

procedure wdgTDropDownList.Point(var e: appTMouseEvent; x, y: longint);
begin
   if(e.Action.IsSet(appmcRELEASED)) then
      ShowMenu();
end;

function wdgTDropDownList.GetValue(index: loopint): StdString;
begin
   Result := Items.List[index];
end;

function wdgTDropDownList.GetItemCount(): loopint;
begin
   Result := Items.n;
end;

procedure wdgTDropDownList.ShowMenu();
var
   d: oxTDimensions;
   origin: uiTWidgetWindowOrigin;

begin
   if(GetItemCount() <= 0) then
      exit;

   d := GetMenuDimensions();

   ZeroOut(origin, SizeOf(origin));
   origin.SetControl(self);
   origin.Properties := WDG_WINDOW_CREATE_BELOW;

   MenuWindow.ExternalData := self;
   MenuWindow.CreateFrom(origin, wdgDropDownListMenu.Internal, d.w, d.h);
end;

procedure wdgTDropDownList.CloseMenu();
begin
   MenuWindow.Destroy();
end;

function wdgTDropDownList.GetMenuDimensions(): oxTDimensions;
begin
   Result.w := Dimensions.w;
   Result.h := (GetItemCount() * ItemHeight) + (2 + MENU_PADDING_SIZE * 2);

   if(GetItemCount() > 1) then
      inc(Result.h, MENU_VERTICAL_SEPARATION * (GetItemCount() - 1));
end;

procedure wdgTDropDownList.DeInitialize;
begin
   inherited DeInitialize;

   MenuWindow.Destroy();
end;

procedure wdgTDropDownList.SelectedItemChanged();
begin
end;

INITIALIZATION
   wdgDropDownList.Create('drop_down_list');
   wdgDropDownList.DropAreaWidth := 16;

   wdgDropDownListMenu.Create('drop_down_list_menu');

END.
