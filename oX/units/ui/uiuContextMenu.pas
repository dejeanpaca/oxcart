{
   uiuContextMenu, context menu
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuContextMenu;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {app}
      appuEvents, appuActionEvents, appuKeyMappings, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuRender, oxuUI, oxuTexture, oxuResourcePool,
      {ui}
      uiuTypes, uiuWindowTypes, uiuSkinTypes, uiuSkin,
      uiuWindow, uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuControl, uiuWidgetWindow,
      uiuDraw, uiuDrawUtilities,
      {wdg}
      wdguList, wdguCheckbox;

CONST
   uiCONTEXT_MENU_MAX_LEVELS  = 16;
   uiCONTEXT_MENU_MAX_LEVEL   = uiCONTEXT_MENU_MAX_LEVELS - 1;

   uiCONTEXT_MENU_ITEM_ENABLED   = $1;
   uiCONTEXT_MENU_ITEM_EXTERNAL  = $2;
   uiCONTEXT_MENU_ITEM_CHECKED   = $4;

TYPE
   uiTContextMenuItemType = (
      uiCONTEXT_MENU_COMMAND,
      uiCONTEXT_MENU_SEPARATOR,
      uiCONTEXT_MENU_SUB,
      uiCONTEXT_MENU_CHECKBOX
   );

   uiPContextMenuItem = ^uiTContextMenuItem;

   uiTContextMenuCallback = procedure(wdg: uiTWidget; menu: TObject; item: uiPContextMenuItem);

   { uiTContextMenuItem }

   uiTContextMenuItem = record
      {caption for the item}
      Caption: StdString;
      {type of item}
      ItemType: uiTContextMenuItemType;
      {action to be executed when this item is activated}
      Action: TEventID;
      {index, used for external reference, has no meaning for the context menu itself}
      Index: loopint;
      {external data}
      ExternalData: pointer;
      {sub-context menu}
      Sub: TObject;
      {callback called when the item is activated}
      Callback: uiTContextMenuCallback;
      {simple callback called when the item is activated}
      Callbacks: uiTWidgetCallback;
      {the associated key mapping, found automatically by the associated Action}
      Key: appPKeyMapping;

      {glyph for the menu entry}
      Glyph: oxTTexture;
      GlyphColor: TColor4ub;

      {item properties}
      Properties: TBitSet;

      {set an action and fetch the associated keymap}
      procedure SetAction(newAction: longint);
      {set a glyph as external}
      procedure SetGlyph(tex: oxTTexture);
      {set this item as a checkbox}
      procedure SetChecked(checked: boolean);
      {is the checkbox checked}
      function IsChecked(): boolean;

      {enable item}
      procedure Enable(enabled: boolean = true);
      {disable item}
      procedure Disable();

      {destroy the item}
      procedure Destroy();
   end;

   uiTContextMenuItems = specialize TSimpleList<uiTContextMenuItem>;

   { uiTContextMenuWindow }

   uiTContextMenuWindow = class(uiTWidgetWindowInternal)
      public
      ContextLevel: longint;
      {The control selected before an item was chosen from the context menu,
      used to check if a callback changed selection, so we can check and not override what the callback did.}
      PreviouslySelected: uiTcontrol;

      procedure Render(); override;

      procedure OnDeactivate(); override;
      procedure DeInitialize(); override;
   end;

   uiTContextMenuWindowClass = class of uiTContextMenuWindow;

   { uiTContextMenu }
   uiTContextMenu = class
      Caption: StdString;

      Items: uiTContextMenuItems;

      ItemHeight,
      SeparatorItemHeight,
      ItemPadding,
      ItemLeftBlank,
      InsertIndex: loopint;

      RenderKeyMappings: boolean;

      Parent: uiTContextMenu;

      constructor Create(const newCaption: StdString);
      destructor Destroy(); override;

      {insert item at a specific place}
      procedure InsertAt(index: loopint);
      procedure InsertAfter(index: loopint);

      {copy over an existing item to this menu (sub menus are added by reference as external)}
      function AddItem(const existing: uiTContextMenuItem): uiPContextMenuItem;
      {add item to menu}
      function AddItem(const useCaption: StdString; action: longword = 0; callback: uiTContextMenuCallback = nil): uiPContextMenuItem;
      function AddItem(const useCaption: StdString; simpleCallback: TProcedure): uiPContextMenuItem;
      function AddItem(const useCaption: StdString; simpleCallback: TObjectProcedure): uiPContextMenuItem;
      function AddItem(const useCaption: StdString; simpleCallback: uiTWidgetCallbackRoutine): uiPContextMenuItem;
      function AddItem(const useCaption: StdString; simpleCallback: uiTWidgetObjectCallbackRoutine): uiPContextMenuItem;
      {add checkbox to the menu}
      function AddCheckbox(const useCaption: StdString; checked: boolean = false): uiPContextMenuItem;
      {add separator to menu}
      function AddSeparator(): uiPContextMenuItem;
      {add a sub menu}
      function AddSub(const useCaption: StdString): uiTContextMenu;
      {add an existing context menu}
      function AddSub(const useCaption: StdString; existing: uiTContextMenu): uiPContextMenuItem;
      {add an existing context menu}
      function AddSub(existing: uiTContextMenu): uiPContextMenuItem;

      {add everything from an existing menu}
      procedure AddFrom(menu: uiTContextMenu);

      {remove all items}
      procedure RemoveAll();

      {show this context menu from a control or a rect}
      procedure Show(const r: oxTRect; from: uiTControl);
      procedure Show(from: uiTControl);
      procedure Show(const from: uiTWidgetWindowOrigin);
      {show a specified context menu}
      class procedure Show(const from: uiTWidgetWindowOrigin; Context: uiTContextMenu; ContextLevel: longint); static;
      {get dimensions for the context menu}
      function GetDimensions(): oxTDimensions;

      {find a submenu item index by its reference}
      function FindIndexOfSub(menu: uiTContextMenu): loopint;
      {find a submenu item that has the specified context menu}
      function FindSub(menu: uiTContextMenu): uiPContextMenuItem;
      {find an item index by the associated action, returns -1 if nothing found}
      function FindIndexByAction(action: TEventID): loopint;
      {find an item by the associated action}
      function FindByAction(action: TEventID): uiPContextMenuItem;

      {enable this context menu in its parent}
      procedure Enable(enabled: boolean = true);
      {disable this context menu in its parent}
      procedure Disable();

      private
         function Add(const useCaption: StdString): uiPContextMenuItem;
   end;

   { uiTContextMenuGlobal }

   uiTContextMenuGlobal = record
      ItemHeight,
      SeparatorItemHeight,
      ItemPadding,
      ItemLeftBlank: longint;
      BackgroundColor,
      BorderColor: TColor4ub;

      {should key mappings be rendered}
      RenderKeyMappings,
      RenderBorder: boolean;

      Windows: array[0..uiCONTEXT_MENU_MAX_LEVEL] of uiTWidgetWindow;
      {a control or window owning the context menu, will refocus back to the owner after closing the context menu}
      Owner: uiTControl;

      Instance: uiTContextMenuWindowClass;
      LastWindow: uiTContextMenuWindow;

      procedure ClearOwner(potentialOwner: uiTControl);

      procedure Destroy();
      procedure DestroySub(fromLevel: longint);

      function GetBorderSize(): loopint;
   end;

VAR
   uiContextMenu: uiTContextMenuGlobal;

IMPLEMENTATION

CONST
   VERTICAL_SEPARATION = 0;
   GLYPH_SIZE_RATIO = 0.85;
   PADDING_SIZE = 0;
   {border size when there is a border rendererd (for now always 1px)}
   BORDER_SIZE_DEFAULT = 2;
   {border size when there is no border rendered (but still want some space around)}
   BORDER_SIZE_NONE = 0;
   ITEM_HEIGHT = 20;
   SEPARATOR_ITEM_HEIGHT = 6;
   ITEM_PADDING = 3;
   ITEM_LEFT_BLANK = 28;

TYPE
   { wdgTContextMenu }

   wdgTContextMenu = class(wdgTStringListBase)
      RenderKeyMapping,
      {determines if glyphs should render}
      RenderGlyphs: boolean;

      ItemLeftBlank,
      SeparatorItemHeight,
      MaxKeymapLength: loopint;

      constructor Create(); override;
      procedure Initialize(); override;

      function GetItemCount(): loopint; override;
      function GetItemHeight(index: loopint): loopint; override;
      function ShouldHighlight(idx: loopint): boolean; override;
      function IsEnabled(idx: loopint): boolean; override;
      function IsNavigable(index: loopint): boolean; override;

      procedure Render(); override;

      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure UpdateItemHeight(); override;

      destructor Destroy(); override;

      protected
         menu: uiTContextMenu;

         procedure FontChanged(); override;

         procedure ItemClicked(idx: loopint; button: TBitSet = appmcLEFT); override;
   end;

VAR
   internalWidget: uiTWidgetClass;

{ uiTContextMenuItem }

procedure uiTContextMenuItem.SetAction(newAction: longint);
begin
   Action := newAction;

   if(newAction <> 0) then
      Key := appKeyMappings.Find(newAction)
   else
      Key := nil;
end;

procedure uiTContextMenuItem.SetGlyph(tex: oxTTexture);
begin
   if(tex <> nil) then begin
      Glyph := tex;
      Glyph.MarkUsed();
   end;
end;

procedure uiTContextMenuItem.SetChecked(checked: boolean);
begin
   Properties.Prop(uiCONTEXT_MENU_ITEM_CHECKED, checked);
end;

function uiTContextMenuItem.IsChecked(): boolean;
begin
   Result := Properties.IsSet(uiCONTEXT_MENU_ITEM_CHECKED);
end;

procedure uiTContextMenuItem.Enable(enabled: boolean);
begin
   if(enabled) then
      Properties.Prop(uiCONTEXT_MENU_ITEM_ENABLED)
   else
      Properties.Clear(uiCONTEXT_MENU_ITEM_ENABLED);
end;

procedure uiTContextMenuItem.Disable();
begin
   Properties.Clear(uiCONTEXT_MENU_ITEM_ENABLED);
end;

procedure uiTContextMenuItem.Destroy();
begin
   oxResource.Destroy(Glyph);

   if(Sub <> nil) and (not Properties.IsSet(uiCONTEXT_MENU_ITEM_EXTERNAL)) then
      FreeObject(Sub);
end;

{ uiTContextMenuGlobal }

procedure uiTContextMenuGlobal.ClearOwner(potentialOwner: uiTControl);
begin
   if(Owner = potentialOwner) then
      Owner := nil;
end;

procedure uiTContextMenuGlobal.Destroy;
var
   i: longint;

begin
   for i := 0 to uiCONTEXT_MENU_MAX_LEVEL do begin
      if(Windows[i].wnd <> nil) then
         Windows[i].Destroy()
      else
         Break;
   end;
end;

procedure uiTContextMenuGlobal.DestroySub(fromLevel: longint);
begin
   if(fromLevel < uiCONTEXT_MENU_MAX_LEVEL) then
      Windows[fromLevel + 1].Destroy();
end;

function uiTContextMenuGlobal.GetBorderSize: loopint;
begin
   if(RenderBorder) then
      Result := BORDER_SIZE_DEFAULT
   else
      Result := BORDER_SIZE_NONE;
end;

{ uiTContextMenuWindow }

procedure uiTContextMenuWindow.Render();
begin
   inherited Render;

   SetColor(uiContextMenu.BorderColor);
   uiDraw.Rect(RPosition, Dimensions);
end;

procedure uiTContextMenuWindow.OnDeactivate();
begin
   if(oxui.Select.GetSelectedWnd().ClassType <> uiTContextMenuWindow) then
      uiContextMenu.Destroy()
end;

procedure uiTContextMenuWindow.DeInitialize();
var
   owner: uiTControl;

begin
   uiContextMenu.DestroySub(ContextLevel);

   if(ContextLevel = 0) then begin
      {only reselect owner if selection hasn't changed when an item was clicked on (or context menu just canceled)}
      If((PreviouslySelected = nil) or (PreviouslySelected = oxui.Select.Selected)) and (uiContextMenu.Owner <> nil) then begin
         owner := uiContextMenu.Owner;
         uiContextMenu.Owner := nil;

         if(owner.ControlType = uiCONTROL_WINDOW) then
            uiTWindow(owner).Select()
         else
            uiTWidget(owner).Select();
      end;

      {clear owner in any case if closing the context menu}
      uiContextMenu.Owner := nil;
   end;
end;

{ wdgTContextMenu }

constructor wdgTContextMenu.Create();
begin
   inherited;

   Clickable := true;
   HighlightHovered := true;
   SelectBorder := false;
   AllowLoopingNavigation := true;

   VerticalSeparation := VERTICAL_SEPARATION;
   SetPadding(PADDING_SIZE);

   SetBorder(uiContextMenu.GetBorderSize());

   ItemPadding := ITEM_PADDING;
   ItemLeftBlank := ITEM_LEFT_BLANK;

   Transparent := true;

   ConstantHeight := false;
   SeparatorItemHeight := SEPARATOR_ITEM_HEIGHT;
end;

function wdgTContextMenu.GetItemCount(): loopint;
begin
   if(menu <> nil) then
      Result := menu.Items.n
   else
      Result := 0;
end;

function wdgTContextMenu.GetItemHeight(index: loopint): loopint;
begin
   if(menu.Items.list[index].ItemType <> uiCONTEXT_MENU_SEPARATOR) then
      Result := ItemHeight
   else
      Result := SeparatorItemHeight;
end;

function wdgTContextMenu.ShouldHighlight(idx: loopint): boolean;
begin
   Result := menu.Items.list[idx].ItemType <> uiCONTEXT_MENU_SEPARATOR;
end;

function wdgTContextMenu.IsEnabled(idx: loopint): boolean;
begin
   if(menu.Items.List[idx].ItemType <> uiCONTEXT_MENU_SUB) or (uiTContextMenu(menu.Items.List[idx].Sub).Items.n > 0) then
      Result := menu.Items.list[idx].Properties.IsSet(uiCONTEXT_MENU_ITEM_ENABLED)
   else
      Result := false;
end;

function wdgTContextMenu.IsNavigable(index: loopint): boolean;
begin
   Result := menu.Items.List[index].ItemType <> uiCONTEXT_MENU_SEPARATOR;
end;

procedure wdgTContextMenu.Render();
var
   i: loopint;

begin
   RenderGlyphs := false;

   for i := 0 to (menu.Items.n - 1) do begin
      if(menu.Items.List[i].Glyph <> nil) or (menu.Items.List[i].ItemType = uiCONTEXT_MENU_CHECKBOX) then begin
         RenderGlyphs := true;
         break;
      end;
   end;

   inherited Render;
end;

procedure wdgTContextMenu.RenderItem(index: loopint; r: oxTRect);
var
   item: uiPContextMenuItem;
   f: oxTFont;
   ir: oxTRect;
   clr: TColor4ub;
   keyMapping: StdString;
   size: longint;
   enabled: boolean;
   pSkin: uiTSkin;

procedure DetermineColor();
var
   highlight: boolean;

begin
   highlight := not ((HighlightedItem <> index) or (item^.ItemType = uiCONTEXT_MENU_SEPARATOR));

   {if sub menu has no items, rneder it as disabled}
   if(item^.ItemType = uiCONTEXT_MENU_SUB) and (uiTContextMenu(item^.Sub).Items.n = 0) then
      enabled := false;

   if(enabled) then begin
      if(not highlight) then
         clr := pSkin.Colors.Text
      else
         clr := pSkin.Colors.TextInHighlight;
   end else begin
      if(not highlight) then
         clr := pSkin.DisabledColors.Text
      else
         clr := pSkin.DisabledColors.TextInHighlight;
   end;
end;

procedure RenderCaption();
begin
   SetColorBlended(clr);

   ir := r;
   inc(ir.x, ItemPadding + ItemLeftBlank);
   dec(ir.w, ItemPadding * 2);

   f.WriteCentered(item^.Caption, ir, [oxfpCenterVertical]);
end;

procedure RenderKeyMap();
begin
   {render key mapping}
   if(RenderKeyMapping) and (item^.Key <> nil) and (MaxKeymapLength > 0) then begin
      keyMapping := item^.Key^.ToString();
      SetColorBlended(clr.Darken(0.25));

      ir.x := r.x + Dimensions.w - 5 - f.GetLength(keyMapping);

      f.WriteCentered(keyMapping, ir, [oxfpCenterVertical]);

      SetColorBlended(pSkin.Colors.Text);
   end;
end;

procedure PrepareGlyph();
begin
   size := round(GLYPH_SIZE_RATIO * r.h);

   if(enabled) then
      uiDraw.Color(item^.GlyphColor)
   else
      uiDraw.Color(item^.GlyphColor.Darken(0.5));
end;

procedure RenderCheckbox();
begin
   PrepareGlyph();

   ir := r;
   inc(ir.x, 2);
   dec(ir.y, (r.h - size) div 2);
   ir.w := size;
   ir.h := size;

   wdgTCheckbox.RenderCheckbox(Self, menu.Items.List[index].Properties.IsSet(uiCONTEXT_MENU_ITEM_CHECKED), enabled, false, ir);
end;

begin
   item := @menu.Items.List[index];
   enabled := item^.Properties.IsSet(uiCONTEXT_MENU_ITEM_ENABLED);
   clr := cWhite4ub;
   pSkin := uiTSkin(uiTWindow(wnd).Skin);

   if(item^.Glyph <> nil) then begin
      PrepareGlyph();

      uiDrawUtilities.Glyph(r.x + 2, r.y - 1, size, size, item^.Glyph);
      uiDraw.ClearTexture();
   end;

   if(item^.ItemType = uiCONTEXT_MENU_COMMAND) then begin
      f := CachedFont;
      f.Start();
      DetermineColor();
      RenderCaption();
      RenderKeyMap();
      oxf.Stop();
   end else if(item^.ItemType = uiCONTEXT_MENU_CHECKBOX) then begin
      RenderCheckbox();
      f := CachedFont;
      f.Start();
      DetermineColor();
      RenderCaption();
      RenderKeyMap();
      oxf.Stop();
   end else if(item^.ItemType = uiCONTEXT_MENU_SUB) then begin
      f := CachedFont;
      f.Start();

      DetermineColor();
      RenderCaption();
      SetColorBlended(clr.Darken(0.25));

      ir.x := r.x + Dimensions.w - (5 + f.GetLength('>'));

      f.WriteCentered('>', ir, [oxfpCenterVertical]);
      SetColorBlended(pSkin.Colors.Text);
      oxf.Stop();
   end else if (item^.ItemType = uiCONTEXT_MENU_SEPARATOR) then begin
      uiDraw.ClearTexture();
      uiDrawUtilities.HorizontalDivisorSunken(wnd, r.x + 1, r.y - (r.h div 2), r.x + r.w - 1, pSkin.Colors.Surface);
   end;
end;

procedure wdgTContextMenu.UpdateItemHeight();
begin
   ConstantHeight := false;
end;

destructor wdgTContextMenu.Destroy();
begin
   inherited Destroy;
end;

procedure wdgTContextMenu.FontChanged();
var
   f: oxTFont;
   len,
   i: loopint;

begin
   inherited;

   f := CachedFont;

   MaxKeymapLength := 0;

   if(menu <> nil) then begin
      for i := 0 to (menu.Items.n - 1) do begin
         if(menu.Items.List[i].Key <> nil) then begin
            len := f.GetLength(menu.Items.List[i].Key^.Key.ToString());

            if(len > MaxKeymapLength) then
               MaxKeymapLength := len;
         end;
      end;
   end;
end;

procedure wdgTContextMenu.ItemClicked(idx: loopint; button: TBitSet);
var
   item: uiPContextMenuItem;
   r: oxTRect;
   origin: uiTWidgetWindowOrigin;

begin
   if(button <> appmcLEFT) then
      exit;

   item := @menu.Items.list[idx];

   if(not item^.Properties.IsSet(uiCONTEXT_MENU_ITEM_ENABLED)) then
      exit;

   uiTContextMenuWindow(wnd).PreviouslySelected := oxui.Select.Selected;

   if(item^.ItemType = uiCONTEXT_MENU_SUB) then begin
      if(uiTContextMenu(item^.Sub).Items.n > 0) then begin
         r.Assign(RPosition, Dimensions);
         r.y := r.y - HighlightedItemOffset;

         ZeroOut(origin, SizeOf(origin));
         origin.SetRect(r, Self);
         origin.Properties := WDG_WINDOW_CREATE_RIGHT;

         menu.Show(origin, uiTContextMenu(item^.Sub), uiTContextMenuWindow(wnd).ContextLevel + 1);
      end;
   end else if(item^.ItemType <> uiCONTEXT_MENU_SEPARATOR) then begin
      if(item^.ItemType <> uiCONTEXT_MENU_CHECKBOX) then
         uiContextMenu.Destroy()
      else
         item^.SetChecked(not item^.IsChecked());

      if(item^.Action <> 0) then
         appActionEvents.Queue(item^.Action);

      if(item^.Callback <> nil) then
         item^.Callback(Self, menu, item);

      item^.Callbacks.Call(Self);
   end;
end;

procedure wdgTContextMenu.Initialize();
begin
   inherited Initialize;

   {get the menu reference when the widget is created}
   menu := uiTContextMenu(uiTWidgetWindowInternal(wnd).ExternalData);
   RenderKeyMapping := menu.RenderKeyMappings;

   SetItemHeight(menu.ItemHeight);
   ItemPadding := menu.ItemPadding;
   ItemLeftBlank := menu.ItemLeftBlank;
   SeparatorItemHeight := menu.SeparatorItemHeight;

   uiTWindow(Parent).SetBackgroundType(uiwBACKGROUND_SOLID);
   uiTWindow(Parent).Background.Color := uiContextMenu.BackgroundColor;

   ItemsChanged();

   {font hasn't really changed, but we want to recalculate MaxKeymapLength now that we have the menu set}
   FontChanged();
end;

{ uiTContextMenu }

constructor uiTContextMenu.Create(const newCaption: StdString);
begin
   Caption := newCaption;

   ItemHeight := uiContextMenu.ItemHeight;
   ItemPadding := uiContextMenu.ItemPadding;
   ItemLeftBlank := uiContextMenu.ItemLeftBlank;
   SeparatorItemHeight := uiContextMenu.SeparatorItemHeight;

   InsertIndex := -1;

   RenderKeyMappings := uiContextMenu.RenderKeyMappings;
   Items.InitializeValues(Items);
end;

destructor uiTContextMenu.Destroy();
var
   i: longint;

begin
   inherited Destroy;

   for i := 0 to (Items.n - 1) do begin
      if(Items.list[i].Sub <> nil) then
         Items.List[i].Destroy();
   end;

   Items.Dispose();
end;

procedure uiTContextMenu.InsertAt(index: loopint);
begin
   if(index >= 0) and (index < Items.n) then begin
      Items.InsertRange(index, 1);
      ZeroOut(Items.List[index], SizeOf(Items.List[index]));

      InsertIndex := index;
   end else
      InsertIndex := -1;
end;

procedure uiTContextMenu.InsertAfter(index: loopint);
begin
   if(index >= 0) and (index < Items.n) then begin
      index := index + 1;

      Items.InsertRange(index, 1);
      ZeroOut(Items.List[index], SizeOf(Items.List[index]));

      InsertIndex := index;
   end;
end;

function uiTContextMenu.AddItem(const existing: uiTContextMenuItem): uiPContextMenuItem;
begin
   Result := Add('');
   Result^ := existing;

   {if we're adding an external sub-menu, then mark it so we do not dispose of it}
   if(existing.Sub <> nil) then
      Result^.Properties.Prop(uiCONTEXT_MENU_ITEM_EXTERNAL);
end;

function uiTContextMenu.AddItem(const useCaption: StdString; action: longword; callback: uiTContextMenuCallback): uiPContextMenuItem;
begin
   Result := Add(useCaption);

   Result^.SetAction(action);
   Result^.Callback := callback;
end;

function uiTContextMenu.AddItem(const useCaption: StdString; simpleCallback: TProcedure): uiPContextMenuItem;
begin
   Result := AddItem(useCaption, 0, nil);
   Result^.Callbacks.Use(simpleCallback);
end;

function uiTContextMenu.AddItem(const useCaption: StdString; simpleCallback: TObjectProcedure): uiPContextMenuItem;
begin
   Result := AddItem(useCaption, 0, nil);
   Result^.Callbacks.Use(simpleCallback);
end;

function uiTContextMenu.AddItem(const useCaption: StdString; simpleCallback: uiTWidgetCallbackRoutine): uiPContextMenuItem;
begin
   Result := AddItem(useCaption, 0, nil);
   Result^.Callbacks.Use(simpleCallback);
end;

function uiTContextMenu.AddItem(const useCaption: StdString; simpleCallback: uiTWidgetObjectCallbackRoutine): uiPContextMenuItem;
begin
   Result := AddItem(useCaption, 0, nil);
   Result^.Callbacks.Use(simpleCallback);
end;

function uiTContextMenu.AddCheckbox(const useCaption: StdString; checked: boolean): uiPContextMenuItem;
var
   item: uiPContextMenuItem;

begin
   item := Add(useCaption);
   item^.ItemType := uiCONTEXT_MENU_CHECKBOX;
   item^.SetChecked(checked);

   Result := item;
end;

function uiTContextMenu.AddSeparator(): uiPContextMenuItem;
var
   item: uiPContextMenuItem;

begin
   item := Add('');
   item^.ItemType := uiCONTEXT_MENU_SEPARATOR;

   Result := item;
end;

function uiTContextMenu.AddSub(const useCaption: StdString): uiTContextMenu;
var
   item: uiPContextMenuItem;

begin
   item := Add(useCaption);
   item^.ItemType := uiCONTEXT_MENU_SUB;
   item^.Sub := uiTContextMenu.Create(useCaption);
   uiTContextMenu(item^.Sub).Parent := Self;

   Result := uiTContextMenu(item^.Sub);
end;

function uiTContextMenu.AddSub(const useCaption: StdString; existing: uiTContextMenu): uiPContextMenuItem;
var
   item: uiPContextMenuItem;

begin
   item := Add(useCaption);
   item^.Sub := existing;
   item^.ItemType := uiCONTEXT_MENU_SUB;

   if(useCaption = '') then
      item^.Caption := existing.Caption;

   item^.Properties.Prop(uiCONTEXT_MENU_ITEM_EXTERNAL);

   if(existing.Parent <> nil) then
      existing.Parent := Self;

   Result := item;
end;

function uiTContextMenu.AddSub(existing: uiTContextMenu): uiPContextMenuItem;
begin
   Result := AddSub('', existing);
end;

procedure uiTContextMenu.AddFrom(menu: uiTContextMenu);
var
   i: loopint;

begin
   for i := 0 to menu.Items.n - 1 do begin
      AddItem(menu.Items.List[i]);
   end;
end;

procedure uiTContextMenu.RemoveAll();
begin
   Items.Dispose();
end;

procedure uiTContextMenu.Show(const r: oxTRect; from: uiTControl);
var
   origin: uiTWidgetWindowOrigin;

begin
   ZeroOut(origin, SizeOf(origin));
   origin.SetRect(r, from);

   Show(origin, Self, 0);
end;

procedure uiTContextMenu.Show(from: uiTControl);
var
   origin: uiTWidgetWindowOrigin;

begin
   ZeroOut(origin, SizeOf(origin));
   origin.SetControl(from);

   Show(origin, Self, 0);
end;

procedure uiTContextMenu.Show(const from: uiTWidgetWindowOrigin);
begin
   Show(from, Self, 0);
end;

class procedure uiTContextMenu.Show(const from: uiTWidgetWindowOrigin; Context: uiTContextMenu; ContextLevel: longint); static;
var
   d: oxTDimensions;

begin
   if(Context <> nil) and (Context.Items.n > 0) and (ContextLevel < uiCONTEXT_MENU_MAX_LEVELS) then begin
      d := Context.GetDimensions();

      uiContextMenu.Windows[ContextLevel].Instance := uiContextMenu.Instance;

      uiContextMenu.Windows[ContextLevel].ExternalData := Context;
      uiContextMenu.Windows[ContextLevel].CreateFrom(from, internalWidget, d.w, d.h);

      uiContextMenu.Windows[ContextLevel].Instance := uiTContextMenuWindow;
      uiContextMenu.Instance := uiTContextMenuWindow;

      uiContextMenu.LastWindow := uiTContextMenuWindow(uiContextMenu.Windows[ContextLevel].wnd);

      uiTContextMenuWindow(uiContextMenu.Windows[ContextLevel].wnd).ContextLevel := ContextLevel;
      uiTContextMenuWindow(uiContextMenu.Windows[ContextLevel].wnd).SetTitle('Context ' + sf(ContextLevel));
   end else
      uiContextMenu.LastWindow := nil;
end;

function uiTContextMenu.GetDimensions(): oxTDimensions;
var
   i: loopint;
   itemHeights: loopint = 0;

begin
   for i := 0 to (Items.n - 1) do begin
      if(Items.list[i].ItemType <> uiCONTEXT_MENU_SEPARATOR) then
         inc(itemHeights, ItemHeight)
      else
         inc(itemHeights, SeparatorItemHeight);
   end;

   Result.w := 160 + (ItemPadding * 2) + (uiContextMenu.GetBorderSize() * 2{border size});
   if(RenderKeyMappings) then
      inc(Result.w, 120);

   Result.h := itemHeights + (uiContextMenu.GetBorderSize() * 2);

   if(Items.n > 1) then
      inc(Result.h, VERTICAL_SEPARATION * (Items.n - 1));
end;

function uiTContextMenu.FindIndexOfSub(menu: uiTContextMenu): loopint;
var
   i: loopint;

begin
   for i := 0 to (Items.n - 1) do begin
      if(Items.List[i].Sub = menu) then
         exit(i);
   end;

   Result := -1;
end;

function uiTContextMenu.FindSub(menu: uiTContextMenu): uiPContextMenuItem;
var
   i: loopint;

begin
   for i := 0 to (Items.n - 1) do begin
      if(Items.List[i].Sub = menu) then
         exit(@Items.list[i]);
   end;

   Result := nil;
end;

function uiTContextMenu.FindIndexByAction(action: TEventID): loopint;
var
   i: loopint;

begin
   for i := 0 to (Items.n - 1) do begin
      if(Items.List[i].Action = action) then
         exit(i);
   end;

   Result := -1;
end;

function uiTContextMenu.FindByAction(action: TEventID): uiPContextMenuItem;
var
   i: loopint;

begin
   for i := 0 to (Items.n - 1) do begin
      if(Items.List[i].Action = action) then
         exit(@Items.list[i]);
   end;

   Result := nil;
end;

procedure uiTContextMenu.Enable(enabled: boolean);
var
   sub: uiPContextMenuItem;

begin
   if(Parent <> nil) then begin
      sub := Parent.FindSub(Self);

      if(enabled) then
         sub^.Properties.Prop(uiCONTEXT_MENU_ITEM_ENABLED)
      else
         sub^.Properties.Clear(uiCONTEXT_MENU_ITEM_ENABLED);
   end;
end;

procedure uiTContextMenu.Disable();
var
   sub: uiPContextMenuItem;

begin
   if(Parent <> nil) then begin
      sub := Parent.FindSub(Self);
      sub^.Properties.ClearBit(uiCONTEXT_MENU_ITEM_ENABLED);
   end;
end;

function uiTContextMenu.Add(const useCaption: StdString): uiPContextMenuItem;
var
   item: uiTContextMenuItem;

begin
   ZeroPtr(@item, SizeOf(item));

   item.Caption := useCaption;
   item.Properties := uiCONTEXT_MENU_ITEM_ENABLED;
   item.GlyphColor := uiSkin.StandardSkin.Colors.Text;

   if(InsertIndex < 0) then begin
      Items.Add(item);

      Result := @Items.List[Items.n - 1];
   end else begin
      Items.List[InsertIndex] := item;

      Result := @Items.List[InsertIndex];
   end;

   InsertIndex := -1;
end;

procedure initializeWidget();
begin
   internalWidget.Instance := wdgTContextMenu;
   internalWidget.Done();
end;

INITIALIZATION
   uiContextMenu.Instance := uiTContextMenuWindow;
   uiContextMenu.ItemHeight := ITEM_HEIGHT;
   uiContextMenu.SeparatorItemHeight := SEPARATOR_ITEM_HEIGHT;
   uiContextMenu.ItemPadding := ITEM_PADDING;
   uiContextMenu.ItemLeftBlank := ITEM_LEFT_BLANK;
   uiContextMenu.RenderKeyMappings := true;
   uiContextMenu.RenderBorder := true;

   uiContextMenu.BackgroundColor.Assign(48, 48, 48, 244);
   uiContextMenu.BorderColor.Assign(8, 8, 8, 255);

   internalWidget.Register('widget.context_menu', @initializeWidget);
END.
