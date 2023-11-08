{
   wdguEmpty, empty widget
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguEmpty;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets,
      wdguBase;

TYPE
   wdgTEmptyGlobal = object(specialize wdgTBase<uiTWidget>)
   end;

VAR
   wdgEmpty: wdgTEmptyGlobal;

IMPLEMENTATION

procedure init();
begin
   wdgEmpty.Internal.Done(uiTWidget);
end;

INITIALIZATION
   wdgEmpty.Create();
   wdgEmpty.Internal.Register('empty', @init);

END.
