{
   oxuDynlib, base unit for dynamic libraries
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuDynlib;

INTERFACE

   USES
      sysutils, uLog, uStd, ParamUtils, StringUtils,
      {app}
      uAppInfo, uApp,
      {ox}
      uOX, oxuGlobalInstances, oxuInitialize, oxuRun, oxulibSettings;

CONST
   {library interface version (does not necessarily indicate engine compatibility)}
   OX_LIBRARY_VERSION_STRING = '3';

TYPE
   { oxTLibrary }

   oxTLibrary = class
      Name: string;
      GlobalInstances: oxPGlobalInstances;
      LibraryInstances: oxPGlobalInstances;
      {is the library in error state}
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
      procedure SetParameters(var params: StringUtils.TStringArray); virtual;

      procedure Run(); virtual;

      {get library mode settings}
      function GetSettings(): oxPLibrarySettings; virtual;
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
   oxLibrary.LibraryInstances := @oxuGlobalInstances.oxGlobalInstances;

   Result := oxLibrary;
end;

procedure ox_library_unload();
begin
   FreeObject(oxLibrary);

   log.v('lib > unloaded');
end;

function ox_library_version(): string;
begin
   Result := OX_LIBRARY_VERSION_STRING;
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
   consoleLog.LogEndTimeDate := false;

   if(GlobalInstances <> nil) then begin
      GlobalInstances^.CopyOverReferences(oxuGlobalInstances.oxGlobalInstances);
      oxExternalGlobalInstances := Self.GlobalInstances;

      {$IFDEF OX_LIBRARY}
      log.i('lib > copied global instances');
      {$ENDIF}

      {$IFDEF OX_LIBRARY}
      log.i('lib > initialize start');
      {$ENDIF}

      oxRun.Initialize();

      exit(ox.Initialized);
   end else
      log.e('lib > global instances reference not set');

   Result := false;
end;

function oxTLibrary.Start(): boolean;
begin
   if(ox.Initialized) then begin
      log.i('lib > initialized');

      oxRun.Start();
   end;

   Result := ox.Initialized;
end;

procedure oxTLibrary.Deinitialize();
begin
   if(ox.Initialized) then
      oxRun.Done();

   oxInitialization.DeInitialize();

   log.i('lib > deinitialized');
end;

function oxTLibrary.GetAppInfo(): appPInfo;
begin
   Result := @appInfo;
end;

function oxTLibrary.IsAppActive(): boolean;
begin
   Result := app.Active;
end;

procedure oxTLibrary.SetParameters(var params: StringUtils.TStringArray);
begin
   parameters.SetParameters(params);
end;

procedure oxTLibrary.Run();
begin
   oxRun.GoCycle(false);
end;

function oxTLibrary.GetSettings(): oxPLibrarySettings;
begin
   Result := @oxLibrarySettings;
end;

INITIALIZATION
   {$IFDEF OX_LIBRARY}
   stdlog.LogEndTimeDate := false;
   {$ENDIF}

END.
