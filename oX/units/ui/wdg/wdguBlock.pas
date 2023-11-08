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
   uiuWidget, uiWidgets, uiuDraw,
   wdguBase;


TYPE
   wdgTBlock = class(uiTWidget)
      procedure Render(); override;
   end;

   wdgTBlockGlobal = class(specialize wdgTBase<wdgTBlock>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgBlock: wdgTBlockGlobal;

IMPLEMENTATION

procedure initializeWidget();
begin
   wdgBlock.Internal.Instance := wdgTBlock;
   wdgBlock.Internal.Done();

   wdgBlock := wdgTBlockGlobal.Create(wdgBlock.Internal);
end;

procedure wdgTBlock.Render();
begin
   {set color or bind texture depending on if textures are available}
   SetColor(Color);

   uiDraw.Box(RPosition, Dimensions);
end;

INITIALIZATION
   wdgBlock.Internal.Register('widget.block', @initializeWidget);

END.
