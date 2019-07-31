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
   end;

VAR
   wdgBlock: wdgTBlockGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := wdgTBlock;
   internal.Done();

   wdgBlock := wdgTBlockGlobal.Create(internal);
end;

procedure wdgTBlock.Render();
begin
   {set color or bind texture depending on if textures are available}
   SetColor(Color);

   uiDraw.Box(RPosition, Dimensions);
end;

INITIALIZATION
   internal.Register('widget.block', @initializeWidget);

END.

