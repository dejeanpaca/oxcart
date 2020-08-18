{
   uOX, base oX unit
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uOX;

INTERFACE

   USES
      uStd, uLog, udvars, uError,
      uAppInfo, oxuRunRoutines;

CONST
   oxEngineName = 'oX';
   oxVersion: array[0..2] of loopint = (0, 4, 0);
   oxsVersion = '0.4';


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

      {initialization failed}
      InitializationFailed: boolean;

      Error: loopint;

      {list of all do routines}
      {called after base engine is initialized}
      OnPreInitialize,
      {called after engine is initialized}
      OnInitialize,
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
      Init: oxTRunRoutines;

      dvar: TDVarGroup;
      {dvar group specifically for the program so the settings are not mixed with the engine}
      ProgramDvar: TDVarGroup;

      function GetVersionString(properties: longword = 0): string;
      function GetErrorDescription(errcode: longint): string;

      class function IsType(what, whatType: TClass): boolean; static;
      class function IsType(what: TObject; whatType: TClass): boolean; static;
      class procedure Assert(expression: boolean; const description: string); static;
   end;

VAR
   ox: oxTGlobal;

IMPLEMENTATION

VAR
   ox_version: StdString = oxsVersion;
   dv_version: TDVar;

{ VERSION }
function oxTGlobal.GetVersionString(properties: longword = 0): string;
var
   vstr: string = '';

begin
   vstr := 'v' + oxsVersion;

   if(properties and oxVERSION_STR_ONLY = 0) then begin
      if(properties and oxVERSION_STR_SHORT > 0) then
         Result := oxEngineName + ' ' + vstr
      else
         Result := oxEngineName + ' Engine ' + vstr;
   end else
      Result := vstr;
end;

function oxTGlobal.GetErrorDescription(errcode: longint): string;
begin
   if(errcode > $FF) then begin
   end;

   exit(uError.GetErrorCodeString(errcode));
end;

class function oxTGlobal.IsType(what, whatType: TClass): boolean;
var
   cur: TClass;

begin
   cur := what.ClassType;

   repeat
     {$IFDEF OX_LIBRARY_SUPPORT}
     if(cur.ClassName = whatType.ClassName) then
        exit(true);
     {$ELSE}
     if(cur = whatType) then
        exit(true);
     {$ENDIF}

     cur := cur.ClassParent;
   until (cur = nil) or (cur = TObject);

   Result := false;
end;

class function oxTGlobal.IsType(what: TObject; whatType: TClass): boolean;
var
   cur: TClass;

begin
   cur := what.ClassType;

   repeat
     {$IFDEF OX_LIBRARY_SUPPORT}
     if(cur.ClassName = whatType.ClassName) then
        exit(true);
     {$ELSE}
     if(cur = whatType) then
        exit(true);
     {$ENDIF}

     cur := cur.ClassParent;
   until (cur = nil) or (cur = TObject);

   Result := false;
end;

class procedure oxTGlobal.Assert(expression: boolean; const description: string);
begin
   {$IFOPT C+}
      {$IFNDEF OX_LIBRARY}
      system.Assert(expression, description);
      {$ELSE}
      if (not expression) then
         log.e('Assertion failed: ' + description);
      {$ENDIF}
   {$ELSE}
   system.Assert(expression, description);
   {$ENDIF}
end;

INITIALIZATION
   appInfo.SetOrganization('ox');

   dvar.Add('ox', ox.dvar);
   ox.dvar.Add(dv_version, 'version', dtcSTRING, @ox_version);
   dv_version.Properties := dv_version.Properties + [dvarREADONLY, dvarDO_NOT_SAVE];

   {$IFDEF OX_LIBRARY}
   ox.LibraryMode := true;
   {$ENDIF}

END.
