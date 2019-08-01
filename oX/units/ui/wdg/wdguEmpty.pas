{
   wdguEmopty, empty widget
   Copyright (C) 2011. Dejan Boras

   Started On:    05.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguEmpty;

INTERFACE

   USES
   {oX}
   oxuTypes,
   {ui}
   uiuWidget, uiWidgets, wdguBase;

TYPE
   wdgTEmptyGlobal = class(specialize wdgTBase<uiTWidget>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgEmpty: wdgTEmptyGlobal;

IMPLEMENTATION

procedure initializeWidget();
begin
   wdgEmpty.Internal.Done(uiTWidget);

   wdgEmpty := wdgTEmptyGlobal.Create(wdgEmpty.Internal);
end;

INITIALIZATION
   wdgEmpty.Internal.Register('widget.empty', @initializeWidget);

END.
