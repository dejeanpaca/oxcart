{
   wdguBlock, block widget, gives a block surface
   Copyright (C) 2011. Dejan Boras

   Started On:    26.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguBlock;

INTERFACE

   USES
   {oX}
   oxuTypes,
   {ui}
   uiuWidget, uiWidgets, uiuDraw;


TYPE
   wdgTBlock = class(uiTWidget)
      procedure Render(); override;
   end;

   uiTWidgetBlockGlobal = record
     function Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTBlock;
   end;

VAR
   wdgBlock: uiTWidgetBlockGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := wdgTBlock;
   internal.Done();
end;

procedure wdgTBlock.Render();
begin
   {set color or bind texture depending on if textures are available}
   SetColor(Color);

   uiDraw.Box(RPosition, Dimensions);
end;

function uiTWidgetBlockGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTBlock;
begin
   result := wdgTBlock(uiWidget.Add(internal, Pos, Dim));
end;

INITIALIZATION
   internal.Register('widget.block', @initializeWidget);

END.

