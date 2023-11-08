{
   wdguDropDownList, drop down list
   Copyright (C) 2016. Dejan Boras

   Started On:    01.10.2016.
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
      uiuWindowTypes, uiuWidget, uiWidgets, uiuDraw, uiuWidgetWindow, uiuWindow,
      {}
      wdguList;

TYPE
   wdgTDropDownListItems = specialize TPreallocatedArrayList<string>;

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
      procedure Add(const item: string);
      {select an item by its index}
      procedure SelectItem(item: longint);
      {remove all items}
      procedure Clear();
      {remove the current item}
      procedure RemoveCurrent(); virtual;

      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;

      function GetValue(index: loopint): string;
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
         procedure FontChanged(); override;
         procedure ItemClicked(idx: loopint; button: TBitSet = appmcLEFT); override;
   end;

   { wdgTDropDownListGlobal }

   wdgTDropDownListGlobal = record
      DropAreaWidth: longint;

      class function Add(const position: oxTPoint; const dimensions: oxTDimensions): wdgTDropDownList; static;
   end;

VAR
   wdgDropDownList: wdgTDropDownListGlobal;

IMPLEMENTATION

CONST
   MENU_VERTICAL_SEPARATION   = 0;
   MENU_PADDING_SIZE          = 0;
   MENU_BORDER_SIZE           = 1;
   MENU_ITEM_HEIGHT           = 18;
   MENU_ITEM_PADDING          = 3;

VAR
   internal,
   internalMenu: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := wdgTDropDownList;
   internal.Done();
end;

procedure initializeMenuWidget();
begin
   internalMenu.Instance := wdgTDropDownListMenu;
   internalMenu.Done();
end;

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
      SetColorBlended(uiTWindow(wnd).Skin.Colors.InputText)
   else
      SetColorBlended(uiTWindow(wnd).Skin.Colors.TextInHighlight);

   ir := r;
   inc(ir.x, ItemPadding);
   dec(ir.w, ItemPadding * 2);

   oxf.GetSelected().WriteCentered(List.GetValue(index), ir, [oxfpCenterVertical]);
end;

procedure wdgTDropDownListMenu.FontChanged;
begin
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

procedure wdgTDropDownList.Add(const item: string);
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

begin
   inherited Render;

   {draw surface}
   SetColor(uiTWindow(wnd).Skin.Colors.InputSurface);
   uiDraw.Box(RPosition, Dimensions);

   {draw rectangle}
   if(wdgpENABLED in Properties) then begin
      if(not IsSelected()) and (not (wdgpHOVERING in Properties)) then
         SetColor(uiTWindow(wnd).Skin.Colors.Border)
      else
         SetColor(uiTWindow(wnd).Skin.Colors.SelectedBorder);
   end else
      SetColor(uiTWindow(wnd).Skin.DisabledColors.Border);

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
         SetColorBlended(uiTWindow(wnd).Skin.Colors.InputText);
         f.WriteCentered(GetValue(CurrentItem), r, [oxfpCenterVertical, oxfpCenterLeft]);
      oxf.Stop();
   end;
end;

procedure wdgTDropDownList.Point(var e: appTMouseEvent; x, y: longint);
begin
   if(e.Action.IsSet(appmcRELEASED)) then
      ShowMenu();
end;

function wdgTDropDownList.GetValue(index: loopint): string;
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
   MenuWindow.CreateFrom(origin, internalMenu, d.w, d.h);
end;

procedure wdgTDropDownList.CloseMenu();
begin
   MenuWindow.Destroy();
end;

function wdgTDropDownList.GetMenuDimensions(): oxTDimensions;
begin
   result.w := Dimensions.w;
   result.h := (GetItemCount() * ItemHeight) + (2 + MENU_PADDING_SIZE * 2);

   if(GetItemCount() > 1) then
      inc(result.h, MENU_VERTICAL_SEPARATION * (GetItemCount() - 1));
end;

procedure wdgTDropDownList.DeInitialize;
begin
   inherited DeInitialize;

   MenuWindow.Destroy();
end;

procedure wdgTDropDownList.SelectedItemChanged();
begin

end;

{ wdgTDropDownListGlobal }

class function wdgTDropDownListGlobal.Add(const position: oxTPoint; const dimensions: oxTDimensions): wdgTDropDownList;
begin
   result := wdgTDropDownList(uiWidget.Add(internal, position, dimensions));
end;

INITIALIZATION
   internal.Register('widget.drop_down_list', @initializeWidget);
   internalMenu.Register('widget.drop_down_list_menu', @initializeMenuWidget);

   wdgDropDownList.DropAreaWidth := 16;

END.
