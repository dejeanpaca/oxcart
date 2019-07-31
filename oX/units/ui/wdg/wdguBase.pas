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

   generic wdgTBase<T> = class
      public
      pInternal: uiPWidgetClass;

      constructor Create(var selfInternal: uiTWidgetClass);

      function Add(const Pos: oxTPoint; const Dim: oxTDimensions): T;
      function Add(const Pos: oxTPoint): T;

      protected
      function AddInternal(const Pos: oxTPoint; const Dim: oxTDimensions): T;
      function AddInternal(const Pos: oxTPoint): T;
      function AddInternal(): T;

      {called when adding is done}
      function AddDone(wdg: uiTWidget): T;
   end;

IMPLEMENTATION

{ wdgTBase }

constructor wdgTBase.Create(var selfInternal: uiTWidgetClass);
begin
   pInternal := @selfInternal;
end;

function wdgTBase.Add(const Pos: oxTPoint; const Dim: oxTDimensions): T;
begin
   Result := AddInternal(Pos, Dim);

   if(Result <> nil) then
      AddDone(Result);
end;

function wdgTBase.Add(const Pos: oxTPoint): T;
begin
   Result := AddInternal(Pos, oxNullDimensions);

   if(Result <> nil) then
      AddDone(Result);
end;

function wdgTBase.AddInternal(const Pos: oxTPoint; const Dim: oxTDimensions): T;
begin
  Result := T(uiWidget.Add(pInternal^, Pos, Dim));
end;

function wdgTBase.AddInternal(const Pos: oxTPoint): T;
begin
   Result := T(uiWidget.Add(pInternal^, Pos, oxNullDimensions))
end;

function wdgTBase.AddInternal(): T;
begin
  Result := AddInternal(uiWidget.LastRect.BelowOf(), oxNullDimensions);
end;

function wdgTBase.AddDone(wdg: uiTWidget): T;
begin
   if(wdg <> nil) then
      wdg.AutoSize();

   Result := T(wdg);
end;

END.
