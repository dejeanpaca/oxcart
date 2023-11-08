{
   wdguBlock, block widget, gives a block surface
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguBlock;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, uiuDraw, uiuRegisteredWidgets,
      wdguBase;


TYPE
   wdgTBlock = class(uiTWidget)
      procedure Render(); override;
   end;

   wdgTBlockGlobal = object(specialize wdgTBase<wdgTBlock>)
   end;

VAR
   wdgBlock: wdgTBlockGlobal;

IMPLEMENTATION

procedure wdgTBlock.Render();
begin
   {set color or bind texture depending on if textures are available}
   SetColor(Color);

   uiDraw.Box(RPosition, Dimensions);
end;


INITIALIZATION
   wdgBlock.Create('block');

END.
