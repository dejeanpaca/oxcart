{
   uiuInitialize, UI initialization
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$INCLUDE oxdefines.inc}
UNIT uiuInitialize;

INTERFACE

   USES
      uiuSkinTypes;

TYPE
   { uiTInitialization }

   uiTInitialization = record
      {ui is initialized and ready}
      Initialized,
      {ui started initialization (if false it means it never attempted to initialize)}
      StartedInitialization,

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
   uiInitialization: uiTInitialization;

IMPLEMENTATION

procedure uiTInitialization.Initialize();
begin
   InitializationProcs.iCall();
end;

procedure uiTInitialization.DeInitialize();
begin
   InitializationProcs.dCall();
end;

procedure uiTInitialization.BaseInitialize();
begin
   oxui.StartedInitialization := true;
   oxui.BaseInitializationProcs.iCall();

   log.i('Initialized UI');
end;

procedure uiTInitialization.BaseDeInitialize();
begin
   if(StartedInitialization) then begin
      StartedInitialization := false;

      {de-initialize UI}
      oxui.BaseInitializationProcs.dCall();

      log.i('Deinitialized UI');
   end;
end;

INITIALIZATION

END.
