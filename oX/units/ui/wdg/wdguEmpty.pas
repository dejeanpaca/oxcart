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
   wdgTEmptyGlobal = class(specialize wdgTBase<uiTWidget>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgEmpty: wdgTEmptyGlobal;

IMPLEMENTATION

procedure init();
begin
   wdgEmpty.Internal.Done(uiTWidget);

   wdgEmpty := wdgTEmptyGlobal.Create(wdgEmpty.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgEmpty);
end;

INITIALIZATION
   wdgEmpty.Internal.Register('widget.empty', @init, @deinit);

END.
