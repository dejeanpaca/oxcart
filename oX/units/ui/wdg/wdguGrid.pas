{
   wdguGrid, grid widget
   Copyright (C) 2016. Dejan Boras

   Started On:    12.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguGrid;

INTERFACE

   USES
      math, uStd, uColors,
      {app}
      appuKeys, appuMouse,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuTypes, uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuDraw, uiuWindow,
      wdguList;

CONST
   {column title padding}
   wdgGRID_COLUMN_TITLE_PADDING     = 5;
   {column title size}
   wdgGRID_COLUMN_TITLE_HEIGHT      = 17;
   {column minimum width}
   wdgGRID_COLUMN_MINIMUM_WIDTH     = 5;
   {column separator line width}
   wdgGRID_SEPARATOR_WIDTH          = 1;
   {column title separator line height}
   wdgGRID_HEADER_SEPARATOR_HEIGHT  = 1;

TYPE
   { wdgTGrid }
   wdgPGridColumn = ^wdgTGridColumn;
   wdgTGridColumn = record
      Title: string;
      Width: loopint;
      Ratio: single;
      HorizontalJustify: uiTHorizontalJustify;
      VerticalJustify: uiTVerticalJustify;
   end;

   wdgTGridColumnList = specialize TPreallocatedArrayList<wdgTGridColumn>;

   wdgTGrid = class(wdgTList)
      TitlePadding,
      SeparatorWidth,
      HeaderSeparatorHeight,
      ColumnMinimumWidth,
      ColumnTitleHeight,
      {last grid item under pointer}
      LastGridItemUnderPointer,
      {currently selected item in grid mode}
      SelectedGridItem: loopint;

      {list of columns}
      Columns: wdgTGridColumnList;

      {is the header (columns header) visible}
      ShowHeader,
      {pure grid mode (no headers or separators, just a MxN grid)}
      GridMode: boolean;

      {dimensions of an item in grid mode}
      ItemDimensions,
      {minimum item dimensions, if set to lower, grid mode is disabled}
      MinimumItemDimensions: oxTDimensions;

      constructor Create; override;

      {add a new column}
      function AddColumn(const columnTitle: string): wdgPGridColumn;
      {call when done adding columns}
      procedure ColumnAddDone();

      procedure RenderItem(index: loopint; r: oxTRect); override;

      procedure Render; override;

      function GetMaxWidth(): loopint; override;
      function GetItemHeight(index: loopint): loopint; override;
      function GetItemWidth({%H-}index: loopint): loopint; override;

      function Key(var k: appTKeyEvent): boolean; override;

      {calculates how many items fit per row}
      function ItemsPerRow(): loopint;
      {get item index for row and column (should be used in grid mode)}
      function GetItemIndex(row, column: loopint): loopint;
      {get total amount of item rows}
      function GetItemRows(total: loopint): loopint;
      {get the column number frol SelectedGridItem}
      function GetColumnFromSelected(): loopint;

      {enable showing of header (update will also update offsets, scrollbar, ... )}
      procedure EnableHeader(doUpdate: boolean = true);
      {disable showing of header (update will also update offsets, scrollbar, ... )}
      procedure DisableHeader(doUpdate: boolean = true);

      {enable pure grid mode}
      procedure EnableGridMode(doUpdate: boolean = true);
      {enable pure grid mode}
      procedure DisableGridMode(doUpdate: boolean = true);

      {called when a row is rendered}
      procedure RenderColumn({%H-}index, {%H-}columnIndex: loopint; var {%H-}r: oxTRect); virtual;

      {set item dimensions}
      procedure SetItemDimensions(const d: oxTDimensions);
      {should be called when data is available}
      procedure Assigned();

      {compute column sizes}
      procedure ComputeColumns();
      {called when column count changes}
      procedure OnColumnCountChange(); virtual;
      {get the number of grid items}
      function GetGridItemCount(): loopint; virtual;

      {select a column}
      procedure SelectColumn(column: loopint);
      {navigate to a column}
      procedure NavigateToColumn(column: loopint; doUpdate: boolean = true);

      protected
         procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
         procedure ItemDoubleClicked(index: loopint; button: TBitSet); override;

         procedure GridItemClicked({%H-}index: loopint; {%H-}button: TBitSet = appmcLEFT); virtual;
         procedure GridItemDoubleClicked({%H-}index: loopint; {%H-}button: TBitSet); virtual;

         function GetItemUnderPointer(x, y: loopint; out offs: loopint): loopint; override;

         procedure PositionChanged; override;
         procedure SizeChanged; override;

         procedure OnHover({%H-}index: loopint); override;
         procedure OnGridHover({%H-}index: loopint); virtual;

         procedure NavigationMoved(); override;
         procedure InternalItemsChanged(); override;
   end;

   { wdgTStringGrid }

   wdgTStringGrid = class(wdgTGrid)
      public
         {vertical separation ratio}
         VerticalSeparation: single;

      constructor Create; override;

      {get the value for the current column, intended to be overriden to get a string from a source}
      function GetValue({%H-}index, {%H-}column: loopint): string; virtual;

      procedure RenderStart; override;
      procedure RenderDone; override;

      procedure RenderColumn(index, columnIndex: loopint; var r: oxTRect); override;

      procedure SetFontColor(index: longint);

      procedure UpdateItemHeight; override;

      protected
         procedure FontChanged; override;
   end;

   { wdgTGridGlobal }

   wdgTGridGlobal = record
      function Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTGrid;
   end;

   { wdgTStringGridGlobal }

   wdgTStringGridGlobal = record
      function Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTStringGrid;
   end;

VAR
   wdgGrid: wdgTGridGlobal;
   wdgStringGrid: wdgTStringGridGlobal;

IMPLEMENTATION

VAR
   internal,
   internalString: uiTWidgetClass;

{ wdgTStringGrid }

constructor wdgTStringGrid.Create;
begin
   inherited Create;

   VerticalSeparation := 0.75;
end;

function wdgTStringGrid.GetValue(index, column: loopint): string;
begin
   Result := '';
end;

procedure wdgTStringGrid.RenderStart;
begin
   CachedFont.Start();
   SetTextColor();

   uiDraw.Scissor(RPosition, Dimensions);
end;

procedure wdgTStringGrid.RenderDone;
begin
   oxf.Stop();

   uiDraw.DoneScissor();
end;

procedure wdgTStringGrid.RenderColumn(index, columnIndex: loopint; var r: oxTRect);
var
   f: oxTFont;
   s: string;
   props: oxTFontPropertiesSet;

begin
   if(not ScissorRect(r)) then
      exit;

   f := CachedFont;
   s := GetValue(index, columnIndex);

   if(s <> '') then begin
      props := [];

      if(Columns.List[columnIndex].HorizontalJustify = uiJUSTIFY_HORIZONTAL_CENTER) then
         Include(props, oxfpCenterHorizontal)
      else if(Columns.List[columnIndex].HorizontalJustify = uiJUSTIFY_HORIZONTAL_RIGHT) then
         Include(props, oxfpCenterRight);

      if(Columns.List[columnIndex].VerticalJustify = uiJUSTIFY_VERTICAL_CENTER) then
         Include(props, oxfpCenterVertical)
      else if(Columns.List[columnIndex].VerticalJustify = uiJUSTIFY_VERTICAL_TOP) then
         Include(props, oxfpCenterTop);

      f.WriteCentered(s, r, props);
   end;
end;

procedure wdgTStringGrid.SetFontColor(index: longint);
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

procedure wdgTStringGrid.UpdateItemHeight;
var
   h: loopint;

begin
   inherited UpdateItemHeight;

   ConstantHeight := true;

   h := CachedFont.GetHeight();
   SetItemHeight(h + round(h * VerticalSeparation));
end;

procedure wdgTStringGrid.FontChanged;
begin
   inherited FontChanged;

   UpdateItemHeight();
end;

{ wdgTGrid }

constructor wdgTGrid.Create;
begin
   TitlePadding := wdgGRID_COLUMN_TITLE_PADDING;
   SeparatorWidth := wdgGRID_SEPARATOR_WIDTH;
   HeaderSeparatorHeight := wdgGRID_HEADER_SEPARATOR_HEIGHT;
   ColumnMinimumWidth := wdgGRID_COLUMN_MINIMUM_WIDTH;
   ColumnTitleHeight := wdgGRID_COLUMN_TITLE_HEIGHT;

   EnableHeader(false);

   ItemDimensions.Assign(64, 64);
   MinimumItemDimensions.Assign(24, 24);
   SelectedGridItem := -1;

   Columns.InitializeValues(Columns, 8);

   inherited Create;
end;

function wdgTGrid.AddColumn(const columnTitle: string): wdgPGridColumn;
var
   g: wdgTGridColumn;

begin
   g.Title := columnTitle;
   g.Width := CachedFont.GetLength(g.Title) + (TitlePadding * 2);
   g.Ratio := 0;
   g.HorizontalJustify := uiJUSTIFY_HORIZONTAL_LEFT;
   g.VerticalJustify := uiJUSTIFY_VERTICAL_CENTER;

   Columns.Add(g);

   Result := @Columns.List[Columns.n - 1];
end;

procedure wdgTGrid.ColumnAddDone();
begin
   OnColumnCountChange();
end;

procedure wdgTGrid.RenderItem(index: loopint; r: oxTRect);
var
   i,
   c: loopint;
   {a part of the whole rect}
   subR: oxTRect;

begin
   subR := r;

   if(not GridMode) then begin
      for i := 0 to (Columns.n - 1) do begin
         subR.w := Columns.List[i].Width;

         RenderColumn(index, i, subR);

         inc(subR.x, subR.w);
      end;
   end else begin
      c := ItemsPerRow();

      for i := 0 to c - 1 do begin
         subR.w := ItemDimensions.w;

         RenderColumn(index, i, subR);

         inc(subR.x, subR.w);
      end;
   end;
end;

procedure wdgTGrid.Render;
var
   i: loopint;
   r,
   br: oxTRect;
   f: oxTFont;

begin
   inherited Render;

   if(ShowHeader) then begin
      {render title}
      SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.LightSurface);
      uiDraw.Box(RPosition.x + Border, RPosition.y - Border,
         RPosition.x + Dimensions.w - 1 - Border, RPosition.y - ColumnTitleHeight - Border + 1);

      {render title separator}
      SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Border);
      uiDraw.Box(RPosition.x + Border, RPosition.y - ColumnTitleHeight - Border,
         RPosition.x + Dimensions.w - 1 - Border, RPosition.y - Border - HeaderHeight + 1);

      {render columns}
      if(Columns.n > 0) then begin
         r.x := RPosition.x + Border;
         r.y := RPosition.y - Border;
         r.w := SeparatorWidth;
         r.h := ColumnTitleHeight;
         br := r;

         {render column separators in title}
         for i := 1 to (Columns.n - 1) do begin
            inc(r.x, Columns.List[i - 1].Width);

            if(r.x < RPosition.x + Dimensions.w) then
               uiDraw.Box(r);
         end;

         SetTextColor();

         r := br;

         f := CachedFont;
         f.Start();

         for i := 0 to (Columns.n - 1) do begin
            r.w := Columns.List[i].Width;

            f.WriteCentered(Columns.List[i].Title, r, oxfpCenterHV);
            inc(r.x, r.w);
         end;

         oxf.Stop();
      end;
   end;
end;

function wdgTGrid.GetMaxWidth(): loopint;
var
   i: loopint;

begin
   Result := 0;

   if(not GridMode) then begin
      for i := 0 to (Columns.n - 1) do begin
         inc(Result, Columns.list[i].Width);
      end;

      if(Columns.n > 1) then
         inc(Result, SeparatorWidth * (Columns.n - 1));
   end else
      Result := GetVisibleHorizontalSpace();
end;

function wdgTGrid.GetItemHeight(index: loopint): loopint;
begin
   if(not GridMode) then
      Result := inherited GetItemHeight(index)
   else
      Result := ItemDimensions.h;
end;

function wdgTGrid.GetItemWidth(index: loopint): loopint;
begin
   Result := GetMaxWidth();
end;

function wdgTGrid.Key(var k: appTKeyEvent): boolean;
begin
   if(GridMode) then begin
      if(k.Key.Equal(kcLEFT)) then begin
         if(k.Key.Released()) then begin
            NavigateToColumn(GetColumnFromSelected() - 1);
         end;

         exit(true);
      end else if(k.Key.Equal(kcRIGHT)) then begin
         if(k.Key.Released()) then begin
            NavigateToColumn(GetColumnFromSelected() + 1);
         end;

         exit(true);
      end else if(k.Key.Equal(kcENTER)) then begin
         if(k.Key.Released()) then begin
            if(SelectedGridItem <> -1) then
               ItemClicked(SelectedGridItem);
         end;

         exit(true);
      end;
   end;

   Result := inherited Key(k);
end;

function wdgTGrid.ItemsPerRow(): loopint;
begin
   if(not GridMode) then
      Result := Columns.n
   else
      Result := trunc(GetVisibleHorizontalSpace() / ItemDimensions.w);
end;

function wdgTGrid.GetItemIndex(row, column: loopint): loopint;
begin
   Result := row * ItemsPerRow() + column;
end;

function wdgTGrid.GetItemRows(total: loopint): loopint;
begin
   Result := math.ceil(total / ItemsPerRow());
end;

function wdgTGrid.GetColumnFromSelected(): loopint;
begin
   result := SelectedGridItem mod ItemsPerRow();
end;

procedure wdgTGrid.EnableHeader(doUpdate: boolean);
begin
   HeaderHeight := ColumnTitleHeight + HeaderSeparatorHeight;
   ShowHeader := true;

   if(doUpdate) then begin
      ComputeColumns();
      AdjustOffset();
      UpdateScrollbar();
   end;
end;

procedure wdgTGrid.DisableHeader(doUpdate: boolean);
begin
   ShowHeader := false;
   HeaderHeight := 0;

   if(doUpdate) then begin
      AdjustOffset();
      UpdateScrollbar();
   end;
end;

procedure wdgTGrid.EnableGridMode(doUpdate: boolean);
begin
   GridMode := true;
   ConstantHeight := true;
   SetItemHeight(ItemDimensions.h);
   DisableHeader(doUpdate);
end;

procedure wdgTGrid.DisableGridMode(doUpdate: boolean = true);
begin
   GridMode := false;
   UpdateItemHeight();
   EnableHeader(doUpdate);

   HighlightedItemX := 0;
   ItemHighlightWidth := 0;
   SelectedItemX := 0;
   SelectedGridItem := -1;
end;

procedure wdgTGrid.RenderColumn(index, columnIndex: loopint; var r: oxTRect);
begin
end;

procedure wdgTGrid.SetItemDimensions(const d: oxTDimensions);
begin
   ItemDimensions := d;

   if(d.w < MinimumItemDimensions.w) or (d.h <  MinimumItemDimensions.h) then begin
      ItemDimensions := MinimumItemDimensions;
      DisableGridMode();
   end;

   ItemsChanged();
end;

procedure wdgTGrid.Assigned();
begin
   ComputeColumns();
   ItemsChanged();
   AdjustOffset();
   Recalculate();
end;

procedure wdgTGrid.ComputeColumns();
var
   i,
   totalWidth: loopint;

begin
   if(Columns.n > 0) then begin
      {set widths according to the ratio}
      totalWidth := Dimensions.w - UnusableWidth;

      for i := 0 to (Columns.n - 1) do begin
         if(Columns.List[i].Ratio > 0) then
            Columns.List[i].Width := round(totalWidth * Columns.List[i].Ratio);
      end;

      {set any columns below minimum width to proper width, if they don't have a ratio}
      for i := 0 to (Columns.n - 1) do begin
         if(Columns.List[i].Ratio = 0) then begin
            if(Columns.List[i].Width < ColumnMinimumWidth) then
               Columns.List[i].Width := ColumnMinimumWidth;
         end;
      end;
   end;
end;

procedure wdgTGrid.OnColumnCountChange();
begin

end;

function wdgTGrid.GetGridItemCount(): loopint;
begin
   Result := GetItemCount();
end;

procedure wdgTGrid.SelectColumn(column: loopint);
begin
   ItemHighlightWidth := ItemDimensions.w;
   HighlightedItemX := column * ItemDimensions.w;
   SelectedItemX := HighlightedItemX;
end;

procedure wdgTGrid.NavigateToColumn(column: loopint; doUpdate: boolean);
var
   index: loopint;

begin
   if(column < 0) then
      column := 0;

   {no vertical item selected}
   if(SelectedItem < 0) then begin
      if(ItemCount > 0) then
         SelectNavigableItemFrom(0)
      else
         {no items, nothing to do}
         exit;

      {nothing can be selected}
      if(SelectedItem < 0) then
         exit;
   end;

   if(column >= 0) and (column < ItemsPerRow()) then begin
      index := GetItemIndex(SelectedItem, column);

      if(index < GetGridItemCount()) then begin
         SelectColumn(column);
         LastGridItemUnderPointer := GetItemIndex(SelectedItem, column);
         SelectedGridItem := LastGridItemUnderPointer;

         if(doUpdate) then
            ItemNavigated(SelectedGridItem);
      end;
   end;
end;

procedure wdgTGrid.ItemClicked(index: loopint; button: TBitSet);
begin
   inherited ItemClicked(index, button);

   SelectedGridItem := LastGridItemUnderPointer;

   if(GridMode) then
      GridItemClicked(SelectedGridItem, button)
   else
      GridItemClicked(SelectedItem, button);
end;

procedure wdgTGrid.ItemDoubleClicked(index: loopint; button: TBitSet);
begin
   inherited ItemDoubleClicked(index, button);

   SelectedGridItem := LastGridItemUnderPointer;

   if(GridMode) then
      GridItemDoubleClicked(SelectedGridItem, button)
   else
      GridItemDoubleClicked(SelectedItem, button);
end;

procedure wdgTGrid.GridItemClicked(index: loopint; button: TBitSet);
begin

end;

procedure wdgTGrid.GridItemDoubleClicked(index: loopint; button: TBitSet);
begin

end;

function wdgTGrid.GetItemUnderPointer(x, y: loopint; out offs: loopint): loopint;
var
   item, column: longint;

begin
   item := -1;
   Result := inherited GetItemUnderPointer(x, y, offs);

   if(GridMode) then begin
      column := (x div ItemDimensions.w);

      SelectColumn(column);
      if(column < ItemsPerRow()) then begin
         item := GetItemIndex(Result, column);

         if(item >= GetGridItemCount()) then begin
            item := -1;
            Result := -1;
         end;
      end else
         Result := -1;
   end;

   LastGridItemUnderPointer := item;
   LastItemUnderPointer := Result;
end;

procedure wdgTGrid.PositionChanged;
begin
   inherited;

   Assigned();
end;

procedure wdgTGrid.SizeChanged;
begin
   inherited;

   Assigned();
end;

procedure wdgTGrid.OnHover(index: loopint);
begin
   OnGridHover(LastGridItemUnderPointer);
end;

procedure wdgTGrid.OnGridHover(index: loopint);
begin
end;

procedure wdgTGrid.NavigationMoved();
var
   index,
   column,
   gridItems: loopint;

begin
   if(not GridMode) then
      exit;

   column := GetColumnFromSelected();
   gridItems := GetGridItemCount();

   NavigateToColumn(column, false);

   index := GetItemIndex(SelectedItem, column);
   if(index >= gridItems) then begin
      LastGridItemUnderPointer := gridItems - 1;
      SelectedGridItem := LastGridItemUnderPointer;

      column := GetColumnFromSelected();
      SelectColumn(column);
   end;
end;

procedure wdgTGrid.InternalItemsChanged();
begin
   LastGridItemUnderPointer := -1;
   SelectedGridItem := -1;
end;

{ wdgTGridGlobal }

function wdgTGridGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTGrid;
begin
   Result := wdgTGrid(uiWidget.Add(internal, Pos, Dim));
end;

{ wdgTStringGridGlobal }

function wdgTStringGridGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTStringGrid;
begin
   Result := wdgTStringGrid(uiWidget.Add(internal, Pos, Dim));
end;

procedure InitWidget();
begin
   internal.Instance := wdgTGrid;
   internal.Done();
end;

procedure InitStringWidget();
begin
   internalString.Instance := wdgTStringGrid;
   internalString.Done();
end;

INITIALIZATION
   internal.Register('widget.grid', @InitWidget);
   internal.Register('widget.stringgrid', @InitStringWidget);
END.
