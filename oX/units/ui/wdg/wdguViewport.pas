{
   wdguViewport, widget with its own rendering viewport
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguViewport;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase;

TYPE
   wdgTViewport = class(uiTWidget)
   end;

   wdgTViewportGlobal = class(specialize wdgTBase<wdgTViewport>)
     Internal: uiTWidgetClass; static;
   end;


VAR
   wdgViewport: wdgTViewportGlobal;

IMPLEMENTATION

procedure init();
begin
   wdgViewport.internal.Done(wdgTViewport);

   wdgViewport := wdgTViewportGlobal.Create(wdgViewport.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgViewport);
end;

INITIALIZATION
   wdgViewport.Internal.Register('widget.viewport', @init, @deinit);

END.
