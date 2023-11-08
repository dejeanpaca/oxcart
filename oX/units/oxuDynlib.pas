{
   oxuDynlib, base unit for dynamic libraries
   Copyright (c) 2017. Dejan Boras

   Started On:    04.06.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDynlib;

INTERFACE

   USES
      sysutils, uLog, uStd, ParamUtils,
      {app}
      uAppInfo, uApp,
      {ox}
      uOX, oxuGlobalInstances, oxuInit, oxuRun;

TYPE
   { oxTLibrary }

   oxTLibrary = class
      Name: string;
      GlobalInstances: oxTGlobalInstances;
      LibraryInstances: oxTGlobalInstances;
      ErrorState: boolean;

      constructor Create; virtual;

      function Initialize(): boolean; virtual;
      function Start(): boolean; virtual;
      procedure Deinitialize(); virtual;

      {get application info}
      function GetAppInfo(): appPInfo; virtual;
      {get application info}
      function IsAppActive(): boolean; virtual;
      {set custom run parameters}
      procedure SetParameters(var params: TStringArray); virtual;

      procedure Run(); virtual;
   end;

   oxTLibraryLoadRoutine = function(): oxTLibrary;
   oxTLibraryUnloadRoutine = TProcedure;
   oxTLibraryRunRoutine = TProcedure;
   oxTLibraryVersionRoutine = function(): string;

function ox_library_load(): oxTLibrary;
procedure ox_library_unload();
function ox_library_version(): string;

IMPLEMENTATION

VAR
   oxLibrary: oxTLibrary;

function ox_library_load(): oxTLibrary;
begin
   stdlog.LogEndTimeDate := false;
   oxLibrary := oxTLibrary.Create();
   oxLibrary.LibraryInstances := oxuGlobalInstances.oxGlobalInstances;

   result := oxLibrary;
end;

procedure ox_library_unload;
begin
   FreeObject(oxLibrary);

   log.v('ox library unloaded');
end;

function ox_library_version: string;
begin
   result := '2';
end;

{ oxTLibrary }

constructor oxTLibrary.Create;
begin
   {$IFDEF OX_LIBRARY}
   Name := 'oxlibrary'
   {$ELSE}
   Name := 'ox'
   {$ENDIF}
end;

function oxTLibrary.Initialize(): boolean;
begin
   ErrorState := false;

   {$IFDEF OX_LIBRARY}
   log.w('ox library initialize start');
   {$ENDIF}
   consoleLog.LogEndTimeDate := false;

   if(GlobalInstances <> nil) then begin
      GlobalInstances.CopyOverReferences(oxuGlobalInstances.oxGlobalInstances);
      oxExternalGlobalInstances := Self.GlobalInstances;

      oxRun.Initialize();

      exit(ox.Initialized);
   end else
      log.e('ox library global instances reference not set');

   result := false;
end;

function oxTLibrary.Start(): boolean;
begin
   if(ox.Initialized) then begin
      log.i('ox library initialized');

      oxRun.Start();
   end;

   Result := ox.Initialized;
end;

procedure oxTLibrary.Deinitialize();
begin
   if(ox.Initialized) then
      oxRun.Done();

   oxInitialization.DeInitialize();

   log.i('ox library deinitialized');
end;

function oxTLibrary.GetAppInfo(): appPInfo;
begin
   result := @appInfo;
end;

function oxTLibrary.IsAppActive(): boolean;
begin
   Result := app.Active;
end;

procedure oxTLibrary.SetParameters(var params: TStringArray);
begin
   parameters.SetParameters(params);
end;

procedure oxTLibrary.Run();
begin
   oxRun.GoCycle();
end;

INITIALIZATION
   {$IFDEF OX_LIBRARY}
   stdlog.LogEndTimeDate := false;
   {$ENDIF}

END.
