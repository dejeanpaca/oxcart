{
   uiuBase, UI base setup
   Copyright (C) 2019. Dejan Boras

   Started On:    04.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuBase;

INTERFACE

   USES
      uLog, udvars,
      oxuRunRoutines,
      uiuSkinTypes;

TYPE
   { uiTBase }

   uiTBase = record
      {ui is initialized and ready}
      Initialized,
      {ui started initialization (if false it means it never attempted to initialize)}
      StartedInitialization: boolean;

      {standard internal skin}
      StandardSkin: uiTSkin;
      {default skin}
      DefaultSkin: uiTSkin;

      { skins }
      nSkins: longint;
      Skins: array of uiTSkin;

      {initialization procedures}
      BaseInitializationProcs,
      InitializationProcs: oxTRunRoutines;

      {group for ui settings}
      dvg: TDVarGroup;

      procedure Initialize();
      procedure DeInitialize();

      procedure BaseInitialize();
      procedure BaseDeInitialize();
   end;

VAR
   ui: uiTBase;

IMPLEMENTATION

procedure uiTBase.Initialize();
begin
   InitializationProcs.iCall();
end;

procedure uiTBase.DeInitialize();
begin
   InitializationProcs.dCall();
end;

procedure uiTBase.BaseInitialize();
begin
   StartedInitialization := true;
   BaseInitializationProcs.iCall();

   log.i('Initialized UI');
end;

procedure uiTBase.BaseDeInitialize();
begin
   if(StartedInitialization) then begin
      StartedInitialization := false;

      {de-initialize UI}
      BaseInitializationProcs.dCall();

      log.i('Deinitialized UI');
   end;
end;

INITIALIZATION

END.
