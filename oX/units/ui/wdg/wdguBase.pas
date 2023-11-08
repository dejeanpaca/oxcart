{
   wdguBase, base functionality and helpers for widgets
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguBase;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWidget, uiWidgets, uiuWindow, uiuRegisteredWidgets;

TYPE

   { wdgTBase }

   generic wdgTBase<T> = object
      public
      Internal: uiTWidgetClass;

      constructor Create(const name: StdString);

      function Add(const Pos: oxTPoint; const Dim: oxTDimensions): T;
      function Add(const Pos: oxTPoint): T;
      function Add(): T;

      protected
      function AddInternal(const Pos: oxTPoint; const Dim: oxTDimensions): T;
      function AddInternal(const Pos: oxTPoint): T;
      function AddInternal(): T;

      {called when adding is done}
      function AddDone(wdg: T): T;

      {called after a a widget is created}
      procedure OnCreate({%H-}wdg: T); virtual;
      procedure OnAdd({%H-}wdg: T); virtual;
   end;

IMPLEMENTATION

{ wdgTBase }

constructor wdgTBase.Create(const name: StdString);
begin
   Internal.Register(name, T);
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

function wdgTBase.Add(): T;
begin
   Result := AddInternal();

   if(Result <> nil) then
      AddDone(Result);
end;

function wdgTBase.AddInternal(const Pos: oxTPoint; const Dim: oxTDimensions): T;
begin
  Result := T(uiWidget.Add(Internal, Pos, Dim));

  if(Result <> nil) then
     OnCreate(Result);
end;

function wdgTBase.AddInternal(const Pos: oxTPoint): T;
begin
   Result := T(uiWidget.Add(Internal, Pos, oxNullDimensions));

   if(Result <> nil) then
      OnCreate(Result);
end;

function wdgTBase.AddInternal(): T;
begin
  Result := AddInternal(uiWidget.LastRect.BelowOf(), oxNullDimensions);

  if(Result <> nil) then
     OnCreate(Result);
end;

function wdgTBase.AddDone(wdg: T): T;
begin
   if(wdg <> nil) then
      uiTWidget(wdg).AutoSize();

   OnAdd(wdg);

   Result := wdg;
end;

procedure wdgTBase.OnCreate(wdg: T);
begin
end;

procedure wdgTBase.OnAdd(wdg: T);
begin
end;

END.
