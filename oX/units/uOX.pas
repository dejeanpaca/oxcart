{
   uOX, base oX unit
   Copyright (c) 2011. Dejan Boras

   Started On:    08.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uOX;

INTERFACE

   USES
      uStd, uInit, uAppInfo, udvars, oxuRunRoutines;

CONST
   oxEngineName               = 'oX';
   oxsVersion                 = '0.4';


   { ERROR CODES }
   oxeGENERAL                    = $0100;
   oxeIMAGE                      = $0101;
   oxeRENDERER                   = $0102; {opengl error}
   oxeNO_GRAPHICS_MEM            = $0103; {no GPU memory}
   oxePLATFORM_INITIALIZATION    = $0104; {failed to initialize platform}
   oxeUNSUPPORTED_ENDIAN         = $0105; {unsupported endian type}

   { VERSION STRING PROPERTIES }
   oxVERSION_STR_SHORT        = $0001;
   oxVERSION_STR_ONLY         = $0002;


TYPE
   { oxTGlobal }

   oxTGlobal = record
      {has the engine been initialized}
      Initialized,
      {has the program started}
      Started,
      {are we running as part of a library}
      LibraryMode: boolean;

      Error: loopint;

      {list of all do routines}
      {called after base engine is initialized}
      OnPreInitialize,
      {called after engine is initialized}
      OnInitialize,
      {called before engine is deinitialized}
      OnDeinitialize,
      {called when the program is ready to start}
      OnStart,
      {called after initialization, but before start to load required resources}
      OnLoad,
      {called before events are processes}
      OnPreEvents,
      {called on run}
      OnRun,
      {called on the end of the run cylce (after OnRun)}
      OnRunAfter: oxTRunRoutines;

      {preinitialization routines (before renderer/window is created)}
      PreInit,
      {minimal required functionality for engine}
      BaseInit,
      {engine initialization}
      Init,
      {program/application initialization}
      AppProcs: TInitializationProcs;

      dvar: TDVarGroup;

      function GetVersionString(properties: longword = 0): string;
      function GetErrorDescription(errcode: longint): string;
   end;

VAR
   ox: oxTGlobal;

{ VERSION }

IMPLEMENTATION

VAR
   ox_version: string = oxsVersion;
   dv_version: TDVar;

{ VERSION }
function oxTGlobal.GetVersionString(properties: longword = 0): string;
var
   vstr: string = '';

begin
   vstr := 'v' + oxsVersion;

   if(properties and oxVERSION_STR_ONLY = 0) then begin
      if(properties and oxVERSION_STR_SHORT > 0) then
         result := oxEngineName + ' ' + vstr
      else
         result := oxEngineName + ' Engine ' + vstr;
   end else
      result := vstr;
end;

function oxTGlobal.GetErrorDescription(errcode: longint): string;
begin
   if(errcode > $FF) then begin
   end;

   exit(uStd.eGetCodeName(errcode));
end;

INITIALIZATION
   appInfo.setOrganization('ox');

   ox.PreInit.Init('ox.preinit');
   ox.PreInit.DontDetermineState();

   ox.Init.Init('ox.init');
   ox.Init.DontDetermineState();

   ox.AppProcs.Init('ox.appprocs');
   ox.AppProcs.DontDetermineState();

   ox.AppProcs.Init('ox.app');

   dvar.Add('ox', ox.dvar);
   ox.dvar.Add(dv_version, 'version', dtcSTRING, @ox_version);
   dv_version.Properties := dv_version.Properties + [dvarREADONLY, dvarDO_NOT_SAVE];

   {$IFDEF OX_LIBRARY}
   ox.LibraryMode := true;
   {$ENDIF}

END.
