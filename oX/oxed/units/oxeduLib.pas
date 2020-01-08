{
   oxeduLib, handles loading/unloading the generated project library
   Copyright (C) 2017. Dejan Boras

   Started On:    04.06.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduLib;

INTERFACE

   USES
      sysutils, dynlibs, uStd, uLog, uAppInfo, uFileUtils, uTiming,
      {ox}
      oxuDynlib, oxulibSettings, oxuGlobalInstances, oxuWindows,
      {oxed}
      uOXED, oxeduProject, oxeduMessages;

TYPE

   { oxedTLibraryGlobal }

   oxedTLibraryGlobal = record
      oxLib: oxTLibrary;
      Lib: TLibHandle;
      appInfo: appPInfo;

      Routines: record
         Load: oxTLibraryLoadRoutine;
         Unload: oxTLibraryUnloadRoutine;
         Version: oxTLibraryVersionRoutine;
      end;

      oxWindows: oxPWindows;
      Settings: oxPLibrarySettings;

      function Load(): boolean;
      function Unload(): boolean;

      private
         function LoadLib(): string;
   end;

VAR
   oxedLib: oxedTLibraryGlobal;
   oxLibReferences: oxTGlobalInstances;

IMPLEMENTATION

{ oxedTLibraryGlobal }

function oxedTLibraryGlobal.Load(): boolean;
var
   logMessage: string = '';

begin
   logMessage := LoadLib();

   if(logMessage = '') then begin
      Result := true
   end else begin
      oxedMessages.e(logMessage);

      Result := false;
      Unload();
   end;
end;

function oxedTLibraryGlobal.Unload(): boolean;
begin
   oxWindows := nil;

   if(Lib <> 0) then begin
      oxLibReferences := nil;

      if(oxLib <> nil) then
         oxLib.Deinitialize();

      if(oxedLib.routines.Unload <> nil) then
         oxedLib.routines.Unload();

      UnloadLibrary(Lib);
      oxLib := nil;
      Settings := nil;

      Lib := 0;
      log.i('Library unloaded successfully');

      Result := true;
   end else
      Result := true;
end;

function oxedTLibraryGlobal.LoadLib(): string;
var
   path: string;
   size: loopint;
   startTime: TDateTime;

begin
   startTime := Time();
   path := oxedProject.GetLibraryPath();

   size := FileUtils.Exists(path);

   if(size < 0) then
      exit('Library ' + path + ' not found')
   else if(size = 0) then
      exit('Library ' + path + ' is empty (invalid output)');

   Lib := LoadLibrary(path);

   if(Lib = 0) then
      exit('Library ' + path + ' failed to load');

   routines.Load := oxTLibraryLoadRoutine(dynlibs.GetProcedureAddress(Lib, 'ox_library_load'));
   routines.Unload := oxTLibraryUnloadRoutine(dynlibs.GetProcedureAddress(Lib, 'ox_library_unload'));
   routines.Version := oxTLibraryVersionRoutine(dynlibs.GetProcedureAddress(Lib, 'ox_library_version'));

   if(routines.Load = nil) then
      exit('Library loaded, but no version routine found');
   if(routines.Unload = nil) then
      exit('Library loaded, but no load routine found');
   if(routines.Version = nil) then
      exit('Library loaded, but no unload routine found');

   if(OX_LIBRARY_VERSION_STRING <> routines.Version()) then
      exit('Library version mismatch. Got ' + routines.Version() + ', expected ' + OX_LIBRARY_VERSION_STRING + '. Please rebuild.');

   oxLib := routines.Load();

   if(oxLib = nil) then
      exit('Library loaded, but did not return a proper object');

   oxLib.GlobalInstances := oxGlobalInstances;
   log.i('Library ' + path + ' loaded successfully: '  + oxLib.Name + ' (Elapsed: ' + startTime.ElapsedfToString() + 's)');

   appInfo := oxLib.GetAppInfo();

   {force organization to preset while running inside OXED}
   appInfo^.SetOrganization(oxedPROJECT_ORGANIZATION);

   oxLibReferences := oxLib.LibraryInstances;

   Settings := oxLib.GetSettings();

   Result := '';
end;

END.
