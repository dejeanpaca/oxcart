{
   wdguToolbar, bar to place widgets on
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguToolbar;

INTERFACE

   USES
      uStd, appuEvents, appuActionEvents, appuMouse, uColors, uTiming, vmVector,
      {oX}
      oxuUI, oxuTypes, oxuTexture, oxuFont, oxuRenderUtilities, oxuRender, oxuTransform, oxuResourcePool,
      {ui}
      uiuTypes, uiuControl, uiuWindowTypes, uiuSkinTypes, uiuDraw,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuDrawUtilities,
      wdguBase, wdguWorkbar;

CONST
   wdgscTOOLBAR_REGULAR = 0;
   wdgscTOOLBAR_REGULAR_DISABLED = 1;
   wdgscTOOLBAR_HIGHLIGHT = 2;
   wdgscTOOLBAR_ACTIVATED = 3;

   wdgToolbarSkinColorDescriptor: array[0..3] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'regular';
         Color: (255, 255, 255, 255)
      ),
      (
         Name: 'regular_disabled';
         Color: (127, 127, 127, 255)
      ),
      (
         Name: 'highlight';
         Color: (192, 192, 255, 255)
      ),
      (
         Name: 'activated';
         Color: (230, 160, 63, 255)
      )
   );

   WDG_TOOLBAR_ITEM_BUTTON_RATIO = 0.9;

TYPE
   wdgTToolbarItemType = (
      WDG_TOOLBAR_ITEM_BUTTON,
      WDG_TOOLBAR_ITEM_CAPTION,
      WDG_TOOLBAR_ITEM_SEPARATOR
   );

   wdgTToolbarItemProperty = (
      WDG_TOOLBAR_ITEM_ENABLED,
      WDG_TOOLBAR_ITEM_SPIN,
      WDG_TOOLBAR_ITEM_HIGHLIGHTABLE,
      {when a toolbar item is activated}
      WDG_TOOLBAR_ITEM_ACTIVE
   );

   wdgTToolbarItemProperties = set of wdgTToolbarItemProperty;

   wdgPToolbarItem = ^wdgTToolbarItem;

   { wdgTToolbarItem }

   wdgTToolbarItem = record
      Name,
      Hint,
      Caption: StdString;

      Action: TEventID;
      Callback: uiTWidgetCallback;

      Typ: wdgTToolbarItemType;
      Glyph: oxTTexture;

      Color: TColor4ub;

      RelativePosition,
      Size: loopint;

      Properties: wdgTToolbarItemProperties;
      Parent: uiTControl;

      {spin speed}
      SpinSpeed: single;

      procedure Enable(setEnable: boolean = true);
      procedure Activate(setActive: boolean = true);
      procedure SetSpin(spin: boolean = true);
      procedure SetHighlightable(highligtable: boolean = true);
      procedure SetHint(const newHint: StdString);
   end;

   wdgTToolbarItems = specialize TSimpleList<wdgTToolbarItem>;

   { wdgTToolbar }

   wdgTToolbar = class(wdgTWorkbar)
      Items: wdgTToolbarItems;
      SeparationWidth,
      HighlightedItem,
      ItemPressed: loopint;

      Vertical,
      {if true, do not render the background}
      Transparent: boolean;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Render(); override;
      procedure Hover(x, y: longint; what: uiTHoverEvent); override;
      procedure Point(var e: appTMouseEvent; x, y: longint); override;
      procedure Update(); override;

      function AddItem(): wdgPToolbarItem;
      function AddSeparator(): wdgPToolbarItem;
      function AddButton(glyph: oxTTexture; newAction: TEventID = 0; callback: TProcedure = nil): wdgPToolbarItem;
      function AddButton(glyph: oxTTexture; newAction: TEventID; callback: TObjectProcedure): wdgPToolbarItem;
      function AddButton(glyph: oxTTexture; newAction: TEventID; callback: uiTWidgetCallbackRoutine): wdgPToolbarItem;
      function AddButton(glyph: oxTTexture; newAction: TEventID; callback: uiTWidgetObjectCallbackRoutine): wdgPToolbarItem;
      function AddCaption(const newCaption: StdString; newAction: TEventID = 0; callback: TProcedure = nil): wdgPToolbarItem;

      function FindItemIndexByAction(actionId: TEventID): loopint;
      function FindItemByAction(actionId: TEventID): wdgPToolbarItem;

      procedure RemoveItem(item: wdgPToolbarItem);
      procedure RemoveItem(index: loopint);

      procedure GetComputedDimensions(out d: oxTDimensions); override;

      procedure ParentSizeChange(); override;
      procedure SizeChanged(); override;

      {enable/disable all items}
      procedure EnableItems(setEnable: boolean);
      {should be called if you change an item}
      procedure ItemChanged();

      protected
         TotalWidth: loopint;
         {true if a hint was changed on the currently highlighted item}
         HintChanged: boolean;

         {tells what the mouse is over}
         function MouseOver(px, py: longint): longint;
         procedure Recalculate();
         procedure ButtonDo(const item: wdgTToolbarItem);
         procedure OnHintChanged(); override;
   end;

   { wdgTToolbarGlobal }

   wdgTToolbarGlobal = object(specialize wdgTBase<wdgTToolbar>)
      {default height}
      Height: longint; static;

      function Add(wnd: uiTWindow; vertical: boolean = false): wdgTToolbar;
      function Add(vertical: boolean = false): wdgTToolbar;
   end;

VAR
   wdgToolbar: wdgTToolbarGlobal;

IMPLEMENTATION

{ wdgTToolbarItem }

procedure wdgTToolbarItem.Enable(setEnable: boolean);
begin
   if(setEnable) then
      Properties := Properties + [WDG_TOOLBAR_ITEM_ENABLED]
   else
      Properties := Properties - [WDG_TOOLBAR_ITEM_ENABLED];
end;

procedure wdgTToolbarItem.Activate(setActive: boolean);
begin
   if(setActive) then
      Include(Properties, WDG_TOOLBAR_ITEM_ACTIVE)
   else
      Exclude(Properties, WDG_TOOLBAR_ITEM_ACTIVE);
end;

procedure wdgTToolbarItem.SetSpin(spin: boolean);
begin
   if(spin) then
      Include(Properties, WDG_TOOLBAR_ITEM_SPIN)
   else
      Exclude(Properties, WDG_TOOLBAR_ITEM_SPIN);
end;

procedure wdgTToolbarItem.SetHighlightable(highligtable: boolean);
begin
   if(highligtable) then
      Include(Properties, WDG_TOOLBAR_ITEM_HIGHLIGHTABLE)
   else
      Exclude(Properties, WDG_TOOLBAR_ITEM_HIGHLIGHTABLE);
end;

procedure wdgTToolbarItem.SetHint(const newHint: StdString);
begin
   Hint := newHint;
   wdgTToolbar(Parent).HintChanged := true;
end;

{ wdgTToolbar }

constructor wdgTToolbar.Create();
begin
   inherited;

   SetPadding(2);

   SeparationWidth := 3;
   Height := wdgToolbar.Height;
   HighlightedItem := -1;
   ItemPressed := -1;

   Items.InitializeValues(Items);
end;

destructor wdgTToolbar.Destroy();
var
   i: loopint;

begin
   inherited Destroy;

   for i := 0 to Items.n - 1 do begin
      oxResource.Destroy(Items.List[i].Glyph);
   end;

   Items.Dispose();
end;

procedure wdgTToolbar.Render();
var
   px,
   py,
   x,
   y,
   x2,
   y2,
   i,
   size,
   center: loopint;

   f: oxTFont;
   m: TMatrix4f;

   rotation: single;

procedure SetupColor(const item: wdgTToolbarItem);
begin
   if((wdgpENABLED in Properties) and (WDG_TOOLBAR_ITEM_ENABLED in item.Properties)) then begin
      if((HighlightedItem <> i) or (not (WDG_TOOLBAR_ITEM_HIGHLIGHTABLE in item.Properties))) then begin
         if(not (WDG_TOOLBAR_ITEM_ACTIVE in item.Properties)) then
            SetColorBlended(item.Color)
         else
            SetColorBlended(wdgscTOOLBAR_ACTIVATED);
      end else
         SetColorBlended(wdgscTOOLBAR_HIGHLIGHT)
   end else
      SetColorBlended(wdgscTOOLBAR_REGULAR_DISABLED);
end;

begin
   rotation := 0;
   if(not Transparent) then
      inherited;

   if(Items.n = 0) then
      exit;

   {first render images}
   oxRender.BlendDefault();

   for i := 0 to Items.n - 1 do begin
      if(Items.List[i].Typ = WDG_TOOLBAR_ITEM_BUTTON) and (Items.List[i].Glyph <> nil) and (Items.List[i].Glyph.rId <> 0) then begin
         size := round(Items.List[i].Size * WDG_TOOLBAR_ITEM_BUTTON_RATIO);

         if(not Vertical) then begin
            px := RPosition.x + Items.List[i].RelativePosition;
            py := RPosition.y - ((Dimensions.h - Items.List[i].Size) div 2);
         end else begin
            px := RPosition.x + ((Dimensions.w - Items.List[i].Size) div 2);
            py := RPosition.y - Items.List[i].RelativePosition;
         end;

         SetupColor(Items.List[i]);

         if(not (WDG_TOOLBAR_ITEM_SPIN in Items.List[i].Properties)) then begin
            uiDrawUtilities.Glyph(px, py, size, size, Items.List[i].Glyph);
         end else begin
            m := oxTransform.Matrix;

            rotation := - (360 * ((timer.Cur() mod 1000) / 1000)) * Items.List[i].SpinSpeed;

            oxTransform.Identity();
            oxTransform.Translate(px + size / 2, py - size / 2, 0);
            oxTransform.RotateZ(rotation);
            oxTransform.Apply();

            oxRenderUtilities.TexturedQuad(0, 0, size / 2, size / 2, Items.List[i].Glyph);

            oxTransform.Apply(m);
         end
      end;
   end;

   uiDraw.ClearTexture();

   {render separators}
   for i := 0 to Items.n - 1 do begin
      if(Items.List[i].Typ = WDG_TOOLBAR_ITEM_SEPARATOR) then begin
         if(not Vertical) then begin
            x := RPosition.x + Items.List[i].RelativePosition + (Items.List[i].Size div 2);
            y := RPosition.y - PaddingTop;
            y2 := RPosition.y - Dimensions.h + 1 + PaddingBottom;

            uiDrawUtilities.VerticalDivisorSunken(uiTWindow(wnd), x, y, y2, Color);
         end else begin
            x := RPosition.x + PaddingLeft;
            x2 := RPosition.x + Dimensions.w - 1 - PaddingRight;
            y := RPosition.y - Items.List[i].RelativePosition - (Items.List[i].Size div 2);

            uiDrawUtilities.HorizontalDivisorSunken(uiTWindow(wnd), x, y, x2, Color);
         end;
      end;
   end;

   {render captions}
   f := CachedFont;
   f.Start();

   if(not Vertical) then
      center := RPosition.y - ((Dimensions.h - f.GetHeight()) div 2)
   else
      center := RPosition.x + ((Dimensions.w -  f.GetHeight()) div 2);

   // TODO: Support for vertical text

   for i := 0 to Items.n - 1 do begin
      if(Items.List[i].Typ = WDG_TOOLBAR_ITEM_CAPTION) then begin
         SetupColor(Items.List[i]);

         if(not Vertical) then
            f.Write(RPosition.x + Items.List[i].RelativePosition, center - f.GetHeight(), Items.List[i].Caption)
         else
            f.Write(center, RPosition.y - Items.List[i].RelativePosition, Items.List[i].Caption);
      end;
   end;

   oxf.Stop();
end;

procedure wdgTToolbar.Hover(x, y: longint; what: uiTHoverEvent);
begin
   if(what <> uiHOVER_NO) then begin
      HighlightedItem := MouseOver(x, y);
   end else
      HighlightedItem := -1;

   OnHintChanged();
end;

procedure wdgTToolbar.Point(var e: appTMouseEvent; x, y: longint);
var
   item: loopint;

begin
   if(wdgpENABLED in Properties) then begin
      item := MouseOver(x, y);

      if(item > -1) then begin
         {left button is released}
         if(e.Action = appmcRELEASED) and (e.Button = appmcLEFT) then begin
            if(ItemPressed = item) then
               ButtonDo(Items.List[item])
         {left button pressed}
         end else if(e.Action = appmcPRESSED) and (e.Button = appmcLEFT) then
            ItemPressed := item;
      end;
   end;
end;

procedure wdgTToolbar.Update();
begin
   if(HintChanged) then begin
      if(HighlightedItem > -1) then begin
         Hint := Items.List[HighlightedItem].Hint;
      end;

      HintChanged := false;
   end;
end;

function wdgTToolbar.AddItem(): wdgPToolbarItem;
var
   item: wdgTToolbarItem;

begin
   ZeroOut(item, SizeOf(item));

   item.Parent := Self;
   item.Properties := [WDG_TOOLBAR_ITEM_ENABLED, WDG_TOOLBAR_ITEM_HIGHLIGHTABLE];
   item.Color := GetColor(wdgscTOOLBAR_REGULAR);
   item.SpinSpeed := 1;

   Items.Add(item);

   Result := @Items.List[Items.n -1];
end;

function wdgTToolbar.AddSeparator(): wdgPToolbarItem;
begin
   Result := AddItem();
   Result^.Typ := WDG_TOOLBAR_ITEM_SEPARATOR;

   Recalculate();
end;

function wdgTToolbar.AddButton(glyph: oxTTexture; newAction: TEventID; callback: TProcedure): wdgPToolbarItem;
begin
   Result := AddItem();
   Result^.Typ := WDG_TOOLBAR_ITEM_BUTTON;
   Result^.Action := newAction;
   Result^.Glyph := glyph;
   Result^.Callback.Use(callback);

   if(glyph <> nil) then
      glyph.MarkUsed();

   Recalculate();
end;

function wdgTToolbar.AddButton(glyph: oxTTexture; newAction: TEventID; callback: TObjectProcedure): wdgPToolbarItem;
begin
   Result := AddButton(glyph, newAction, TProcedure(nil));
   Result^.Callback.Use(callback);
end;

function wdgTToolbar.AddButton(glyph: oxTTexture; newAction: TEventID; callback: uiTWidgetCallbackRoutine): wdgPToolbarItem;
begin
   Result := AddButton(glyph, newAction, TProcedure(nil));
   Result^.Callback.Use(callback);
end;

function wdgTToolbar.AddButton(glyph: oxTTexture; newAction: TEventID; callback: uiTWidgetObjectCallbackRoutine): wdgPToolbarItem;
begin
   Result := AddButton(glyph, newAction, TProcedure(nil));
   Result^.Callback.Use(callback);
end;

function wdgTToolbar.AddCaption(const newCaption: StdString; newAction: TEventID; callback: TProcedure = nil): wdgPToolbarItem;
begin
   Result := AddItem();
   Result^.Typ := WDG_TOOLBAR_ITEM_CAPTION;
   Result^.Caption := newCaption;
   Result^.Action := newAction;
   Result^.Callback.Use(callback);

   Recalculate();
end;

function wdgTToolbar.FindItemIndexByAction(actionId: TEventID): loopint;
var
   i: loopint;

begin
   if(actionId > 0) then begin
      for i := 0 to Items.n - 1 do begin
         if(Items.List[i].Action = actionId) then
            exit(i);
      end;
   end;

   Result := -1;
end;

function wdgTToolbar.FindItemByAction(actionId: TEventID): wdgPToolbarItem;
var
   index: loopint;

begin
   index := FindItemIndexByAction(actionId);

   if(index > -1) then
      Result := @Items.List[index]
   else
      Result := nil;
end;

procedure wdgTToolbar.RemoveItem(item: wdgPToolbarItem);
var
   i: loopint;

begin
   for i := 0 to Items.n - 1 do begin
      if(@Items.List[i] = item) then
         RemoveItem(i);
   end;
end;

procedure wdgTToolbar.RemoveItem(index: loopint);
begin
   if(index >= 0) and (index < Items.n) then begin
      Items.Remove(index);
      ItemChanged();
   end;
end;

procedure wdgTToolbar.GetComputedDimensions(out d: oxTDimensions);
begin
   Recalculate();

   d.h := Height;
   d.w := TotalWidth;
end;

procedure wdgTToolbar.Recalculate();
var
   i: loopint;
   itemSize: loopint = 0;
   relativePosition: loopint;
   f: oxTFont;

begin
   f := CachedFont;

   TotalWidth := 0;
   if(not Vertical) then begin
      relativePosition := PaddingLeft;
      itemSize := Height - (PaddingTop + PaddingBottom);
   end else begin
      relativePosition := PaddingTop;
      itemSize := Height - (PaddingLeft + PaddingRight);
   end;

   for i := 0 to (Items.n - 1) do begin
      Items.List[i].RelativePosition := relativePosition;
      Items.List[i].Size := itemSize;

      if(Items.List[i].Typ = WDG_TOOLBAR_ITEM_SEPARATOR) then
         Items.List[i].Size := 6
      else if(Items.List[i].Typ = WDG_TOOLBAR_ITEM_CAPTION) then
         Items.List[i].Size := f.GetLength(Items.List[i].Caption);

      inc(relativePosition, SeparationWidth + Items.List[i].Size);
   end;

   TotalWidth := relativePosition;
end;

procedure wdgTToolbar.ButtonDo(const item: wdgTToolbarItem);
begin
   if(not ((wdgpENABLED in Properties) and (WDG_TOOLBAR_ITEM_ENABLED in item.Properties))) then
      exit;

   if(wdgpENABLED in Properties) then begin
      {queue an action event if one is assigned}
      if(item.Action <> 0) then
         appActionEvents.Queue(item.Action, 0, wnd);
   end;

   {clear the pressed state}
   ItemPressed := -1;

   {call the callback last, in case the callback destroys the widget or container}
   if(wdgpENABLED in Properties) then
      item.Callback.Call(Self);
end;

procedure wdgTToolbar.OnHintChanged();
begin
   inherited OnHintChanged();

   if(HighlightedItem > -1) then
      Hint := Items.List[HighlightedItem].Hint
   else
      Hint := '';
end;

procedure wdgTToolbar.ParentSizeChange();
begin
   inherited ParentSizeChange;

   Recalculate();
end;

procedure wdgTToolbar.SizeChanged();
begin
   inherited SizeChanged;

   Recalculate();
end;

procedure wdgTToolbar.EnableItems(setEnable: boolean);
var
   i: loopint;

begin
   for i := 0 to Items.n - 1 do begin
      Items.List[i].Enable(setEnable);
   end;
end;

procedure wdgTToolbar.ItemChanged();
begin
   Recalculate();
end;

function wdgTToolbar.MouseOver(px, py: longint): longint;
var
   pos,
   i,
   rPos,
   size: loopint;

begin
   if(not Vertical) then
      pos := px
   else
      pos := py;

   for i := 0 to Items.n - 1 do begin
      rPos := Items.List[i].RelativePosition;
      size := Items.List[i].Size;

      if(not Vertical) then begin
         if((pos >= rPos) and (pos < rPos + size)) then
            exit(i);
      end else begin
         rPos := Dimensions.h - rPos;

         if((pos <= rPos) and (pos > rPos - size)) then
            exit(i);
      end;
   end;

   Result := -1;
end;


{ wdgTToolbarGlobal }

function wdgTToolbarGlobal.Add(wnd: uiTWindow; vertical: boolean = false): wdgTToolbar;
begin
   uiWidget.SetTarget(wnd);
   Result := Add(vertical);
end;

function wdgTToolbarGlobal.Add(vertical: boolean = false): wdgTToolbar;
begin
   Result := inherited Add(oxNullPoint, oxNullDimensions);

   Result.Vertical := vertical;
   Result.AutoPositionTarget := wdgWORKBAR_POSITION_TOP;
   Result.AutoPosition();
   Result.Recalculate();
end;

procedure init();
begin
   wdgToolbar.Internal.Done(wdgTToolbar);
end;

INITIALIZATION
   wdgToolbar.Create();
   wdgToolbar.Height := wdgWORKBAR_HEIGHT;

   wdgToolbar.Internal.Register('toolbar', @init);
   wdgToolbar.Internal.SkinDescriptor.UseColors(wdgToolbarSkinColorDescriptor);

END.
