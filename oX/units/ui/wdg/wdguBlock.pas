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

   wdgTBlockGlobal = class(specialize wdgTBase<wdgTBlock>)
      Internal: uiTWidgetClass; static;
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

procedure init();
begin
   wdgBlock.Internal.Done(wdgTBlock);

   wdgBlock := wdgTBlockGlobal.Create(wdgBlock.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgBlock);
end;

INITIALIZATION
   wdgBlock.Internal.Register('widget.block', @init, @deinit);

END.
