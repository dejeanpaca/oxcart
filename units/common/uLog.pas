{
   uLog, logging backend
   Copyright (C) 2008. Dejan Boras
}

{$IF not defined(NO_THREADS) and not defined(LOG_THREAD_UNSAFE)}
   {$DEFINE LOG_THREAD_SAFE}
{$ENDIF}

{$INCLUDE oxheader.inc}
UNIT uLog;

INTERFACE

   USES
      SysUtils, uStd{$IFNDEF NOLOG}, StringUtils{$ENDIF}, ConsoleUtils
      {$IFDEF ANDROID}, android_log_helper{$ENDIF};

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
      Path: StdString; {path to where log files should be created}

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

   { TLogHandler }

   TLogHandler = object
      Name,
      FileExtension: StdString;
      NeedOpen,
      NoHeader: boolean;

      constructor Create();

      procedure Init(log: PLog); virtual;
      procedure Dispose(log: PLog); virtual;
      procedure Open(log: PLog); virtual;
      procedure Start(log: PLog); virtual;
      procedure Close(log: PLog); virtual;
      procedure Flush(log: PLog); virtual;
      procedure Writeln(log: PLog; priority: longint; const s: StdString); virtual;
      procedure WritelnRaw(log: PLog; const s: StdString); virtual;
      procedure EnterSection(log: PLog; const s: StdString; collapsed: boolean); virtual;
      procedure LeaveSection(log: PLog); virtual;
      procedure Del(log: PLog); virtual;
   end;

   {a log file}

   { TLog }

   TLog = record
      FileName,
      LogHeader,
      Tag: StdString;
      FileMode: longint;
      Fl: ^text;

      Flags: record
         Initialized,
         Opened,
         Closing,
         AppendFailed,
         Error,
         CloseChained,
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

      {next log in chain}
      ChainLog: PLog;

      {initializes the log file, the second one reserves memory}
      function Initialize(const fn, logh: StdString; mode: longint): boolean;
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
      procedure QuickOpen(const {%H-}fn, {%H-}logh: StdString; {%H-}mode: longint; var {%H-}newHandler: TLogHandler);

      {reset the log file to an empty state}
      procedure Reset();

      {log string with specified priority}
      procedure s({%H-}priority: longint; const {%H-}logString: StdString);
      procedure s({%H-}priority: longint; {%H-}args: array of const);

      {flush log file}
      procedure Flush();
      {flush log file}
      procedure FlushChain();

      {log information}
      procedure i(const {%H-}logString: StdString);
      procedure i({%H-}args: array of const);
      procedure i();
      {log error}
      procedure e(const {%H-}logString: StdString);
      procedure e({%H-}args: array of const);
      {log warning}
      procedure w(const {%H-}logString: StdString);
      procedure w({%H-}args: array of const);
      {log debug}
      procedure d(const {%H-}logString: StdString);
      procedure d({%H-}args: array of const);
      {log verbose}
      procedure v(const {%H-}logString: StdString);
      procedure v({%H-}args: array of const);
      {log fatal}
      procedure f(const {%H-}logString: StdString);
      procedure f({%H-}args: array of const);
      {log ok}
      procedure k(const {%H-}logString: StdString);
      procedure k({%H-}args: array of const);

      {enter section}
      procedure Enter(const {%H-}title: StdString; {%H-}collapsed: boolean);
      procedure Enter(const title: StdString);
      {enter a section, but set it collapsed by default}
      procedure Collapsed(const title: StdString);
      {exit section}
      procedure Leave();

      {handler writing}
      procedure HandlerWriteln({%H-}priority: longint; const {%H-}logString: StdString; {%H-}noChainLog: boolean);
      procedure HandlerWritelnRaw(const {%H-}logString: StdString);
   end;

   { TDummyLogHandler }

   TDummyLogHandler = object(TLogHandler)
      constructor Create();
   end;

   { TStandardLogHandler }

   TStandardLogHandler = object(TLogHandler)
      constructor Create();

      procedure Init(log: PLog); virtual;
      procedure Dispose(log: PLog); virtual;
      procedure Open(log: PLog); virtual;
      procedure Close(log: PLog); virtual;
      procedure Flush(log: PLog); virtual;
      procedure Writeln(logf: PLog; priority: longint; const s: StdString); virtual;
      procedure WritelnRaw(log: PLog; const s: StdString); virtual;
      procedure EnterSection(log: PLog; const s: StdString; {%H-}collapsed: boolean); virtual;
      procedure Del(log: PLog); virtual;

      { STANDARD LOG HANDLER }
      function StdError(var log: TLog): longint;
   end;

   { TConsoleLogHandler }

   TConsoleLogHandler = object(TLogHandler)
      constructor Create();

      procedure Writeln(logf: PLog; priority: longint; const s: StdString); virtual;
      procedure WritelnRaw(log: PLog; const s: StdString); virtual;
      procedure EnterSection(log: PLog; const s: StdString; {%H-}collapsed: boolean); virtual;
   end;

   { TLogUtils }

   TLogUtils = record
      {called when the standard log is disposed of}
      onDeInitStdLog: TProcedure;

      Handler: record
         Dummy: TLogHandler; {dummy log handler}
         Standard: TStandardLogHandler; {standard log handler}
         Console: TConsoleLogHandler; {console log handler}
         pDefault: PLogHandler; {default log handler}
      end;

      TabString,
      SpaceString: StdString;

      Settings: TLogSettings;

      {initialize a TLog record}
      procedure Init(out logFile: TLog);

      {creates a TLog on the heap and returns a pointer to it}
      function Make(): PLog;
      {disposes a PLog}
      procedure Dispose(var logFile: PLog);

      {same as above, only it works with the standard logs}
      function Ok(): boolean; inline;
      {Quickly initializes and de-initializes the standard log with the given filename}
      procedure InitStd(const fn, logh: StdString; mode: longint);
      {deinitializes the standard log file}
      procedure DeInitStd();

      procedure s(priority: longint; const logString: StdString); inline;
      procedure i(const logString: StdString); inline;
      procedure i(); inline;
      procedure e(const logString: StdString); inline;
      procedure w(const logString: StdString); inline;
      procedure d(const logString: StdString); inline;
      procedure v(const logString: StdString); inline;
      procedure f(const logString: StdString); inline;
      procedure k(const logString: StdString); inline;
      procedure Flush(); inline;

      {set a default handler (which also sets the stdlog handler)}
      procedure SetDefaultHandler(const newHandler: tLogHandler);

      procedure Enter(const title: StdString); inline;
      procedure Collapsed(const title: StdString); inline;
      procedure Leave(); inline;
   end;

VAR
   {standard logs}
   stdlog,
   consoleLog: TLog;

   log: TLogUtils;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

{ TLogHandler }

{$PUSH}
{$WARN 5024 off : Parameter "$1" not used}

constructor TLogHandler.Create();
begin

end;

procedure TLogHandler.Init(log: PLog);
begin
end;

procedure TLogHandler.Dispose(log: PLog);
begin

end;

procedure TLogHandler.Open(log: PLog);
begin

end;

procedure TLogHandler.Start(log: PLog);
begin

end;

procedure TLogHandler.Close(log: PLog);
begin

end;

procedure TLogHandler.Flush(log: PLog);
begin

end;

procedure TLogHandler.Writeln(log: PLog; priority: longint; const s: StdString);
begin

end;

procedure TLogHandler.WritelnRaw(log: PLog; const s: StdString);
begin

end;

procedure TLogHandler.EnterSection(log: PLog; const s: StdString; collapsed: boolean);
begin

end;

procedure TLogHandler.LeaveSection(log: PLog);
begin

end;

procedure TLogHandler.Del(log: PLog);
begin

end;

{$POP}

{ TDummyLogHandler }

constructor TDummyLogHandler.Create();
begin
   Name := 'dummy';
end;

{ TStandardLogHandler }


constructor TStandardLogHandler.Create();
begin
   Name := 'standard';
   FileExtension := 'log';
   NeedOpen := true;
end;

procedure TStandardLogHandler.Init(log: PLog);
begin
   {get memory for the file}
   new(log^.Fl);

   if(log^.Fl <> nil) then begin
      {assign the filename to the file}
      UTF8Assign(log^.Fl^, log^.FileName);
   end else
      log^.Error := logeNO_MEMORY;
end;

procedure TStandardLogHandler.Dispose(log: PLog);
begin
   if(log^.Fl <> nil) then
      system.Dispose(log^.Fl);

   log^.Fl := nil;
end;

procedure TStandardLogHandler.Open(log: PLog);
label
   repeatopen;

begin
   {jump here to try to open the file again, and who said labels are not good
   | other method could have been used but this one is simple}
repeatopen:

   {open the file in the correct mode.
   If the file cannot be appended try rewriting it}
   if(log^.FileMode = logcAPPEND)then begin
      append(log^.Fl^);

      if(StdError(log^) <> 0) then begin
         log^.Flags.AppendFailed := true;
         log^.FileMode := logcREWRITE;
         goto repeatopen;
      end;
   end else if(log^.FileMode = logcREWRITE)then begin
      rewrite(log^.Fl^);

      if(StdError(log^) <> 0) then
         log^.SetErrorState(logeIO);
   end else begin
      log^.FileMode := logcREWRITE;
      goto repeatopen;
   end;
end;

procedure TStandardLogHandler.Close(log: PLog);
begin
   system.close(log^.Fl^);
   IOResult();
end;

procedure TStandardLogHandler.Flush(log: PLog);
begin
   if(log^.Ok()) then begin
      system.flush(log^.Fl^);
      StdError(log^);
   end;
end;

procedure TStandardLogHandler.Writeln(logf: PLog; priority: longint; const s: StdString);
var
   timeString: StdString = '';

begin
   if(logf^.Ok()) then begin
      if(s <> '') then begin
         {construct a time string}
         if(log.Settings.LogTime) then begin
            timeString := utf8string(TimeToStr(Now()));
         end;

         if(priority >= 0) and (priority <= logcPRIORITY_MAX) then
            timeString := timeString + ' ' + logcPriorityCharacters[priority] + '> ';

         {add tabs to signify a section}
         if(logf^.SectionLevel > 0) then
            system.writeln(logf^.Fl^, timeString + copy(log.TabString, 1, logf^.SectionLevel) + s)
         else
         {level 0 section needs no tabs}
            system.writeln(logf^.Fl^, timeString + s);
      end else
         system.writeln(logf^.Fl^);

      {check for errors}
      StdError(logf^);
   end;
end;

procedure TStandardLogHandler.WritelnRaw(log: PLog; const s: StdString);
begin
   if(log^.Ok()) then begin
      system.writeln(log^.Fl^, s);
      StdError(log^);
   end;
end;

procedure TStandardLogHandler.EnterSection(log: PLog; const s: StdString; collapsed: boolean);
begin
   log^.HandlerWriteln(logcINFO, s, true);
end;

procedure TStandardLogHandler.Del(log: PLog);
begin
   erase(log^.Fl^);
   StdError(log^);
end;

function TStandardLogHandler.StdError(var log: TLog): longint;
begin
   log.IoError := IOResult();

   if(log.IoError <> 0) then
      log.SetErrorState(logeIO);

   Result := log.IoError;
end;

{ TConsoleLogHandler }

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

constructor TConsoleLogHandler.Create();
begin
   Name := 'console';
   NeedOpen := false;
end;

procedure TConsoleLogHandler.Writeln(logf: PLog; priority: longint; const s: StdString);
var
   timeString: StdString = '';

begin
   if(logf^.Ok() {$IFDEF WINDOWS}and IsConsole{$ENDIF}) then begin
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
         if(logf^.SectionLevel > 0) then begin
            system.writeln(timeString + copy(log.SpaceString, 1, logf^.SectionLevel * 2) + s)
         end else
         {level 0 section needs no tabs}
            system.writeln(timeString + s);

         if(priority <> logcINFO) then
            console.ResetDefault();
      end else
         system.writeln();
   end;
end;

procedure TConsoleLogHandler.WritelnRaw(log: PLog; const s: StdString);
begin
   if(log^.Ok() {$IFDEF WINDOWS}and IsConsole{$ENDIF}) then begin
      system.writeln(s);
   end;
end;

procedure TConsoleLogHandler.EnterSection(log: PLog; const s: StdString; collapsed: boolean);
begin
   log^.HandlerWriteln(logcINFO, s, true);
end;

{ TLogUtils }

procedure TLogUtils.Init(out logFile: TLog);
begin
   ZeroOut(logFile, SizeOf(logFile));

   logFile.Handler       := log.Handler.pDefault;
   logFile.FlushOnWrite  := log.Settings.FlushOnWrite;
   logFile.Tag           := log.Settings.Tag;

   logFile.VerboseEnabled := log.Settings.VerboseEnabled;
   logFile.LogEndTimeDate := log.Settings.EndTimeDate;
end;

function TLogUtils.Make(): PLog;
begin
   new(Result);

   if(Result <> nil) then
      Init(Result^);
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
   Result := stdlog.Ok();
end;

procedure TLogUtils.InitStd(const fn, logh: StdString; mode: longint);
begin
   if(log.Settings.HandleLogs) and (not stdlog.Flags.Initialized) then begin
      {initialize the standard log file}
      stdlog.Initialize(fn, logh, mode);

      if(stdlog.Error = logeNONE) then
         {open the standard log file}
         stdlog.Open();

      if(stdlog.Error = 0) then begin
         {$IFNDEF ANDROID}
         if(IsConsole) then
            writeln('Initialized standard log file(' + stdlog.FileName + ')');
         {$ELSE}
         logi('Initialized standard log file(' + stdlog.FileName + ')');
         {$ENDIF}
      end else begin
         {$IFNDEF ANDROID}
         if(IsConsole) then
            writeln('Failed to initialize stdlog(' + stdlog.FileName + '). Error: ', stdlog.Error, ',', stdlog.IoError);
         {$ELSE}
         {$IFNDEF NOLOG}
         loge('Failed to initialize stdlog(' + stdlog.FileName + '). Error: ' + sf(stdlog.Error) + ',' + sf(stdlog.IoError));
         {$ENDIF}
         {$ENDIF}
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

procedure TLogUtils.s(priority: longint; const logString: StdString); inline;
begin
   stdlog.s(priority, logString);
end;

procedure TLogUtils.i(const logString: StdString); inline;
begin
   stdlog.i(logString);
end;

procedure TLogUtils.i();
begin
   stdlog.i('');
end;

procedure TLogUtils.e(const logString: StdString); inline;
begin
   stdlog.e(logString);
end;

procedure TLogUtils.w(const logString: StdString); inline;
begin
   stdlog.w(logString);
end;

procedure TLogUtils.d(const logString: StdString); inline;
begin
   stdlog.d(logString);
end;

procedure TLogUtils.v(const logString: StdString); inline;
begin
   stdlog.v(logString);
end;

procedure TLogUtils.f(const logString: StdString); inline;
begin
   stdlog.f(logString);
end;

procedure TLogUtils.k(const logString: StdString);
begin
   stdlog.k(logString);
end;

procedure TLogUtils.Flush(); inline;
begin
   stdlog.Flush();
end;

procedure TLogUtils.SetDefaultHandler(const newHandler: tLogHandler);
begin
   Handler.pDefault := @newHandler;
   stdlog.Handler := @newHandler;
end;

procedure TLogUtils.Enter(const title: StdString);
begin
   stdlog.Enter(title);
end;

procedure TLogUtils.Collapsed(const title: StdString);
begin
   stdlog.Collapsed(title);
end;

procedure TLogUtils.Leave(); inline;
begin
   stdlog.Leave();
end;

function TLog.Initialize(const fn, logh: StdString; mode: longint): boolean;
begin
   Result := false;

   {$IFNDEF NOLOG}
   {no filename provided, exit}
   if(log.Settings.HandleLogs) and (fn <> '') and (not Flags.Initialized) then begin
      {$IFDEF LOG_THREAD_SAFE}
      InitCriticalSection(LogCS);
      {$ENDIF}

      if(Handler = nil) then
         Handler := @log.Handler.Dummy;

      {store stuff}
      FileName   := log.Settings.Path + fn;
      LogHeader  := logh;
      FileMode   := mode;

      if(log.Settings.UseHandlerFileExtension) then
         FileName := ExtractAllNoExt(FileName) + '.' + Handler^.FileExtension;

      Handler^.Init(@self);

      if(Error = 0) then begin
         Flags.Initialized := true;
         Result := true;
      end;
   end;
   {$ELSE}
   Handler := @log.Handler.Dummy;
   FileName   := fn;
   LogHeader  := logh;
   FileMode   := mode;
   {$ENDIF}
end;

procedure TLog.Dispose();
begin
   if(ChainLog <> nil) then
      ChainLog^.Dispose();

   FileName := '';
   Handler^.Dispose(@self);
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

      if(not Self.Handler^.NeedOpen) then begin
         Flags.Opened := true;
         Flags.Ok := true;
         exit;
      end;

      if(Flags.Initialized) then begin
         Handler^.Open(@self);

         if(not Flags.Error) then begin
            Flags.Opened := true;
            Flags.Ok := true;

            Handler^.Start(@self);

            {write down the log header(if one exists)}
            if(LogHeader <> '') and (not Handler^.NoHeader) then begin
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

      Flags.Opened := false;
      Flags.Ok := false;
      Flags.Closing := false;

      {close the file and set the state}
      Handler^.Close(@self);
   end else begin
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
   if(ChainLog <> nil) and (flags.CloseChained) then begin
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
       Handler^.Del(@self);
   end;
   {$ENDIF}
end;

procedure TLog.DeInitialize();
var
   wasOk: boolean;

begin
   {$IFNDEF NOLOG}
   Error := logeNONE;

   if(log.settings.HandleLogs <> false) and (Flags.Initialized) then begin
      wasOk := Flags.Ok;

      {if the file is opened try to close it}
      if(Flags.Opened) then begin
         Close();

         if(Error <> logeNONE) then
            exit;
      end;

      Flags.Initialized := false;
      Flags.Ok := false;

      {we can no longer use the CS}
      {$IFDEF LOG_THREAD_SAFE}
      if(wasOk) then
         DoneCriticalSection(LogCS);
      {$ENDIF}
   end;
   {$ENDIF}
end;

function TLog.Ok(): boolean;
begin
   {$IFNDEF NOLOG}
   Result := Flags.Ok;
   {$ENDIF}
end;

procedure TLog.SetErrorState();
begin
   SetErrorState(logeNONE);
end;

procedure TLog.SetErrorState(errorCode: longint);
begin
   {$IFNDEF NOLOG}
   Error       := errorCode;
   Flags.Error := true;

   {$IFNDEF NO_THREADS}
   if(Flags.Ok) then
      DoneCriticalSection(LogCS);
   {$ENDIF}

   Flags.Ok    := false;
   {$ENDIF}
end;

procedure TLog.QuickOpen(const fn, logh: StdString; mode: longint; var newHandler: TLogHandler);
begin
   {$IFNDEF NOLOG}
   log.Init(self);
   Handler := @newHandler;
   Initialize(fn, logh, mode);
   Open();
   {$ENDIF}
end;

procedure TLog.Reset();
begin
   Close();
   Open();
end;

procedure TLog.s(priority: longint; const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(priority, logString, false);
   {$ENDIF}
end;

procedure TLog.s(priority: longint; args: array of const);
{$IFNDEF NOLOG}
var
   index: loopint;
   logString: StdString = '';
{$ENDIF}

begin
   {$IFNDEF NOLOG}
   for index := 0 to high(args) do begin
      case args[index].VType of
         vtInteger:     logString := logString + sf(args[index].VInteger);
         vtInt64:       logString := logString + sf(args[index].VInt64^);
         vtQWord:       logString := logString + sf(args[index].VQWord^);
         vtBoolean:     logString := logString + sf(args[index].VBoolean);
         vtAnsiString:  logString := logString + AnsiString(args[index].VAnsiString^);
         vtWideString:  logString := logString + UTF8Encode(WideString(args[index].VWideString^));
         vtString:      logString := logString + args[index].VString^; {shortstring}
         vtChar:        logString := logString + args[index].VChar;
         vtPointer:     logString := logString + addr2str(args[index].VPointer);
      end;
   end;

   HandlerWriteln(priority, logString, false);
   {$ENDIF}
end;

procedure TLog.Flush();
begin
   {$IFNDEF NOLOG}
   if(Flags.Ok) then begin
      {$IFDEF LOG_THREAD_SAFE}
      EnterCriticalSection(LogCS);
      {$ENDIF}

      Handler^.Flush(@self);

      {$IFDEF LOG_THREAD_SAFE}
      LeaveCriticalSection(LogCS);
      {$ENDIF}
   end;
   {$ENDIF}
end;

procedure TLog.FlushChain();
begin
   {$IFNDEF NOLOG}
   Flush();

   if(ChainLog <> nil) then
      ChainLog^.FlushChain();
   {$ENDIF}
end;

procedure TLog.i(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcINFO, logString, false);
   {$ENDIF}
end;

procedure TLog.i(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcINFO, args);
   {$ENDIF}
end;

procedure TLog.i();
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcINFO, '', false);
   {$ENDIF}
end;

procedure TLog.e(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcERROR, logString, false);
   {$ENDIF}
end;

procedure TLog.e(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcERROR, args);
   {$ENDIF}
end;

procedure TLog.w(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcWARNING, logString, false);
   {$ENDIF}
end;

procedure TLog.w(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcWARNING, args);
   {$ENDIF}
end;

procedure TLog.d(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcDEBUG, logString, false);
   {$ENDIF}
end;

procedure TLog.d(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcDEBUG, args);
   {$ENDIF}
end;

procedure TLog.v(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   if(verboseEnabled) then
      HandlerWriteln(logcVERBOSE, logString, false);
   {$ENDIF}
end;

procedure TLog.v(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcVERBOSE, args);
   {$ENDIF}
end;

procedure TLog.f(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcFATAL, logString, false);
   {$ENDIF}
end;

procedure TLog.f(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcFATAL, args);
   {$ENDIF}
end;

procedure TLog.k(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   HandlerWriteln(logcOK, logString, false);
   {$ENDIF}
end;

procedure TLog.k(args: array of const);
begin
   {$IFNDEF NOLOG}
   s(logcOK, args);
   {$ENDIF}
end;

procedure TLog.Enter(const title: StdString; collapsed: boolean);
begin
   {$IFNDEF NOLOG}
   if(Flags.Ok) then begin
      Handler^.EnterSection(@self, title, collapsed);
      inc(SectionLevel);
      assert(SectionLevel < logcMAX_SECTIONS, 'Too many log sections, increase logcMAX_SECTIONS. At section: ' + title);
   end;

   if(ChainLog <> nil) then
      ChainLog^.Enter(title, collapsed);
   {$ENDIF}
end;

procedure TLog.Enter(const title: StdString);
begin
   Enter(title, false);
end;

procedure TLog.Collapsed(const title: StdString);
begin
   Enter(title, true);
end;

procedure TLog.Leave();
begin
   {$IFNDEF NOLOG}
   if Flags.Ok and (SectionLevel > 0) then begin
      Handler^.LeaveSection(@self);

      dec(SectionLevel);
   end;

   if(ChainLog <> nil) then
      ChainLog^.Leave();
   {$ENDIF}
end;

{ HANDLER }

procedure TLog.HandlerWriteln(priority: longint; const logString: StdString; noChainLog: boolean);
begin
   {$IFNDEF NOLOG}
   if(Flags.Ok) then begin
      {$IFDEF LOG_THREAD_SAFE}
      EnterCriticalSection(LogCS);
      {$ENDIF}

      Handler^.Writeln(@self, priority, logString);

      if(FlushOnWrite) then
         Handler^.Flush(@self);

      {$IFDEF LOG_THREAD_SAFE}
      LeaveCriticalSection(LogCS);
      {$ENDIF}
   end;

   if(ChainLog <> nil) and (not noChainLog) then
      ChainLog^.HandlerWriteln(priority, logString, false);
   {$ENDIF}
end;

procedure TLog.HandlerWritelnRaw(const logString: StdString);
begin
   {$IFNDEF NOLOG}
   if(Flags.Ok) then begin
      {$IFDEF LOG_THREAD_SAFE}
      EnterCriticalSection(LogCS);
      {$ENDIF}

      Handler^.WritelnRaw(@self, logString);

      if(FlushOnWrite) then
         Handler^.Flush(@self);

      {$IFDEF LOG_THREAD_SAFE}
      LeaveCriticalSection(LogCS);
      {$ENDIF}
   end;
   {$ENDIF}
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

   {initialize handlers}
   log.Handler.Dummy.Create();
   log.Handler.Standard.Create();
   log.Handler.Console.Create();

   log.SetDefaultHandler(log.Handler.Standard);
end;

procedure RuntimeError();
begin
   stdlog.FlushChain();
   ExitProc := oldExitProc;
end;

INITIALIZATION
   log.TabString := #9#9#9#9#9 + #9#9#9#9#9 + #9#9#9#9#9 + #9#9#9#9#9;
   log.SpaceString := '                                 ';

   consoleColors[0] := ConsoleUtils.console.InitialTextColor;

   {$IFNDEF NOLOG}
   Init();
   log.Init(stdlog);
   {standard log closes all chained logs by default}
   stdlog.Flags.CloseChained := true;

   {setup console log}
   log.Init(consoleLog);
   {$IFNDEF ANDROID}
   consoleLog.QuickOpen('console', '', logcREWRITE, log.Handler.Console);
   consoleLog.LogEndTimeDate := false;
   stdlog.ChainLog := @consoleLog;
   {$ENDIF}

   {store the old exit proc and set the new one}
   oldExitProc := ExitProc;
   ExitProc := @RunTimeError;
   {$ENDIF}

FINALIZATION
   {$IFNDEF NOLOG}
   log.DeInitStd();
   {$ENDIF}

END.
