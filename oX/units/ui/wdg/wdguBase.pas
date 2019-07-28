{
   wdguBase, base functionality and helpers for widgets
   Copyright (C) 2019. Dejan Boras

   Started On:    28.07.2019.
}

{$INCLUDE oxdefines.inc}
UNIT wdguBase;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWidget, uiWidgets, uiuWindow;

TYPE

   { wdgTBase }

   wdgTBase = class
      public
      pInternal: uiPWidgetClass;

      constructor Create(var selfInternal: uiTWidgetClass);

      function Add(const Pos: oxTPoint; const Dim: oxTDimensions): uiTWidget;
      function Add(): uiTWidget;

      protected
      {called when adding is done}
      function AddDone(wdg: uiTWidget): uiTWidget;
   end;

IMPLEMENTATION

{ wdgTBase }

constructor wdgTBase.Create(var selfInternal: uiTWidgetClass);
begin
   pInternal := @selfInternal;
end;

function wdgTBase.Add(const Pos: oxTPoint; const Dim: oxTDimensions): uiTWidget;
begin
  Result := uiWidget.Add(pInternal^, Pos, Dim);
end;

function wdgTBase.Add(): uiTWidget;
begin
  Result := Add(uiWidget.LastRect.BelowOf(), oxNullDimensions);
end;

function wdgTBase.AddDone(wdg: uiTWidget): uiTWidget;
begin
   if(wdg <> nil) then
      wdg.AutoSize();

   Result := wdg;
end;

END.
