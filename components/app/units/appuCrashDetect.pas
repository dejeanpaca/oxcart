{
   appuCrashDetect, detects if a crash occured in the previous instance of the program
   Copyright (C) 2011. Dejan Boras

   Started On:    30.10.2013.
}

{$INCLUDE oxdefines.inc}
UNIT appuCrashDetect;

INTERFACE

   USES
      uFileUtils, uLog,
      uApp, appuPaths,
      oxuRunRoutines;

TYPE
   appTCrashDetect = record
      {did the previous instance crash}
      previousInstanceCrashed,
      {was a check for a crash made}
      checkedCrash,
      {skip initialization}
      skipInit: boolean;

      {returns crash detect file name}
      function GetFileName(): string;
      {runs crash detection}
      function Run(): boolean;
   end;

VAR
   appCrashDetect: appTCrashDetect;

IMPLEMENTATION

function appTCrashDetect.GetFileName(): string;
begin
   result := appPath.Configuration.Path + 'crashdetect';
end;

function appTCrashDetect.Run(): boolean;
var
   fn: string;

begin
   if(not checkedCrash) then begin
      fn := GetFileName();

      if(FileUtils.Exists(fn) = -1) then begin
         FileUtils.Create(fn);
         previousInstanceCrashed := false;
      end else begin
         log.w('Previous instance of the application did not exit cleanly.');
         previousInstanceCrashed := true;
      end;

      checkedCrash := true;
   end;

   result := previousInstanceCrashed;
end;

procedure DeInitialize();
var
   fn: string;

begin
   fn := appCrashDetect.GetFileName();

   FileUtils.Erase(fn);
end;

procedure Initialize();
begin
   if(not appCrashDetect.skipInit) then
      appCrashDetect.Run();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   app.InitializationProcs.Add(initRoutines, 'crashdetect', @Initialize, @DeInitialize);

END.
