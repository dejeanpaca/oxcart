{
   wdguList, list widget
   Copyright (C) 2016. Dejan Boras

   Started On:    05.07.2016.
}

{$INCLUDE oxdefines.inc}
UNIT wdguList;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuTexture,
      {ui}
      uiuTypes, uiuWindowTypes, uiuWidget, uiWidgets, uiuSkinTypes,
      uiuDraw, uiuWidgetRender, uiuWindow, uiuSettings,
      uiuPointer,
      wdguBase, wdguScrollbar;

TYPE
   wdgTListGlyph = record
      Glyph: oxTTexture;
      Color: TColor4ub;
   end;

   { wdgTList }

   wdgTList = class(uiTWidget)
   public
      {does the list use a constant height for its items}
      ConstantHeight,
      {is an item selectable}
      Selectable,
      {are multiple items selectable (requires Selectable aswell)}
      SelectableMultiple,
      {can items be clicked on}
      Clickable,
      {highlight the hovered over item}
      HighlightHovered,
      {use odd colored surface for odd numbered items}
      OddColored,
      {highlight the border the widget is selected}
      SelectBorder,
      {do not render the surface}
      Transparent,
      {should the horizontal scrollbar be permanently shown}
      PermanentHorizontalScrollbar,
      {does the list include a glyph in it's items}
      HasGlyphs,
      {navigation also means selecting}
      NavigationIsSelection,
      {allows looping navigation}
      AllowLoopingNavigation: boolean;

      {constant item height}
      ItemHeight,
      {item padding, used by inherited widgets}
      ItemPadding,
      {currently selected item}
      SelectedItem,
      SelectedItemX,
      SelectedItemOffset,
      {currently highlighted item}
      HighlightedItem,
      {offset within the widget space of the highlighted item}
      HighlightedItemOffset,
      {horizontal position of highlighted item}
      HighlightedItemX,
      {width position of highlighted item (if 0 means whole area)}
      ItemHighlightWidth,
      {last item under pointer}
      LastItemUnderPointer,
      {item offset, the first visible item}
      ItemOffset,
      {total item count}
      ItemCount: loopint;

      {header height}
      HeaderHeight,
      {footer height (horizontal scrollbar)}
      FooterHeight: loopint;
      {font padding if any for item height}
      FontPadding: loopint;

      {maximum size (height) of all items}
      Max,
      {Maximum width of all items}
      MaxWidth: loopint;

      {stored offsets for all items}
      ItemOffsets: TPreallocatedInt64ArrayList;

      {the last position where a pointer event occured}
      LastPointerPosition: oxTPoint;

      constructor Create(); override;

      procedure Initialize(); override;

      {set a constant height for all items}
      procedure SetConstantHeight(height: loopint);

      {get the height of a specified item}
      function GetItemHeight({%H-}index: loopint): loopint; virtual;
      {get the width of a specified item}
      function GetItemWidth({%H-}index: loopint): loopint; virtual;
      {get the height of all items}
      function GetAllHeight(): loopint; virtual;
      {get the width of all items}
      function GetMaxWidth(): loopint; virtual;
      {get item count}
      function GetItemCount(): loopint; virtual;
      {get the offset of the specified item}
      function GetItemOffset(index: loopint): loopint;
      {get the visible vertical space}
      function GetVisibleVerticalSpace(): loopint;
      {get the visible vertical space}
      function GetVisibleHorizontalSpace(): loopint;
      {determines whether or not an item should be highlighted}
      function ShouldHighlight({%H-}index: loopint): boolean; virtual;
      {determines whether or not the item is enabled}
      function IsEnabled({%H-}index: loopint): boolean; virtual;
      {determines whether or not the item is navigable to}
      function IsNavigable({%H-}index: loopint): boolean; virtual;
      {determines whether or not the item is selectable}
      function IsSelectable({%H-}index: loopint): boolean; virtual;

      {get the glyph for the specified item}
      function GetGlyph({%H-}index: loopint): wdgTListGlyph; virtual;

      {get the vertical offset of the specified item}
      function GetItemVerticalOffset(index: loopint): loopint;

      procedure RenderStart(); virtual;
      procedure RenderDone(); virtual;
      procedure RenderItem({%H-}index: loopint; {%H-}r: oxTRect); virtual;

      procedure Render(); override;
      function Key(var k: appTKeyEvent): boolean; override;
      procedure Point(var e: appTMouseEvent; x, y: longint); override;
      procedure Hover(x, y: longint; what: uiTHoverEvent); override;

      {set text color}
      procedure SetTextColor();

      {select the next navigable item from the specified (does nothing if there isn't any)}
      procedure SelectNavigableItemFrom(start: loopint);
      {select the next navigable item down from the specified (does nothing if there isn't any)}
      procedure SelectNavigableItemDownFrom(start: loopint);

      {move to the next item}
      procedure Next();
      {move to the previous item}
      procedure Previous();

      {go to the start item}
      procedure StartItem();
      {go to the end item}
      procedure EndItem();
      {perform the click action on the currently selected item}
      procedure ClickItem();

      {remove all items}
      procedure RemoveAll(); virtual;

      {select item with the specified index}
      procedure NavigateToItem(index: loopint);

      protected
         {current offset position}
         Offset,
         {horizontal offset}
         HorizontalOffset,
         {currently visible offset}
         VisibleOffset,
         {content y end coordinate}
         ContentYEnd,
         {content y start coordinate}
         ContentY: loopint;
         {scrollbar widget}
         scrollWidget,
         horizontalScrollWidget: wdgTScrollbar;

         {adjust offset and visible offset}
         procedure AdjustOffset();
         {adjust horizontal offset}
         procedure AdjustHorizontaloffset();
         {when padding or border height changes, update the unusable size (dimensions) numbers}
         procedure SetupUnusableSize(); override;

         {determines whether all items can fit in the visible space}
         function CanFit(): boolean;
         {determines whether all items can fit in the horizontally visible space}
         function CanFitHorizontally(): boolean;

         {update the scrollbar widget}
         procedure UpdateScrollbar();
         {adjust the scrollbar position}
         procedure AdjustScrollbar();
         {scrollbar has moved}
         procedure ScrollbarMoved(p: single);
         {horizontal scrollbar has moved}
         procedure HorizontalScrollbarMoved(p: single);
         {number of items has changed}
         procedure ItemsChanged();
         {set new item height}
         procedure SetItemHeight(height: loopint);

         {called when the item height should be updated}
         procedure UpdateItemHeight(); virtual;

         procedure PositionChanged; override;
         procedure SizeChanged(); override;
         procedure RPositionChanged; override;
         procedure Recalculate();

         {called when an item is clicked upon (but not in selection mode)}
         procedure ItemClicked({%H-}index: loopint; {%H-}button: TBitSet = appmcLEFT); virtual;
         {called when no item is selected}
         procedure ItemCleared(); virtual;
         {called when an item is double clicked upon (but not in selection mode)}
         procedure ItemDoubleClicked({%H-}index: loopint; {%H-}button: TBitSet); virtual;
         {called when an item is selected}
         procedure ItemSelected({%H-}index: loopint); virtual;
         {called when an item is unselected}
         procedure ItemUnselected({%H-}index: loopint); virtual;
         {called when an item is navigated to}
         procedure ItemNavigated({%H-}index: loopint); virtual;

         {called when an item starts hovering over}
         procedure OnHover({%H-}index: loopint); virtual;

         {internal, called to update navigation and parameters before events}
         procedure NavigationMoved(); virtual;
         {internal, called to update navigation and parameters before events}
         procedure InternalItemsChanged(); virtual;

         {returns index of the item under the pointer, or -1 if nothing}
         function GetItemUnderPointer({%H-}x, y: loopint; out offs: loopint): loopint; virtual;

         {set the offset to the specified items}
         procedure SetOffsetToItem(item: loopint);
         {scrolls horizontally by the specified amount}
         procedure ScrollHorizontally(howMuch: loopint);

         {get top y coordinate for content}
         function GetContentY(): loopint;
         function GetContentYEnd(): loopint;
         {get total header height, including border}
         function GetTotalHeader(): loopint;

         {scissor a rectangle to fit within the widget visible area}
         function GetScissoredRect(var r: oxTRect): boolean;
         {apply scissor rectangle within the bounds of the widget, returns false if out of bottom bounds (assumes top to bottom rendering)}
         function ScissorRect(var r: oxTRect): boolean;
   end;

   { wdgTStringListBase }

   wdgTStringListBase = class(wdgTList)
      public
         VerticalSeparation: single;

      constructor Create(); override;

      procedure RenderStart(); override;
      procedure RenderDone(); override;

      procedure SetFontColor(index: loopint);

      procedure UpdateItemHeight(); override;

      protected
         procedure FontChanged(); override;
      end;

   { wdgTStringList }

   wdgTStringList = class(wdgTStringListBase)
      public
         Items: TPreallocatedStringArrayList;

      constructor Create(); override;

      function GetItemCount(): loopint; override;

      function Assign(items_list: TAnsiStringArray): wdgTStringList;
      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure Add(const item: StdString);
      procedure Remove(index: loopint);

      function GetValue(index: loopint): StdString; virtual;

      function GetItemWidth(index: loopint): loopint; override;
      function GetMaxWidth: loopint; override;

      function Load(): wdgTStringList;

      procedure RemoveAll(); override;

      destructor Destroy(); override;

      protected
         ItemsExternal: boolean;

         procedure RemoveItems(updateWidget: boolean = true);
   end;

   { wdgTStringItemList }

   wdgTStringItemList = class(wdgTStringList)
      constructor Create(); override;
   end;

   { wdgTListGlobal }

   wdgTListGlobal = class(specialize wdgTBase<wdgTList>)
      Internal: uiTWidgetClass; static;
   end;

   { wdgTStringListGlobal }

   wdgTStringListGlobal = class(specialize wdgTBase<wdgTStringList>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgList: wdgTListGlobal;
   wdgStringList: wdgTStringListGlobal;

IMPLEMENTATION

{ wdgTStringItemList }

constructor wdgTStringItemList.Create();
begin
   inherited Create;

   Clickable := true;
   HighlightHovered := true;
   Transparent := true;
end;

{ wdgTStringList }

constructor wdgTStringListBase.Create();
begin
   inherited;

   VerticalSeparation := 0.5;
end;

procedure wdgTStringListBase.RenderStart();
begin
   CachedFont.Start();

   if(Transparent) then
      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text)
   else
      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text);
end;

procedure wdgTStringListBase.RenderDone();
begin
   oxf.Stop();
end;

procedure wdgTStringListBase.SetFontColor(index: loopint);
begin
   if(HighlightHovered) then begin
      if(Transparent) then begin
         if(index <> HighlightedItem) then
            SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text)
         else
            SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.TextInHighlight);
      end else begin
         if(index <> HighlightedItem) then
            SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.InputText)
         else
            SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.TextInHighlight)
      end;
   end;
end;

procedure wdgTStringListBase.UpdateItemHeight();
var
   h: loopint;

begin
   ConstantHeight := true;
   h := CachedFont.GetHeight();

   SetItemHeight(h + round(h * VerticalSeparation));
end;


procedure wdgTStringListBase.FontChanged();
begin
   inherited FontChanged;

   UpdateItemHeight();
end;

{ wdgTStringList }

constructor wdgTStringList.Create();
begin
   inherited Create();

   Items.InitializeValues(Items);
end;

function wdgTStringList.GetItemCount(): loopint;
begin
   Result := Items.n;
end;

procedure wdgTStringList.RenderItem(index: loopint; r: oxTRect);
var
   f: oxTFont;

begin
   SetFontColor(index);
   f := oxf.GetSelected();

   f.WriteCentered(GetValue(index), r, [oxfpCenterVertical]);
end;

procedure wdgTStringList.Add(const item: StdString);
begin
   if(not ItemsExternal) then begin
      Items.Add(item);
      ItemsChanged();
   end;
end;

procedure wdgTStringList.Remove(index: loopint);
begin
   if(not ItemsExternal) and (index >= 0) and (index < Items.n) then begin
      Items.Remove(index);
      ItemsChanged();
   end;
end;

function wdgTStringList.GetValue(index: loopint): StdString;
begin
   if(Items.n > 0) then
      Result := Items[index]
   else
      Result := '';
end;

function wdgTStringList.GetItemWidth(index: loopint): loopint;
var
   f: oxTFont;

begin
   f := CachedFont;

   Result := f.GetLength(GetValue(index));
end;

function wdgTStringList.GetMaxWidth: loopint;
var
   i: loopint;
   f: oxTFont;
   maxLength,
   currentLength: loopint;

begin
   if(ItemCount > 0) then begin
      f := CachedFont;
      maxLength := 0;

      for i := 0 to (ItemCount - 1) do begin
         currentLength := f.GetLength(GetValue(i));

         if(currentLength > maxLength) then
            maxLength := currentLength;
      end;

      Result := maxLength;
   end else
      Result := 0;
end;

function wdgTStringList.Load(): wdgTStringList;
begin
   ItemsChanged();
   Result := Self;
end;

procedure wdgTStringList.RemoveAll();
begin
   Items.Dispose();
   ItemsChanged();
end;

function wdgTStringList.Assign(items_list: TAnsiStringArray): wdgTStringList;
var
   i: loopint;

begin
   RemoveItems(false);

   for i := 0 to Length(items_list) - 1 do begin
      Items.Add(items_list[i]);
   end;

   Result := Load();
end;

destructor wdgTStringList.Destroy();
begin
   inherited Destroy;

   RemoveItems();
end;

procedure wdgTStringList.RemoveItems(updateWidget: boolean = true);
begin

   if(not ItemsExternal) then
      Items.Dispose();

   if(updateWidget) and (not (wdgpDESTROY_IN_PROGRESS in Properties)) then
      ItemsChanged();
end;

constructor wdgTList.Create();
begin
   ConstantHeight := true;
   SelectBorder := true;
   HighlightedItem := -1;
   SelectedItem := -1;
   FontPadding := 0;

   PermanentHorizontalScrollbar := false;
   NavigationIsSelection := true;

   inherited;

   SetBorder(1);
   SetPadding(0, 1, 0, 1);
end;

procedure wdgTList.Initialize();
begin
   inherited Initialize;

   Recalculate();
end;

procedure wdgTList.SetConstantHeight(height: loopint);
begin
   ConstantHeight := true;
   ItemHeight := height;
end;

function wdgTList.GetItemHeight(index: loopint): loopint;
begin
   if(ConstantHeight) then
      Result := ItemHeight
   else
      Result := (CachedFont.GetHeight()) + FontPadding;
end;

function wdgTList.GetItemWidth(index: loopint): loopint;
begin
   Result := GetVisibleHorizontalSpace();
end;

procedure wdgTList.RenderItem(index: loopint; r: oxTRect);
begin
end;

function wdgTList.GetAllHeight(): loopint;
var
   i: loopint;
   sum: loopint;

begin
   if(ItemCount > 0) then begin
      if(ConstantHeight) then
         Result := loopint(ItemCount) * ItemHeight
      else begin
         sum := 0;

         for i := 0 to (ItemCount - 1) do begin
            sum := sum + GetItemHeight(i);
         end;

         Result := sum;
      end;
   end else
      Result := 0;
end;

function wdgTList.GetMaxWidth(): loopint;
var
   i: loopint;
   maxLength,
   currentLength: loopint;

begin
   if(ItemCount > 0) then begin
      maxLength := 0;

      for i := 0 to (ItemCount - 1) do begin
         currentLength := GetItemWidth(i);

         if(currentLength > maxLength) then
            maxLength := currentLength;
      end;

      Result := maxLength;
   end else
      Result := 0;
end;

function wdgTList.GetItemCount(): loopint;
begin
   Result := 0;
end;

function wdgTList.GetItemOffset(index: loopint): loopint;
var
   i,
   count: loopint;

begin
   count := ItemCount;

   if(count > 0) then begin
      if(ItemOffsets.n > index) then begin
         Result := ItemOffsets.list[index]
      end else begin
         if(ConstantHeight) then
            Result := index * ItemHeight
         else begin
            Result := 0;

            if(index < count) then
               count := index
            else
               count := count - 1;

            for i := 0 to count do begin
               inc(Result, GetItemHeight(i));
            end;
         end;
      end;
   end else
      Result := 0;
end;

function wdgTList.GetVisibleVerticalSpace(): loopint;
begin
   Result := loopint(Dimensions.h) - loopint(UnusableHeight);
end;

function wdgTList.GetVisibleHorizontalSpace(): loopint;
begin
   Result := loopint(Dimensions.w) - loopint(UnusableWidth);
end;

function wdgTList.ShouldHighlight(index: loopint): boolean;
begin
   Result := true;
end;

function wdgTList.IsEnabled(index: loopint): boolean;
begin
   Result := true;
end;

function wdgTList.IsNavigable(index: loopint): boolean;
begin
   Result := true;
end;

function wdgTList.IsSelectable(index: loopint): boolean;
begin
   Result := true;
end;

function wdgTList.GetGlyph(index: loopint): wdgTListGlyph;
begin
   Result.Glyph := nil;
   Result.Color := cWhite4ub;
end;

function wdgTList.GetItemVerticalOffset(index: loopint): loopint;
begin
   Result := GetItemOffset(index) - Offset + (PaddingTop + HeaderHeight);
end;

procedure wdgTList.RenderStart();
begin
end;

procedure wdgTList.RenderDone();
begin

end;

procedure wdgTList.Render();
var
   renderProperties: TBitSet;
   window: uiTWindow;
   borderColor: TColor4ub;
   highlightable: boolean;

   i,
   h: loopint;
   r,
   br,
   hbr: oxTRect;

   pSkin: uiTSkin;

procedure _getItemHeight(index: loopint);
begin
   if(ConstantHeight) then
      h := ItemHeight
   else begin
      h := GetItemHeight(index);
      r.h := h;
   end;
end;

procedure SetOddColor();
begin
   if(odd(i)) then
      window.SetColor(pSkin.Colors.LightSurface.Darken(0.1))
   else
      window.SetColor(pSkin.Colors.LightSurface);
end;

procedure SetHighlightColor();
begin
   if(IsEnabled(i)) then
      window.SetColor(pSkin.Colors.Highlight)
   else
      window.SetColor(pSkin.DisabledColors.Highlight);
end;

procedure RenderHighlighted(item, offset, itemX: loopint);
begin
   _getItemHeight(item);

   dec(r.y, offset);

   if(GetScissoredRect(r)) then begin
      if(IsEnabled(item)) then
         window.SetColor(pSkin.Colors.Highlight)
      else
         window.SetColor(pSkin.DisabledColors.Highlight);

      if(ItemHighlightWidth > 0) then begin
         inc(r.x, itemX);
         r.w := ItemHighlightWidth;
      end;

      uiDraw.Box(r);
   end;
end;

procedure DrawHBR();
begin
   hbr := r;
   dec(hbr.x, PaddingLeft);
   inc(hbr.w, PaddingRight + PaddingLeft);
   GetScissoredRect(hbr);
   uiDraw.Box(hbr);
end;

begin
   window := uiTWindow(wnd);
   pSkin := uiTSkin(window.Skin);

   if(not Transparent) then begin
      if(not OddColored) then
         renderProperties := wdgRENDER_BLOCK_SURFACE or wdgRENDER_BLOCK_SIMPLE
      else
         renderProperties := wdgRENDER_BLOCK_SIMPLE;

      if(Border > 0) then
         renderProperties := renderProperties or wdgRENDER_BLOCK_BORDER;

      if(not IsSelected()) or (not SelectBorder) then
         borderColor := pSkin.Colors.Border
      else
         borderColor := pSkin.Colors.SelectedBorder;

      uiRenderWidget.Box(uiTWidget(Self), pSkin.Colors.LightSurface, borderColor, renderProperties, window.opacity);
   end;

   {create rect for items}

   r.x := RPosition.x;
   r.y := RPosition.y ;
   r.w := Dimensions.w;
   r.h := ItemHeight;

   h := 0;

   inc(r.x, Border + PaddingLeft + HorizontalOffset);
   dec(r.y, Border + PaddingTop + HeaderHeight - VisibleOffset);

   dec(r.w, UnusableWidth);

   br := r;
   hbr := r;

   {render odd colored background}
   if(OddColored) then begin
      i := ItemOffset;
      h := ItemHeight;

      if(ItemHighlightWidth = 0) then begin
         repeat
            highlightable := ((HighlightedItem = i) or ((SelectedItem = i) and Selectable)) and ShouldHighlight(HighlightedItem);

            if (not highlightable) then
               SetOddColor()
            else
               SetHighlightColor();

            DrawHBR();

            if(i < ItemCount) then
               _getItemHeight(i);

            dec(r.y, h);
            inc(i);
         until(r.y < ContentYEnd);
      end else begin
         repeat
            SetOddColor();

            DrawHBR();

            if(i < ItemCount) then begin
               if(HighlightedItem = i) then begin
                  SetHighlightColor();

                  inc(hbr.x, HighlightedItemX);
                  hbr.w :=  ItemHighlightWidth;

                  GetScissoredRect(hbr);

                  uiDraw.Box(hbr);
               end else if(SelectedItem = i) and (Selectable) then begin
                  SetHighlightColor();

                  inc(hbr.x, SelectedItemX);
                  hbr.w :=  ItemHighlightWidth;

                  GetScissoredRect(hbr);

                  uiDraw.Box(hbr);
               end;

               _getItemHeight(i);
            end;

            dec(r.y, h);
            inc(i);
         until(r.y < ContentYEnd);
      end;
   end else begin
      hbr := r;

      if((HighlightedItem <> -1) and ShouldHighlight(HighlightedItem)) then
         RenderHighlighted(HighlightedItem, HighlightedItemOffset, HighlightedItemX);

      if(SelectedItem <> -1) and (Selectable) then begin
         r := hbr;
         RenderHighlighted(SelectedItem, SelectedItemOffset, SelectedItemX);
      end;
   end;

   if(ItemCount = 0) then
      exit;

   {render items}
   r := br;

   RenderStart();

   {scissor to go to next level}
   uiDraw.Scissor(RPosition, Dimensions);

   i := ItemOffset;

   if(i < ItemCount) then repeat
      _getItemHeight(i);

      if(not ScissorRect(r)) then
         break;

      RenderItem(i, r);

      dec(r.y, h);
      inc(i);
   until (r.y < ContentYEnd) or (i >= ItemCount);

   {done}
   uiDraw.DoneScissor();

   RenderDone();
end;

function wdgTList.Key(var k: appTKeyEvent): boolean;
begin
   Result := true;

   if(k.Key.Equal(kcHOME)) then begin
      if(k.Key.Released()) then
         StartItem();
   end else if(k.Key.Equal(kcEND)) then begin
      if(k.Key.Released()) then
         EndItem();
   end else if(k.Key.Equal(kcUP)) then begin
      if(not k.Key.Released()) then
         Previous();
   end else if(k.Key.Equal(kcDOWN)) then begin
      if(not k.Key.Released()) then
         Next();
   end else if(k.Key.Equal(kcENTER)) then begin
      if(k.Key.Released()) then
         ClickItem();
   end else if(k.Key.Equal(kcLEFT)) then begin
      if(not k.Key.Released()) then
         ScrollHorizontally(-1);
   end else if(k.Key.Equal(kcRIGHT)) then begin
      if(not k.Key.Released()) then
         ScrollHorizontally(1);
   end else if(k.Key.IsContext()) then begin
      if(not k.Key.Released()) then
         ItemClicked(LastItemUnderPointer, appmcRIGHT);
   end else
      Result := false;
end;

procedure wdgTList.Point(var e: appTMouseEvent; x, y: longint);
var
   index: loopint;

function SelectPointer(): longint;
begin
   ItemHighlightWidth := 0;
   Result := GetItemUnderPointer(x, y, HighlightedItemOffset);
   SelectedItem := Result;

   if(Result > -1) then begin
      if(Selectable) then
         HighlightedItem := Result;

      if(not Clickable and (Selectable or SelectableMultiple)) then begin
         {TODO: Select or unselect item}
      end else if (not (Selectable or SelectableMultiple) and Clickable) then begin
      end;
   end ;
end;

begin
   LastPointerPosition.x := x;
   LastPointerPosition.y := y;

   if(e.Action.IsSet(appmcRELEASED)) then begin
      if(not uiPointer.IsDoubleClick()) then begin
         if(e.Button = appmcLEFT) then begin
            SelectedItem := SelectPointer();
            SelectedItemOffset := HighlightedItemOffset;

            if(SelectedItem > -1) then begin
               ClickItem();
               ItemNavigated(SelectedItem);
            end else
               ItemCleared();
         end else begin
            index := SelectPointer();
            ItemClicked(index, e.Button);
         end;
      end else begin
         index := SelectPointer();
         ItemDoubleClicked(index, e.Button);
      end;
   end else if(e.IsWheel()) then begin
      if(e.Value < 0) then begin
         if(not uiSettings.NaturalScroll) then
            Next()
         else
            Previous();
      end else begin
         if(not uiSettings.NaturalScroll) then
            Previous()
         else
            Next();
      end;
   end;
end;

procedure wdgTList.Hover(x, y: longint; what: uiTHoverEvent);
var
   index: loopint = -1;

begin
   if(HighlightHovered) then begin
      index := GetItemUnderPointer(x, y, HighlightedItemOffset);

      if(what = uiHOVER_NO) then
         index := -1;

      HighlightedItem := index;
   end;

   OnHover(index);
end;

procedure wdgTList.SetTextColor();
begin
   if(Transparent) then
      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text)
   else
      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text);
end;

procedure wdgTList.SelectNavigableItemFrom(start: loopint);
var
   item: loopint;

begin
   if(AllowLoopingNavigation) and (start >= ItemCount) then
      start := 0;

   if(start < ItemCount) then begin
      item := start;

      repeat
         if(IsNavigable(item)) then
            break;

         inc(item);

         if(AllowLoopingNavigation) and (item >= ItemCount) then
            item := 0;
      until (item >= ItemCount) or (item = start);

      {we went to the end while finding no navigable items}
      if(item >= ItemCount) then
         exit;

      NavigateToItem(item);
   end;
end;

procedure wdgTList.SelectNavigableItemDownFrom(start: loopint);
var
   item: loopint;

begin
   if(AllowLoopingNavigation) and (start < 0) then
      start := ItemCount - 1;

   if(start >= 0) then begin
      item := start;

      repeat
         if(IsNavigable(item)) then
            break;

         dec(item);

         if(AllowLoopingNavigation) and (item < 0) then
            item := ItemCount - 1;
      until (item < 0) or (item = start);

      {we went below the item list while finding no navigable item}
      if(item < 0) then
         exit;

      NavigateToItem(item);
   end;
end;

procedure wdgTList.Next();
begin
   SelectNavigableItemFrom(SelectedItem + 1);
end;

procedure wdgTList.Previous();
begin
   SelectNavigableItemDownFrom(SelectedItem - 1);
end;

procedure wdgTList.StartItem();
begin
   if(ItemCount > 0) then
      SelectNavigableItemFrom(0);
end;

procedure wdgTList.EndItem();
begin
   if(ItemCount > 0) then
      SelectNavigableItemDownFrom(ItemCount - 1);
end;

procedure wdgTList.ClickItem();
begin
   if(SelectedItem <> -1) then
      ItemClicked(SelectedItem)
   else
      ItemCleared();
end;

procedure wdgTList.RemoveAll();
begin
   ItemsChanged();
end;

procedure wdgTList.NavigateToItem(index: loopint);
begin
   if(index < 0) then
      index := 0
   else if (index >= ItemCount) then
      index := ItemCount - 1;

   SelectedItem := index;
   HighlightedItem := index;

   SetOffsetToItem(SelectedItem);
   SelectedItemOffset := HighlightedItemOffset;

   LastItemUnderPointer := index;
   LastPointerPosition.x := 0;
   LastPointerPosition.y := Dimensions.h - GetTotalHeader() - SelectedItemOffset;

   NavigationMoved();

   ItemNavigated(index);
   if(NavigationIsSelection) then
      ItemSelected(SelectedItem);
end;

procedure wdgTList.AdjustOffset();
var
   i: loopint;

begin
   if(Offset < 0) then
      Offset := 0;

   if(Offset > Max - GetVisibleVerticalSpace()) then
      Offset := Max - GetVisibleVerticalSpace();

   {figure out what item is at this offset}
   ItemOffset := 0;

   if(Max < GetVisibleVerticalSpace()) then begin
      Offset := 0;
      VisibleOffset := 0;
      exit;
   end;

   if(ItemCount > 0) then begin
      for i := 0 to (ItemCount - 1) do begin
         if(Offset >= ItemOffsets.list[i]) and (Offset < ItemOffsets.list[i] + GetItemHeight(i)) then begin
            ItemOffset := i;
            break;
         end;
      end;

      VisibleOffset := Offset - GetItemOffset(ItemOffset);

      if(ItemOffset >= ItemCount) then
         ItemOffset := ItemCount - 1;
   end;
end;

procedure wdgTList.AdjustHorizontaloffset();
begin
   if(HorizontalOffset > MaxWidth - GetVisibleHorizontalSpace()) then
      HorizontalOffset := MaxWidth - GetVisibleHorizontalSpace();

   if(HorizontalOffset < 0) then
      HorizontalOffset := 0;
end;

procedure wdgTList.SetupUnusableSize();
begin
   inherited;

   inc(UnusableHeight, HeaderHeight);
   inc(UnusableHeight, FooterHeight);

   UpdateScrollbar();
end;

function wdgTList.CanFit(): boolean;
begin
   Result := Max <= GetVisibleVerticalSpace();
end;

function wdgTList.CanFitHorizontally(): boolean;
begin
   Result := MaxWidth <= GetVisibleHorizontalSpace();
end;

function scrollbarControl(wdg: TObject; what: longword): longint;
var
   parent: wdgTList;

begin
   Result := -1;

   if(what = wdgSCROLLBAR_MOVED) then begin
      parent := wdgTList(uiTWidget(wdg).Parent);

      parent.ScrollbarMoved(wdgTScrollbar(wdg).GetHandlePosition());
   end;
end;

function horizontalScrollbarControl(wdg: TObject; what: longword): longint;
var
   parent: wdgTList;

begin
   Result := -1;

   if(what = wdgSCROLLBAR_MOVED) then begin
      parent := wdgTList(uiTWidget(wdg).Parent);

      parent.HorizontalScrollbarMoved(wdgTScrollbar(wdg).GetHandlePosition());
   end;
end;

procedure wdgTList.UpdateScrollbar();
begin
   if(CanFitHorizontally()) then begin
      if(horizontalScrollWidget <> nil) then
         horizontalScrollWidget.Show();
   end else begin
      if(horizontalScrollWidget <> nil) then begin
         horizontalScrollWidget.Show();
         horizontalScrollWidget.Bottom();
         horizontalScrollWidget.SetSize(MaxWidth, GetVisibleHorizontalSpace());
      end else begin
         if(GetVisibleHorizontalSpace() > 0) and (Dimensions.IsPositive()) then begin
            {create widget}
            uiWidget.PushTarget();

            Self.SetTarget(@horizontalScrollbarControl);
            horizontalScrollWidget :=
               wdgScrollbar.Add(MaxWidth, GetVisibleHorizontalSpace()).Light().Bottom();

            uiWidget.PopTarget();

            if(PermanentHorizontalScrollbar) then begin
               FooterHeight := horizontalScrollWidget.Dimensions.h;
               horizontalScrollWidget.Permanent := true;

               AdjustOffset();
               AdjustScrollbar();
            end;
         end;
      end;
   end;

   {determine whether or not to show the scrollbar}
   if(CanFit()) then begin
      if(scrollWidget <> nil) then
         scrollWidget.Hide();
   end else begin
      if(scrollWidget <> nil) then begin
         scrollWidget.Show();
         scrollWidget.Right();
         scrollWidget.SetSize(Max{ - GetVisibleVerticalSpace()}, GetVisibleVerticalSpace());
      end else begin
         if(GetVisibleVerticalSpace() > 0) and (Dimensions.IsPositive()) then begin
            {create widget}
            uiWidget.PushTarget();

            Self.SetTarget(@scrollbarControl);
            scrollWidget :=
               wdgScrollbar.Add(Max{ - GetVisibleVerticalSpace()}, GetVisibleVerticalSpace()).Light().Right();

            uiWidget.PopTarget();
         end;
      end;
   end;
end;

procedure wdgTList.AdjustScrollbar();
begin
   if(scrollWidget <> nil) then
      scrollWidget.SetHandlePosition((double(1.0) / (Max - GetVisibleVerticalSpace())) * Offset);
end;

procedure wdgTList.ScrollbarMoved(p: single);
begin
   Offset := round(p * (Max - GetVisibleVerticalSpace()));

   AdjustOffset();
end;

procedure wdgTList.HorizontalScrollbarMoved(p: single);
begin
   HorizontalOffset := round(p * (MaxWidth - GetVisibleHorizontalSpace()));
end;

procedure wdgTList.ItemsChanged();
var
   i: loopint;
   offs: loopint;

begin
   ItemCount := GetItemCount();

   ItemOffsets.SetSize(ItemCount);
   if(ItemCount > 0) then begin
      offs := 0;

      for i := 0 to (ItemCount - 1) do begin
         ItemOffsets.list[i] := offs;

         inc(offs, GetItemHeight(i));
      end;
   end;

   Max := GetAllHeight();
   MaxWidth := GetMaxWidth();

   Offset := 0;
   HighlightedItemOffset := 0;
   SelectedItem := -1;
   HighlightedItem := -1;
   HorizontalOffset := 0;

   HighlightedItemX := 0;
   ItemHighlightWidth := 0;
   SelectedItemX := 0;

   InternalItemsChanged();

   UpdateScrollbar();
end;

procedure wdgTList.SetItemHeight(height: loopint);
begin
   ItemHeight := height;
end;

procedure wdgTList.UpdateItemHeight();
begin
end;

procedure wdgTList.PositionChanged;
begin
   inherited PositionChanged;

   Recalculate();
end;

procedure wdgTList.SizeChanged();
begin
   inherited SizeChanged;

   Recalculate();
   UpdateScrollbar();
end;

procedure wdgTList.RPositionChanged;
begin
   inherited ParentSizeChange;

   Recalculate();
end;

procedure wdgTList.Recalculate();
begin
   ContentYEnd := RPosition.y - GetContentYEnd();
   ContentY :=  RPosition.y - GetContentY();
end;

procedure wdgTList.ItemClicked(index: loopint; button: TBitSet);
begin
end;

procedure wdgTList.ItemCleared();
begin

end;

procedure wdgTList.ItemDoubleClicked(index: loopint; button: TBitSet);
begin
end;

procedure wdgTList.ItemSelected(index: loopint);
begin

end;

procedure wdgTList.ItemUnselected(index: loopint);
begin

end;

procedure wdgTList.ItemNavigated(index: loopint);
begin

end;

procedure wdgTList.OnHover(index: loopint);
begin

end;

procedure wdgTList.NavigationMoved();
begin

end;

procedure wdgTList.InternalItemsChanged();
begin

end;

function wdgTList.GetItemUnderPointer(x, y: loopint; out offs: loopint): loopint;
var
   index,
   i,
   currentY,
   pointedOffset: loopint;

begin
   offs := 0;

   if(ItemCount > 0) and (ItemHeight > 0) then begin
      pointedOffset := Offset + loopint(Dimensions.h - HeaderHeight - y - (1 + (UnusableHeight - HeaderHeight) div 2));

      if(ConstantHeight) then begin
         Result := pointedOffset div ItemHeight;

         if(Result >= ItemCount) then
            Result := -1
         else
            offs := (result - ItemOffset) * ItemHeight;
      end else begin
         i := ItemOffset;

         currentY := Offset + ((UnusableHeight - HeaderHeight) div 2) - 1 - HeaderHeight;
         index := -1;

         repeat
            if(pointedOffset >= currentY) and (pointedOffset < ItemOffsets.list[i] + GetItemHeight(i)) then begin
               offs := currentY;
               index := i;
               break;
            end;

            inc(currentY, GetItemHeight(i));
            inc(i);
         until (i >= ItemCount) or (currentY > Offset + Dimensions.h - (HeaderHeight + (UnusableHeight - HeaderHeight) div 2));

         Result := index;
      end;
   end else
      Result := -1;

   LastItemUnderPointer := Result;
end;

procedure wdgTList.SetOffsetToItem(item: loopint);
begin
   if(Selectable) then
      HighlightedItem := item;

   HighlightedItemOffset := GetItemOffset(item);

   if(HighlightedItemOffset + GetItemHeight(item) >= Offset + GetVisibleVerticalSpace()) then
      Offset := GetItemOffset(item) - GetVisibleVerticalSpace() + GetItemHeight(item)
   else if(HighlightedItemOffset < Offset) then
      Offset := GetItemOffset(item);

   AdjustOffset();
   AdjustScrollbar();

   HighlightedItemOffset := HighlightedItemOffset - Offset + VisibleOffset;
end;

procedure wdgTList.ScrollHorizontally(howMuch: loopint);
var
   amount: loopint;

begin
   if(GetVisibleHorizontalSpace() < MaxWidth) then begin
      amount := (GetVisibleHorizontalSpace() div 3) * howMuch;

      HorizontalOffset := HorizontalOffset + amount;

      AdjustHorizontalOffset();
   end;
end;

function wdgTList.GetContentY(): loopint;
begin
   Result := GetTotalHeader();
end;

function wdgTList.GetContentYEnd(): loopint;
var
   unusable: loopint;

begin
   unusable := (1 + (UnusableHeight - HeaderHeight) div 2);

   Result := Dimensions.h -  unusable;
end;

function wdgTList.GetTotalHeader(): loopint;
begin
   Result := ((UnusableHeight - HeaderHeight) div 2) - HeaderHeight;
end;

function wdgTList.GetScissoredRect(var r: oxTRect): boolean;
var
   sRect: oxTRect;
   uWidth: loopint;

begin
   sRect := r;
   uWidth := UnusableWidth - PaddingLeft - PaddingRight;

   if(r.y - r.h + 1 < ContentYEnd) then begin
      sRect.h := r.h - (ContentYEnd - (r.y - r.h) + 1);

      if(sRect.h < 0) then
         sRect.h := 0;
   end;

   if(r.y >= ContentY) then begin
      sRect.y := ContentY;
      sRect.h := sRect.h - (r.y - ContentY);
   end;

   if(sRect.x < RPosition.x + (uWidth div 2)) then
      sRect.x := RPosition.x + (uWidth div 2);

   r := sRect;
   Result := sRect.h > 0;
end;

function wdgTList.ScissorRect(var r: oxTRect): boolean;
var
   sRect: oxTRect;

begin
   sRect := r;

   Result := GetScissoredRect(sRect);

   if(sRect.h > 0) then
      uiDraw.Scissor(sRect, false);
end;

procedure InitWidget();
begin
   wdgList.Internal.Done(wdgTList);

   wdgList := wdgTListGlobal.Create(wdgList.Internal);
end;

procedure InitStringWidget();
begin
   wdgStringList.Internal.Done(wdgTStringList);

   wdgStringList := wdgTStringListGlobal.Create(wdgStringList.Internal);
end;

INITIALIZATION
   wdgList.Internal.Register('widget.list', @InitWidget);
   wdgStringList.Internal.Register('widget.stringlist', @InitStringWidget);

END.
