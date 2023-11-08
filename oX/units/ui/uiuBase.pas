{
   uiuBase, UI base setup
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuBase;

INTERFACE

   USES
      uLog, udvars,
      {ox}
      oxuRunRoutines;

TYPE
   { uiTBase }

   uiTBase = record
      {ui is initialized and ready}
      Initialized,
      {ui started initialization (if false it means it never attempted to initialize)}
      StartedInitialization: boolean;

      {initialization procedures}
      BaseInitializationProcs,
      WidgetInitializationProcs,
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

   WidgetInitializationProcs.iCall();

   log.i('Initialized UI');
end;

procedure uiTBase.BaseDeInitialize();
begin
   if(StartedInitialization) then begin
      StartedInitialization := false;

      WidgetInitializationProcs.dCall();

      {de-initialize UI}
      BaseInitializationProcs.dCall();

      log.i('Deinitialized UI');
   end;
end;

INITIALIZATION
   {initialization procedures}
   oxTRunRoutines.Initialize(ui.BaseInitializationProcs, 'ui.Base');
   oxTRunRoutines.Initialize(ui.WidgetInitializationProcs, 'ui.Widget');
   oxTRunRoutines.Initialize(ui.InitializationProcs, 'ui.Initialization');

END.
