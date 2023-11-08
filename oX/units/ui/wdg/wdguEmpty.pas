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
   uiuWidget, uiWidgets;


TYPE
   uiTWidgetEmptyGlobal = record
      function Add(const Pos: oxTPoint; const Dim: oxTDimensions): uiTWidget;
   end;

VAR
   wdgEmpty: uiTWidgetEmptyGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := uiTWidget;
   internal.Done();
end;

function uiTWidgetEmptyGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions): uiTWidget;
begin
   Result := uiWidget.Add(internal, Pos, Dim);
end;

INITIALIZATION
   internal.Register('widget.empty', @initializeWidget);

END.
