{
   wdguHierarchyList, hierarchical list
   Copyright (C) 2017. Dejan Boras

   Started On:    20.03.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguHierarchyList;

INTERFACE

   USES
      uStd, uColors, vmVector,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuFont, oxuTexture, oxuRender, oxuRenderUtilities,
      {ui}
      oxuUI, uiuTypes, uiuWindowTypes, uiuWidget, uiWidgets, uiuWindow, uiuDraw,
      wdguList;

CONST
   wdgHIERARCHY_LIST_INDENTATION_WIDTH = 20;

TYPE
   wdgTHierarchyListItem = record
      Item: pointer;
      Level: longint;
   end;

   wdgTPreallocatedHierarchyListItems = specialize TPreallocatedArrayList<wdgTHierarchyListItem>;

   { wdgTHierarchyList }

   wdgTHierarchyList = class(wdgTStringListBase)
      {current number of items}
      TotalItemCount,
      {item indetation width for every level}
      ItemIndentationWidth,
      {separation between the expander symbol and the rest}
      ExpanderSeparationWidth: loopint;
      {the widget should manage the data (data is not external)}
      ManageData: Boolean;

      constructor Create; override;

      {render the item}
      procedure RenderItem(index: loopint; r: oxTRect); override;

      {called when the initial items are loaded}
      procedure Load(); virtual;

      {value of the item with the given index}
      function GetValue({%H-}index: loopint): string; virtual;
      {determines if the item with the given index is expandable}
      function Expandable({%H-}index: loopint): boolean; virtual;
      {check if the given item is expanded}
      function Expanded(index: loopint): boolean;

      function GetItemCount(): loopint; override;
      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
      function GetItemWidth(index: loopint): loopint; override;

      function GetExpanderWidth(): loopint;
      function GetHorizontalItemOffset(index: loopint): loopint;

      {get the item with the specified index}
      function GetItem(index: loopint): pointer;

      {get sub items of the given item, and if given item is nil, return the top level items}
      function GetSubItems({%H-}index: loopint; {%H-}ref: pointer): TPreallocatedPointerArrayList; virtual;
      {find the index of the given item}
      function Find(item: pointer): loopint;

      {collapses the specified item, if it is collapsible}
      procedure Collapse(index: loopint);
      {expand the specified item, if it is expandable}
      procedure Expand(index: loopint);

      {add a new single item }
      procedure AddItem(index: loopint; item: pointer);
      {add a new single item }
      procedure RemoveItem(index: loopint);

      procedure RemoveAll; override;

      procedure FontChanged; override;

      protected
         {visible items}
         Visible: wdgTPreallocatedHierarchyListItems;
         {width of the current font character}
         FontWidth: loopint;

         procedure ExpandTo(const items: TPreallocatedPointerArrayList; index: loopint; l: loopint);

         {expand data list with the given items at given index}
         procedure ExpandData(const {%H-}items: TPreallocatedPointerArrayList; {%H-}index: loopint); virtual;
         {collapses the specified data range}
         procedure CollapseData({%H-}index, {%H-}count: loopint); virtual;
   end;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure InitWidget();
begin
   internal.Instance := wdgTHierarchyList;
   internal.Done();
end;

{ wdgTHierarchyList }

constructor wdgTHierarchyList.Create;
begin
   inherited;

   Clickable := true;
   HighlightHovered := true;
   OddColored := true;

   Visible.Increment := 32;
   ExpanderSeparationWidth := 2;

   VerticalSeparation := 0.75;
   ItemIndentationWidth := wdgHIERARCHY_LIST_INDENTATION_WIDTH;
end;

procedure wdgTHierarchyList.RenderItem(index: loopint; r: oxTRect);
var
   s: string;
   glyph: wdgTListGlyph;
   width,
   height,
   triangleOffset,
   padding: loopint;
   pr: oxTRect;
   px,
   py: single;
   f: oxTFont;
   triangle: array[0..2] of TVector3f;

begin
   f := CachedFont;
   SetFontColor(index);

   inc(r.x, GetHorizontalItemOffset(index));

   s := GetValue(index);

   width := GetExpanderWidth();
   triangle[0] := vmvZero3f;

   if(Expandable(index)) then begin
      height := round(ItemHeight * 0.8);
      triangleOffset := (ItemHeight - height) div 2;

      pr := r;
      inc(pr.x, triangleOffset);
      dec(pr.y, triangleOffset);
      pr.h := height;
      pr.w := height;

      if(not Expanded(index)) then begin
         triangle[2].Assign(pr.x, pr.y, 0);
         triangle[1].Assign(pr.x + pr.w, pr.y - (pr.h / 2), 0);
         triangle[0].Assign(pr.x, pr.y - pr.h, 0);
      end else begin
         triangle[2].Assign(pr.x, pr.y, 0);
         triangle[1].Assign(pr.x + pr.h, pr.y, 0);
         triangle[0].Assign(pr.x + (pr.h / 2), pr.y - pr.h, 0);
      end;

      uiDraw.CorrectPoints(PVector3f(@triangle[0]), 3);

      oxui.Material.ApplyTexture('texture', nil);
      oxui.Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
      oxRenderingUtilities.Triangle(triangle[0], triangle[1], triangle[2]);
      oxui.Material.ApplyTexture('texture', f.Texture);
      oxRender.BlendDefault();
   end;

   inc(r.x, width + ExpanderSeparationWidth);

   if(HasGlyphs) then begin
      glyph := GetGlyph(index);

      padding := 1;

      height := (r.h - padding * 2) div 2;

      px := r.x + height;
      py := r.y - (r.h - padding * 2) div 2;

      if(glyph.Glyph <> nil) and (glyph.Glyph.rId <> 0) then begin
         oxRender.BlendDefault();
         SetColorBlended(glyph.Color);
         oxRenderingUtilities.TexturedQuad(px, py, height, height, glyph.Glyph);
         oxui.Material.ApplyTexture('texture', f.Texture);
      end;

      inc(r.x, (height * 2) + (padding * 2));
   end;

   SetColorBlendedEnabled(uiTWindow(wnd).Skin.Colors.Text, uiTWindow(wnd).Skin.DisabledColors.Text);

   f.WriteCentered(s, r, [oxfpCenterVertical]);
end;

procedure wdgTHierarchyList.Load();
var
   items: TPreallocatedPointerArrayList;

begin
   if(Visible.n > 0) then begin
      if(ManageData) then
         CollapseData(0, Visible.n);

      Visible.RemoveRange(0, Visible.n);
   end;

   items := GetSubItems(0, nil);

   ExpandTo(items, 0, 0);

   if(items.n = 0) then
      ItemsChanged();

   items.Dispose();
end;

function wdgTHierarchyList.GetValue(index: loopint): string;
begin
   result := '';
end;

function wdgTHierarchyList.Expandable(index: loopint): boolean;
begin
   result := false;
end;

function wdgTHierarchyList.Expanded(index: loopint): boolean;
begin
   result := (index < Visible.n - 1) and (Visible.List[index + 1].Level = (Visible.List[index].Level + 1));
end;

function wdgTHierarchyList.GetItemCount(): loopint;
begin
   result := Visible.n;
end;

procedure wdgTHierarchyList.ItemClicked(index: loopint;  button: TBitSet);
var
   items: TPreallocatedPointerArrayList;

function expandedClicked(): boolean;
var
   w, l: loopint;

begin
   l := Visible.List[index].Level;

   w := ItemHeight;
   inc(w, l * ItemIndentationWidth);

   result := LastPointerPosition.x - (UnusableWidth div 2) <=  w;
end;

begin
   if(button = appmcLEFT) then begin
      if(Expandable(index) and expandedClicked()) then begin
         if(not Expanded(index)) then begin
            items := GetSubItems(index, Visible.List[index].Item);
            ExpandTo(items, index + 1, Visible.List[index].Level + 1);
            items.Dispose();
         end else
            Collapse(index);
      end;
   end;
end;

function wdgTHierarchyList.GetItemWidth(index: loopint): loopint;
var
   s: string;
   l: loopint;
   f:oxTFont;

begin
   f := CachedFont;
   s := GetValue(index);

   l := Visible.List[index].Level;
   Result := (l * ItemIndentationWidth) +  f.GetLength(s);

   if(Expandable(index)) then
      Result := Result + ItemHeight;
end;

function wdgTHierarchyList.GetExpanderWidth(): loopint;
begin
   result := ItemHeight;
end;

function wdgTHierarchyList.GetHorizontalItemOffset(index: loopint): loopint;
begin
   if(Visible.List[index].Level > 0) then
      Result := Visible.List[index].Level * ItemIndentationWidth
   else
      Result := 0;
end;

function wdgTHierarchyList.GetItem(index: loopint): pointer;
begin
   if(index >= 0) and (index < Visible.n) then
      result := Visible.List[index].Item
   else
      result := nil;
end;

function wdgTHierarchyList.GetSubItems(index: loopint; ref: pointer): TPreallocatedPointerArrayList;
begin
   Result.Initialize(Result);
end;

function wdgTHierarchyList.Find(item: pointer): loopint;
var
   i: loopint;

begin
   for i := 0 to (Visible.n - 1) do begin
      if(Visible.List[i].Item = item) then
         exit(i);
   end;

   result := -1;
end;

procedure wdgTHierarchyList.ExpandTo(const items: TPreallocatedPointerArrayList; index: loopint; l: loopint);
var
   i: loopint;

begin
   if(items.n > 0) then begin
      Visible.InsertRange(index, items.n);

      {copy over items and set levels}
      for i := 0 to (items.n - 1) do begin
         Visible.List[index + i].Item := items.List[i];
         Visible.List[index + i].Level := l;
      end;

      if(ManageData) then
         ExpandData(items, index);

      ItemsChanged();
   end;
end;

procedure wdgTHierarchyList.Collapse(index: loopint);
var
   i,
   count,
   l: loopint;

begin
   if(index < Visible.n - 1) then begin
      count := 0;

      {find target level to collapse}
      l := Visible.List[index].Level + 1;

      {find how many items we need to remove}
      for i := index + 1 to (Visible.n - 1) do begin
         if(Visible.List[i].Level >= l) then
            inc(count)
         else
            break;
      end;

      if(count > 0) then begin
         Visible.RemoveRange(index + 1, count);

         if(ManageData) then
            CollapseData(index + 1, count);
      end;
   end;

   ItemsChanged();
end;

procedure wdgTHierarchyList.Expand(index: loopint);
var
   items: TPreallocatedPointerArrayList;

begin
   if(Expandable(index) and (not Expanded(index))) then begin
      items := GetSubItems(index, Visible.List[index].Item);
      ExpandTo(items, index + 1, Visible.List[index].Level + 1);
      items.Dispose();

      ItemsChanged();
   end;
end;

procedure wdgTHierarchyList.AddItem(index: loopint; item: pointer);
var
   items: TPreallocatedPointerArrayList;
   l, i: longint;

begin
   items.Initialize(items);

   items.Allocate(1);
   items.Add(item);

   if(index = -1) then begin
      ExpandTo(items, Visible.n, 0);
      ItemsChanged();
   end else begin
      {if not expanded then we don't need to add it to the list}
      if(Expanded(index) and (index < Visible.n)) then begin
         l := Visible.List[index].Level;
         i := index;

         repeat
            inc(i);

            if(i < Visible.n) and (Visible.List[i].Level <= l) then begin
               i := i;
               break;
            end;
         until i = Visible.n;

         Expandto(items, i, l + 1);
         ItemsChanged();
      end;
   end;

   items.Dispose();
end;

procedure wdgTHierarchyList.RemoveItem(index: loopint);
begin
   if((index > -1) and (index < Visible.n)) then begin
      if(Expanded(index)) then
         Collapse(index);

      Visible.Remove(index);
      CollapseData(index, 1);

      ItemsChanged();
   end;
end;

procedure wdgTHierarchyList.RemoveAll;
begin
   Visible.Dispose();

   inherited RemoveAll;
end;

procedure wdgTHierarchyList.FontChanged;
begin
   inherited FontChanged;
end;

procedure wdgTHierarchyList.ExpandData(const items: TPreallocatedPointerArrayList; index: loopint);
begin

end;

procedure wdgTHierarchyList.CollapseData(index, count: loopint);
begin

end;

INITIALIZATION
   internal.Register('widget.hierarchylist', @InitWidget);

END.
