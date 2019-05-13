{
   uLog, logging backend
   Copyright (C) 2008. Dejan Boras

   Started On:    26.11.2008.
}

{$IF not defined(NO_THREADS) and not defined(LOG_THREAD_UNSAFE)}
   {$DEFINE LOG_THREAD_SAFE}
{$ENDIF}

{$MODE OBJFPC}{$H+}{$I-}{$GOTO+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uLog;

INTERFACE

   USES SysUtils, uStd{$IFNDEF NOLOG}, StringUtils{$ENDIF}, ConsoleUtils;

CONST
   {errors}
   logeNONE                = 00;
   logeGENERAL             = 01;
   logeNO_MEMORY           = 02;
   logeIO                  = 03;

   {file modes for log files | only writing modes are supported}
   logcREWRITE             = $00;
   logcAPPEND              = $01;

   {log priority/type}
   logcINFO					   = $0000;
   logcWARNING				   = $0001;
   logcERROR				   = $0002;
   logcVERBOSE				   = $0003;
   logcFATAL				   = $0004;
   logcDEBUG				   = $0005;
   logcOK				      = $0006;
   logcPRIORITY_MAX        = $0006;

   logcPriorityCharacters: array[0..logcPRIORITY_MAX] of char =
      ('I', 'W', 'E', 'V', 'F', 'D', 'K');

   {section}
   logcMAX_SECTIONS        = 20;
   logcMAX_SECTION_LEVEL   = logcMAX_SECTIONS - 1;

TYPE
   PLog        = ^TLog;
   PLogHandler = ^TLogHandler;

   TLogSettings = record
      Tag, {tag used in the log file, if supported}
      Path: string; {path to where log files should be created}

      {logging settings}

      {if false, logging functions do nothing}
      HandleLogs,
      {put an empty line after the log header}
      EmptyLineAfterHeader,
      {write time for each log entry}
      LogTime,
      {write logging start time and date}
      StartTimeDate,
      {write logging end time and date}
      EndTimeDate,
      {use file extension of the log handler if one is not set for the log file}
      UseHandlerFileExtension,
      {flush every time something is written to the log file}
      FlushOnWrite,
      {determines if verbose logging is enabled}
      VerboseEnabled: boolean;
   end;


   {a log handler}
   TLogHandler = record
      Name,
      FileExtension: string;
      NeedOpen,
      NoHeader: boolean;

      init: procedure(log: PLog);
      dispose: procedure(log: PLog);
      open: procedure(log: PLog);
      start: procedure(log: PLog);
      close: procedure(log: PLog);
      flush: procedure(log: PLog);
      writeln: procedure(log: PLog; priority: longint; const s: string);
      writelnraw: procedure(log: PLog; const s: string);
      enterSection: procedure(log: PLog; const s: string; collapsed: boolean);
      leaveSection: procedure(log: PLog);
      del: procedure(log: PLog);
   end;

   {a log file}

   { TLog }

   TLog = record
      FileName,
      LogHeader,
      tag: string;
      FileMode: longint;
      fl: ^text;

      Flags: record
         Initialized,
         Opened,
         Closing,
         AppendFailed,
         Error,
         Ok: boolean;
      end;

      {flush output on each write}
      FlushOnWrite,
      {is verbose logging enabled}
      VerboseEnabled,
      {log ending statement}
      LogEndTimeDate: boolean;

      SectionLevel: longint;
      Error,
      IoError: longint;

      {$IFDEF LOG_THREAD_SAFE}
      LogCS: TRTLCriticalSection;
      {$ENDIF}

      Handler: PLogHandler;
      h: PLogHandler;

      {next log in chain}
      ChainLog: PLog;

      {initializes the log file, the second one reserves memory}
      function Initialize(const {%H-}fn, {%H-}logh: string; {%H-}mode: longint): boolean;
      {disposes a TLog record}
      procedure Dispose();
      {opens the log file}
      procedure Open();
      {closes the log file}
      procedure Close();
      {closes the log file}
      procedure CloseChained();
      {deletes the log file}
      procedure Delete();
      {de initializes the log file, the second one also frees memory}
      procedure DeInitialize();
      {verifies that the log is ok and ready for writting}
      function Ok(): boolean;
      {Sets the log into a error state}
      procedure SetErrorState();
      procedure SetErrorState({%H-}errorCode: longint);
      {quickly initialize and open a log file}
      procedure QuickOpen(const {%H-}fn, {%H-}logh: string; {%H-}mode: longint; var {%H-}newHandler: TLogHandler);

      {log string with specified priority}
      procedure s({%H-}priority: longint; const {%H-}logString: string);
      {flush log file}
      procedure Flush();

      {log information}
      procedure i(const {%H-}logString: string);
      procedure i();
      {log error}
      procedure e(const {%H-}logString: string);
      {log warning}
      procedure w(const {%H-}logString: string);
      {log debug}
      procedure d(const {%H-}logString: string);
      {log verbose}
      procedure v(const {%H-}logString: string);
      {log fatal}
      procedure f(const {%H-}logString: string);
      {log ok}
      procedure k(const {%H-}logString: string);

      {enter section}
      procedure Enter(const {%H-}title: string; {%H-}collapsed: boolean);
      procedure Enter(const title: string);
      {enter a section, but set it collapsed by default}
      procedure Collapsed(const title: string);
      {exit section}
      procedure Leave();

      {handler writing}
      procedure HandlerWriteln({%H-}priority: longint; const {%H-}logString: string; {%H-}nochainlog: boolean);
      procedure HandlerWritelnRaw(const {%H-}logString: string);
   end;


   { TLogUtils }

   TLogUtils = record
      {called when the standard log is disposed of}
      onDeInitStdLog: TProcedure;

      Handler: record
         Dummy: TLogHandler; {dummy log handler}
         Standard: TLogHandler; {standard log handler}
         Console: TLogHandler; {console log handler}
         pDefault: PLogHandler; {default log handler}
      end;

      Settings: TLogSettings;

      {initialize a TLog record}
      procedure Init(out logFile: TLog);
      {initialize a TLogHandler record}
      procedure Init(out h: TLogHandler);

      {creates a TLog on the heap and returns a pointer to it}
      function Make(): PLog;
      {disposes a PLog}
      procedure Dispose(var logFile: PLog);

      {same as above, only it works with the standard logs}
      function Ok(): boolean; inline;
      {Quickly initializes and de-initializes the standard log with the given filename}
      procedure InitStd(const fn, logh: string; mode: longint);
      {deinitializes the standard log file}
      procedure DeInitStd();

      procedure s(priority: longint; const logString: string); inline;
      procedure i(const logString: string); inline;
      procedure i(); inline;
      procedure e(const logString: string); inline;
      procedure w(const logString: string); inline;
      procedure d(const logString: string); inline;
      procedure v(const logString: string); inline;
      procedure f(const logString: string); inline;
      procedure k(const logString: string); inline;
      procedure Flush(); inline;

      procedure Enter(const title: string); inline;
      procedure Collapsed(const title: string); inline;
      procedure Leave(); inline;
   end;

VAR
   {standard logs}
   stdlog: TLog;
   consoleLog: TLog;

   log: TLogUtils;

IMPLEMENTATION

{ TLogUtils }

procedure TLogUtils.Init(out logFile: TLog);
begin
   ZeroOut(logFile, SizeOf(logFile));

   logFile.Handler       := log.Handler.pDefault;
   logFile.h             := @log.Handler.Dummy;
   logFile.flushOnWrite  := log.Settings.FlushOnWrite;
   logFile.tag           := log.Settings.tag;

   logFile.VerboseEnabled := log.Settings.VerboseEnabled;
   logFile.LogEndTimeDate := log.Settings.EndTimeDate;
end;

procedure TLogUtils.Init(out h: TLogHandler);
begin
   ZeroOut(h, SizeOf(h));
end;

function TLogUtils.Make(): PLog;
var
   log: PLog = nil;

begin
   new(log);
   if(log <> nil) then
      Init(log^);

   result := log;
end;

procedure TLogUtils.Dispose(var logFile: PLog);
begin
   if(logFile <> nil) then begin
      logFile^.Dispose();
      system.Dispose(logFile);
      logFile := nil;
   end;
end;

{ stdlog }

function TLogUtils.Ok(): boolean; inline;
begin
   result := stdlog.Ok();
end;

procedure TLogUtils.InitStd(const fn, logh: string; mode: longint);
begin
   if(log.Settings.HandleLogs) and (not stdlog.Flags.Initialized) then begin
      {initialize the standard log file}
      stdlog.Initialize(fn, logh, mode);
      if(stdlog.Error = logeNONE) then
         {open the standard log file}
         stdlog.Open();

      if(stdlog.Error = 0) then begin
         if(IsConsole) then
            writeln('Initialized standard log file(' + stdlog.FileName + ')');
      end else begin
         if(IsConsole) then
            writeln('Failed to initialize stdlog(' + stdlog.FileName + '). Error: ', stdlog.Error, ',', stdlog.IoError);
      end;
   end;
end;

procedure TLogUtils.DeInitStd();
begin
   if(log.Settings.HandleLogs) then begin
      {close the standard log file}
      stdlog.Close();

      if(stdlog.Error = logeNONE) then begin
         {deinit the standard log file}
         stdlog.DeInitialize();
         stdlog.Dispose();

         if(log.onDeInitStdLog <> nil) then
            log.onDeInitStdLog();
      end;
   end;
end;

procedure TLogUtils.s(priority: longint; const logString: string); inline;
begin
   stdlog.s(priority, logString);
end;

procedure TLogUtils.i(const logString: string); inline;
begin
   stdlog.i(logString);
end;

procedure TLogUtils.i();
begin
   stdlog.i('');
end;

procedure TLogUtils.e(const logString: string); inline;
begin
   stdlog.e(logString);
end;

procedure TLogUtils.w(const logString: string); inline;
begin
   stdlog.w(logString);
end;

procedure TLogUtils.d(const logString: string); inline;
begin
   stdlog.d(logString);
end;

procedure TLogUtils.v(const logString: string); inline;
begin
   stdlog.v(logString);
end;

procedure TLogUtils.f(const logString: string); inline;
begin
   stdlog.f(logString);
end;

procedure TLogUtils.k(const logString: string);
begin
   stdlog.k(logString);
end;

procedure TLogUtils.Flush(); inline;
begin
   stdlog.Flush();
end;

procedure TLogUtils.Enter(const title: string);
begin
   stdlog.Enter(title);
end;

procedure TLogUtils.Collapsed(const title: string);
begin
   stdlog.Collapsed(title);
end;

procedure TLogUtils.Leave(); inline;
begin
   stdlog.Leave();
end;

function TLog.Initialize(const fn, logh: string; mode: longint): boolean;
begin
   result := false;

   {$IFNDEF NOLOG}
   {no filename provided, exit}
   if(log.Settings.HandleLogs) and (fn <> '') and (not Flags.Initialized) then begin
      {$IFDEF LOG_THREAD_SAFE}
      InitCriticalSection(LogCS);
      {$ENDIF}

      if(Handler = nil) then
         Handler := @log.Handler.Dummy;

      h := Handler;

      {store stuff}
      FileName   := log.Settings.Path + fn;
      LogHeader  := logh;
      FileMode   := mode;

      if(log.Settings.UseHandlerFileExtension) then
         FileName := ExtractAllNoExt(FileName) + '.' + h^.FileExtension;

      h^.init(@self);

      if(Error = 0) then begin
         Flags.Initialized := true;
         result := true;
      end;
   end;
   {$ELSE}
   h := @log.Handler.Dummy;
   {$ENDIF}
end;

procedure TLog.Dispose();
begin
   if(ChainLog <> nil) then
      ChainLog^.Dispose();

   FileName := '';
   h^.dispose(@self);
end;


procedure TLog.Open();
{$IFNDEF NOLOG}
var
   td: TDateTime;
{$ENDIF}

begin
   {$IFNDEF NOLOG}
   Error := logeNONE;

   if(log.Settings.HandleLogs) then begin
      Flags.Closing := false;
      if(not self.h^.needOpen) then begin
         Flags.Opened := true;
         Flags.Ok := true;
         exit;
      end;

      if(Flags.Initialized) then begin
         h^.open(@self);

         if(not Flags.Error) then begin
            Flags.Opened := true;
            Flags.Ok := true;

            h^.start(@self);

            {write down the log header(if one exists)}
            if(LogHeader <> '') and (not h^.noheader) then begin
               i(LogHeader);

               {put an additional after the header(if chosen so)}
               if(log.Settings.EmptyLineAfterHeader = true) then
                  i();
            end;

            if(log.Settings.StartTimeDate) then begin
               td := Now();
               i('Logging Start: ' + DateToStr(td) + ' at ' + TimeToStr(td));
            end;
         end
      end;
   end
   {$ENDIF}
end;

procedure TLog.Close();
{$IFNDEF NOLOG}
var
   td: TDateTime;
{$ENDIF}

begin
   {$IFNDEF NOLOG}
   Error := logeNONE;

   if(log.Settings.HandleLogs) and (Flags.Opened) then begin
      Flags.Closing := true;

      {exit any existing sections}
      if(SectionLevel > 0) then
         repeat
            Leave();
         until (SectionLevel = 0);

      {write log end time}
      if(log.settings.EndTimeDate) and (LogEndTimeDate) then begin
         td := Now();
         HandlerWriteln(logcINFO, 'Logging end:   ' + DateToStr(td) + ' at ' + TimeToStr(td), true);
      end;

      Flush();

      {close the file and set the state}
      h^.close(@self);

      Flags.Opened := false;
      Flags.Ok := false;
      Flags.Closing := false;
   end;

   {close chained log file}
   CloseChained();
   {$ENDIF}
end;

procedure TLog.CloseChained();
begin
   if(ChainLog <> nil) then begin
      ChainLog^.Close();
      ChainLog := nil;
   end;
end;

procedure TLog.Delete();
begin
   {$IFNDEF NOLOG}
   Error := logeNONE;

   if(log.Settings.HandleLogs) then begin
      {close the log file}
      if(Flags.Opened) then begin
         Close();

         if(Error <> 0) then
            exit;
      end;

       {erase the file}
       h^.del(@self);
   end;
   {$ENDIF}
end;

procedure TLog.DeInitialize();
begin
   {$IFNDEF NOLOG}
   Error := logeNONE;

   if(log.settings.HandleLogs <> false) and (Flags.Initialized) then begin
      {$IFDEF LOG_THREAD_SAFE}
      DoneCriticalSection(LogCS);
      {$ENDIF}

      {if the file is opened try to close it}
      if(Flags.Opened) then begin
         Close();

         if(Error <> logeNONE) then
            exit;
      end;

      Flags.Initialized := false;
      Flags.ok := false;
   end;
   {$ENDIF}
end;

function TLog.Ok(): boolean;
begin
   {$IFNDEF NOLOG}
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(LogCS);
   {$ENDIF}

   result := Flags.Ok;

   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(LogCS);
   {$ENDIF}
   {$ELSE}
   result := false;
   {$ENDIF}
end;

procedure TLog.SetErrorState();
begin
   SetErrorState(logeNONE);
end;

procedure TLog.SetErrorState(errorCode: longint);
begin
   {$IFNDEF NOLOG}
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(LogCS);
   {$ENDIF}

   Error       := errorCode;
   Flags.Error := true;
   Flags.Ok    := false;

   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(LogCS);
   {$ENDIF}
   {$ENDIF}
end;

procedure TLog.QuickOpen(const fn, logh: string; mode: longint; var newHandler: TLogHandler);
begin
   {$IFNDEF NOLOG}
   log.Init(self);
   Handler := @newHandler;
   Initialize(fn, logh, mode);
   Open();
   {$ENDIF}
end;

procedure TLog.s(priority: longint; const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(priority, logString, false);
   {$ENDIF}
end;

procedure TLog.Flush();
begin
   {$IFNDEF NOLOG}
   h^.flush(@self);
   {$ENDIF}
end;

procedure TLog.i(const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcINFO, logString, false);
   {$ENDIF}
end;

procedure TLog.i();
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcINFO, '', false);
   {$ENDIF}
end;

procedure TLog.e(const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcERROR, logString, false);
   {$ENDIF}
end;

procedure TLog.w(const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcWARNING, logString, false);
   {$ENDIF}
end;

procedure TLog.d(const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcDEBUG, logString, false);
   {$ENDIF}
end;

procedure TLog.v(const logString: string);
begin
   {$IFNDEF NOLOG}
   if(verboseEnabled) then
      HandlerWriteln(logcVERBOSE, logString, false);
   {$ENDIF}
end;

procedure TLog.f(const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcFATAL, logString, false);
   {$ENDIF}
end;

procedure TLog.k(const logString: string);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcOK, logString, false);
   {$ENDIF}
end;

procedure TLog.Enter(const title: string; collapsed: boolean);
begin
   {$IFNDEF NOLOG}
   if(Flags.Initialized) then begin
      h^.enterSection(@self, title, collapsed);
      inc(SectionLevel);
      assert(SectionLevel < logcMAX_SECTIONS, 'Too many log sections, increase logcMAX_SECTIONS.');
   end;

   if(ChainLog <> nil) then
      ChainLog^.Enter(title, collapsed);
   {$ENDIF}
end;

procedure TLog.Enter(const title: string);
begin
   Enter(title, false);
end;

procedure TLog.Collapsed(const title: string);
begin
   Enter(title, true);
end;

procedure TLog.Leave();
begin
   {$IFNDEF NOLOG}
   if(SectionLevel > 0) then begin
      h^.leaveSection(@self);
      dec(SectionLevel);

      if(ChainLog <> nil) then
         ChainLog^.Leave();
   end;
   {$ENDIF}
end;

{ HANDLER }

procedure TLog.HandlerWriteln(priority: longint; const logString: string; nochainlog: boolean);
begin
   {$IFNDEF NOLOG}
   if(Flags.Ok) then begin
      h^.writeln(@self, priority, logString);

      if(flushOnWrite) then
         h^.flush(@self);
   end;

   if(ChainLog <> nil) and (not nochainlog) then
      ChainLog^.HandlerWriteln(priority, logString, false);
   {$ENDIF}
end;

procedure TLog.HandlerWritelnRaw(const logString: string);
begin
   {$IFNDEF NOLOG}
   if(Flags.Ok) then begin
      h^.writelnraw(@self, logString);

      if(flushOnWrite) then
         h^.flush(@self);
   end;
   {$ENDIF}
end;

{ DUMMY LOG HANDLER}
{$PUSH}{$HINTS OFF}
procedure dummyproc(log: PLog);
begin
   if(log <> nil) then;
end;

procedure dummystringproc(log: PLog; const s: string);
begin
end;

procedure dummywriteln(log: PLog; priority: longint; const s: string);
begin
end;

procedure dummyEnter(log: PLog; const s: string; collapsed: boolean);
begin
end;

procedure dummyLeave(log: PLog);
begin
end;

{$POP}

{ STANDARD LOG HANDLER }
function stderror(var log: TLog): longint;
begin
   log.IoError := IOResult();

   if(log.IoError <> 0) then
      log.SetErrorState(logeIO);

   result := log.IoError;
end;

procedure stdopen(log: PLog);
label
   repeatopen;

begin
   {jump here to try to open the file again, and who said labels are not good
   | other method could have been used but this one is simple}
repeatopen:

   {open the file in the correct mode.
   If the file cannot be appended try rewriting it}
   if(log^.FileMode = logcAPPEND)then begin
      append(log^.fl^);

      if(stderror(log^) <> 0) then begin
         log^.Flags.AppendFailed := true;
         log^.FileMode := logcREWRITE;
         goto repeatopen;
      end;
   end else if(log^.FileMode = logcREWRITE)then begin
      rewrite(log^.fl^);

      if(stderror(log^) <> 0) then
         log^.SetErrorState(logeIO);
   end else begin
      log^.FileMode := logcREWRITE;
      goto repeatopen;
   end;
end;

procedure stdinit(log: PLog);
begin
   {get memory for the file}
   new(log^.fl);

   if(log^.fl <> nil) then
      {assign the filename to the file}
      Assign(log^.fl^, log^.FileName)
   else
      log^.Error := logeNO_MEMORY;
end;

procedure stddispose(log: PLog);
begin
   if(log^.fl <> nil) then
      dispose(log^.fl);

   log^.fl := nil;
end;

procedure stdclose(log: PLog);
begin
   close(log^.fl^);
   IOResult();
end;

VAR
   tabstr: string = #9#9#9#9#9 + #9#9#9#9#9 + #9#9#9#9#9 + #9#9#9#9#9;
   spacestr: string = '                                 ';

procedure stdwriteln(logFile: PLog; priority: longint; const s: string);
var
   timeString: string = '';

begin
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(logFile^.LogCS);
   {$ENDIF}

   if(logFile^.Ok()) then begin
      if(s <> '') then begin
         {construct a time string}
         if(log.Settings.LogTime) then begin
            timeString := TimeToStr(Now());
         end;

         if(priority >= 0) and (priority <= logcPRIORITY_MAX) then
            timeString := timeString + ' ' + logcPriorityCharacters[priority] + '> ';

         {add tabs to signify a section}
         if(logFile^.SectionLevel > 0) then
            writeln(logFile^.fl^, timeString + copy(tabstr, 1, logFile^.SectionLevel) + s)
         else
         {level 0 section needs no tabs}
            writeln(logFile^.fl^, timeString + s);
      end else
         writeln(logFile^.fl^);

      {check for errors}
      stderror(logFile^);
   end;
   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(logFile^.LogCS);
   {$ENDIF}
end;

procedure stdwritelnraw(log: PLog; const s: string);
begin
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(log^.LogCS);
   {$ENDIF}

   if(log^.Ok()) then begin
      writeln(log^.fl^, s);
      stderror(log^);
   end;

   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(log^.LogCS);
   {$ENDIF}
end;

procedure stdflush(log: PLog);
begin
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(log^.LogCS);
   {$ENDIF}

   if(log^.Ok()) then begin
      flush(log^.fl^);
      stderror(log^);
   end;

   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(log^.LogCS);
   {$ENDIF}
end;

procedure stddel(log: PLog);
begin
   erase(log^.fl^);
   stderror(log^);
end;

VAR
   consoleColors: array[0..logcPRIORITY_MAX] of longint = (
      console.LightGray, {logcINFO}
      console.Yellow, {logcWARNING}
      console.LightRed, {logcERROR}
      console.DarkGray, {logcVERBOSE}
      console.Red, {logcFATAL}
      console.Cyan, {logcDEBUG}
      console.LightGreen {logcOK}
   );

procedure consoleWriteln(logFile: PLog; priority: longint; const s: string);
var
   timeString: string = '';

begin
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(logFile^.LogCS);
   {$ENDIF}

   if(logFile^.Ok() {$IFDEF WINDOWS}and IsConsole{$ENDIF}) then begin
      if(s <> '') then begin
         {construct a time string}
         if(log.Settings.LogTime) then
            timeString := TimeToStr(Now());

         if(priority >= 0) and (priority <= logcPRIORITY_MAX) then begin
            if(priority <> logcINFO) then
               console.TextColor(consoleColors[priority]);

            timeString := timeString + ' ';
         end;

         {add tabs to signify a section}
         if(logFile^.SectionLevel > 0) then begin
            writeln(timeString + copy(spacestr, 1, logFile^.SectionLevel * 2) + s)
         end else
         {level 0 section needs no tabs}
            writeln(timeString + s);

         if(priority <> logcINFO) then
            console.ResetDefault();
      end else
         writeln();
   end;

   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(logFile^.LogCS);
   {$ENDIF}
end;

procedure consoleWritelnRaw(log: PLog; const s: string);
begin
   {$IFDEF LOG_THREAD_SAFE}
   EnterCriticalSection(log^.LogCS);
   {$ENDIF}

   if(log^.Ok() {$IFDEF WINDOWS}and IsConsole{$ENDIF}) then
      writeln(s);

   {$IFDEF LOG_THREAD_SAFE}
   LeaveCriticalSection(log^.LogCS);
   {$ENDIF}
end;


procedure stdEnter(log: PLog; const s: string; {%H-}collapsed: boolean);
begin
   log^.HandlerWriteln(logcINFO, s, true);
end;

procedure consoleEnter(log: PLog; const s: string; {%H-}collapsed: boolean);
begin
   log^.HandlerWriteln(logcINFO, s, true);
end;

procedure initStdHandler();
begin
   log.Handler.Standard               := log.Handler.Dummy;
   log.Handler.Standard.Name          := 'standard';
   log.Handler.Standard.FileExtension := 'log';
   log.Handler.Standard.NeedOpen      := true;

   log.Handler.Standard.open          := @stdopen;
   log.Handler.Standard.close         := @stdclose;
   log.Handler.Standard.init          := @stdinit;
   log.Handler.Standard.dispose       := @stddispose;
   log.Handler.Standard.writeln       := @stdwriteln;
   log.Handler.Standard.writelnraw    := @stdwritelnraw;
   log.Handler.Standard.flush         := @stdflush;
   log.Handler.Standard.enterSection  := @stdEnter;

   log.Handler.pDefault := @log.Handler.Standard;
end;

procedure initConsoleHandler();
begin
   log.Handler.Console              := log.Handler.Dummy;
   log.Handler.Console.Name         := 'console';
   log.Handler.Console.NeedOpen     := false;

   log.Handler.Console.writeln     := @consoleWriteln;
   log.Handler.Console.writelnraw  := @consoleWritelnRaw;
   log.Handler.Console.enterSection:= @consoleEnter;
end;

{ INITIALIZE }

procedure Init();
begin
   log.Settings.Tag                       := '';
   log.Settings.Path                      := '';
   log.Settings.HandleLogs                := true;
   log.Settings.EmptyLineAfterHeader      := true;
   log.Settings.LogTime                   := true;
   log.Settings.StartTimeDate             := true;
   log.Settings.EndTimeDate               := true;
   log.Settings.UseHandlerFileExtension   := true;
   log.Settings.FlushOnWrite              := true;
   log.Settings.VerboseEnabled            := true;

   {initiale the dummy handler}
   log.Handler.Dummy.Name             := 'dummy';
   log.Handler.Dummy.FileExtension    := '';
   log.Handler.Dummy.NeedOpen         := false;
   log.Handler.Dummy.NoHeader         := false;

   log.Handler.Dummy.open             := @dummyproc;
   log.Handler.Dummy.start            := @dummyproc;
   log.Handler.Dummy.close            := @dummyproc;
   log.Handler.Dummy.init             := @dummyproc;
   log.Handler.Dummy.dispose          := @dummyproc;
   log.Handler.Dummy.writeln          := @dummywriteln;
   log.Handler.Dummy.writelnraw       := @dummystringproc;
   log.Handler.Dummy.flush            := @dummyproc;
   log.Handler.Dummy.del              := @dummyproc;
   log.Handler.Dummy.enterSection     := @dummyEnter;
   log.Handler.Dummy.leaveSection     := @dummyLeave;

   {initialize other handlers}
   initStdHandler();
   initConsoleHandler();
end;

INITIALIZATION
   consoleColors[0] := ConsoleUtils.console.InitialTextColor;
   {$IFNDEF NOLOG}
   Init();
   log.Init(stdlog);
   log.Init(consoleLog);

   {setup html log}
   consoleLog.QuickOpen('console', '', logcREWRITE, log.Handler.Console);
   consoleLog.LogEndTimeDate := false;
   stdlog.ChainLog := @consoleLog;
   {$ELSE}
   if(IsConsole) then
      writeln('Logging support disabled');
   {$ENDIF}

FINALIZATION
   {$IFNDEF NOLOG}
   log.DeInitStd();
   {$ENDIF}

END.
