{
   oxuConsoleBackend, command console backend, previously known as dConsole
   Copyright (c) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuConsoleBackend;

INTERFACE

   USES sysutils, uStd, StringUtils, uColors, uLog;

CONST
   {actions}
   CON_ACTION_ACTIVATE           = $0000;
   CON_ACTION_DEACTIVATE         = $0001;
   CON_ACTION_INITIALIZE         = $0002;
   CON_ACTION_DEINITIALIZE       = $0003;
   CON_ACTION_PROCESS_ENTRY      = $0004;
   CON_ACTION_PROCESS_ENTRY_END  = $0005;

   CON_RESULT_IGNORE             = -1;
   CON_RESULT_FALSE              = 0;
   CON_RESULT_TRUE               = 1;

TYPE
   {CONSOLE LINE}
   conPLine = ^conTLine;
   conTLine = record
      Time: TTime;
      Typ: word;
      Txt: StdString;
      Color: TColor4ub;
   end;

   conTLines = specialize TSimpleList<conTLine>;

   conPConsole = ^conTConsole;

   {CONSOLE ENTRY HANDLER}
   conPEntryHandlerFunc = ^conTEntryHandlerFunc;
   conTEntryHandlerFunc = function(con: conPConsole): boolean;

   {color information for an console}
   conPColor = ^conTColor;
   conTColor = TColor4ub;

   {call procedure parameter}
   conPArgument = ^conTArgument;
   conTArgument = packed record
      VarType: byte;
      MaxSize: word;
   end;

   conPArguments = ^conTArgument;
   conTArguments = array[0..31] of conTArgument;

   conPCallArguments = ^conTCallArguments;
   conTCallArguments = record
      Args: ppointer;
      nArgs: longint;
   end;


   {COMMANDS}
   conTSimpleComandCallback = procedure(con: conPConsole);

   conTSimpleComand = record
      sID: StdString;
      Callback: conTSimpleComandCallback;
   end;

   {command notification procedure}
   conTCommandNotifyProc = procedure(con: conPConsole; nID: longint);

   {command}
   conPCommand = ^conTCommand;
   conTCommand = record
      sID: StdString;
      sHelp: StdString;
      nID: word;
   end;

   {commands}
   conPCommands = ^conTCommands;
   conTCommands = array[0..127] of conTCommand;

   {CONSOLE HANDLER}
   conPHandler = ^conTHandler;
   conTHandler = record
      Notify: conTCommandNotifyProc;
      nCommands: longint;
      Commands: conPCommands;
      Next: conPHandler;
   end;

   conTEntryHandlerFuncs = specialize TSimpleList<conTEntryHandlerFunc>;

   {LOGGING}
   conTConsoleHandlerActionFunc = function(a: longint): longint;

   {CONSOLE RECORD}

   conTSimpleCommands = specialize TSimpleList<conTSimpleComand>;

   { conTConsole }

   conTConsole = record
      {name of the console}
      Name: StdString;

      {is the console initialized}
      Initialized,
      {is the console active(shown)}
      Active,
      {display possible command matches}
      DisplayPossibleMatches,
      {skip history for the current entry}
      SkipHistoryCurrent,
      {write to standard out}
      StdOut: boolean;

      {error code}
      Error: longint;

      {current entry}
      Entry: StdString;

      {output to a log handler}
      LogOutput: PLog;

      {color}
      Colors: record
         Error,
         Warning,
         Command,
         Debug,
         Statement,
         Verbose,
         Fatal,
         Ok,
         Current: TColor4ub;
      end;

      {console contents}
      Contents: conTLines;

      {entry history}
      History: record
         Pos: longint;
         Entries: TSimpleStringList;
         EntryChanged: boolean;
      end;

      {arguments}
      Arguments: TSimpleStringList;

      {entry handlers}
      EntryHandlers: conTEntryHandlerFuncs;

      {command handlers}
      CommandHandlers: record
         n: longint;
         s,
         e: conPHandler;
      end;

      {contains simple commands}
      Commands: conTSimpleCommands;
      {handler for the default commands}
      DefaultCommandsHandler: conTHandler;

      {console handler}
      ActionHandler: conTConsoleHandlerActionFunc;

      procedure eRaise(err: longint);
      procedure ErrorReset();

      {select a console on which operations are to be performed}
      procedure Select();

      {INITIALIZATION}
      procedure Initialize();
      procedure DeInitialize();
      procedure SetDefaultSizes();

      {DISPOSING}
      {dispose of the console data}
      procedure Dispose();

      {PROCESS}
      procedure ResetEntry();
      function PerformCommand(): boolean;
      function PerformSimpleCommand(): boolean;

      {processes a console entry}
      procedure ProcessEntry();
      procedure ProcessEntry(const newEntry: StdString);
      {executes console commands from a file}
      procedure Exec(const fn: StdString);

      {send an action signal to the console handler}
      function Action(a: longint): longint;

      {ACTIVATION/DEACTIVATION}
      procedure Activate();
      procedure DeActivate();
      procedure Reset();

      {ENTRY HISTORY}
      {clear the history}
      procedure ClearHistory();
      {add the entry to the history}
      procedure AddHistory(const st: StdString);
      {dispose of the console history}
      procedure DisposeHistory();

      {ARGUMENTS}
      {clear the arguments}
      procedure ClearArguments();

      {CONTENTS}
      {set the size of the contents}
      procedure SetContentsSize(size: longint);
      {dispose of the console contents}
      procedure DisposeContents();
      {clear the contents}
      procedure Clear();

      {ENTRY HANDLERS}
      {add a console entry handler}
      procedure AddHandler(handler: conTEntryHandlerFunc);
      {clear the handlers}
      procedure DisposeHandlers();

      {COMMAND HANDLERS}
      procedure AddCommand(const command: StdString; callback: conTSimpleComandCallback);
      function FindCallback(const command: StdString): conTSimpleComandCallback;

      {adds a command handler}
      procedure AddHandler(var handler: conTHandler);
      procedure AddHandler(out handler: conTHandler; notify: conTCommandNotifyProc; var cmds: array of conTCommand);
      {finds a command}
      function FindCommand(var cmd: StdString; out c: conPCommand): conPHandler;
      {disposes all command handlers}
      procedure DisposeCHandlers();

      {WRITTING TO THE CONSOLE}
      {write to the console directly, bypassing any other output (skip log files)}
      procedure RawWriteln(const s: StdString; const clr: conTColor);
      {write with a custom color}
      procedure Writeln(const s: StdString; const clr: conTColor);
      {normal write (informative)}
      procedure i(const s: StdString);
      procedure i();

      {error writing}
      procedure e(const s: StdString);
      {warning writing}
      procedure w(const s: StdString);
      {debug writing}
      procedure d(const s: StdString);
      {verbose writing}
      procedure v(const s: StdString);
      {fatal writing}
      procedure f(const s: StdString);
      {ok writing}
      procedure k(const s: StdString);

      {writing commands}
      procedure cmdWriteln();

      {writing statements}
      procedure s(const st: StdString);
      {log something}
      procedure log(priority: loopint; const st: StdString);

      {SETTING COLORS}
      {sets 3 colors rgb for the text, opaque}
      procedure Color3ub(r, g, b: byte);
      {sets 4 colors rgba for the text, with transparency}
      procedure Color4ub(r, g, b, a: byte);
      {same as conColor3ub, only takes an entire value instead of 3 individual ones}
      procedure Color3ubv(const clr: TColor3ub);
      {same as conColor3ub, only takes an entire value instead of 4 individual ones}
      procedure Color4ubv(const clr: TColor4ub);
   end;

TYPE

   { conTConsoleGlobal }

   conTConsoleGlobal = record
      StdOut: boolean;

      {the selected console}
      Selected: conPConsole;

      {initialize a console record}
      procedure Init(out con: conTConsole);
      {make a console}
      function Make(): conPConsole;

      {dispose of the console data}
      procedure Dispose(var con: conPConsole);

      {WRITTING TO THE CONSOLE}
      procedure i(const s: StdString);
      procedure i();

      {error writing}
      procedure e(const s: StdString);
      {warning writing}
      procedure w(const s: StdString);
      {debug writing}
      procedure d(const s: StdString);
      {verbose writing}
      procedure v(const s: StdString);
      {fatal writing}
      procedure f(const s: StdString);

      {SETTING COLORS}
      {sets 3 colors rgb for the text, opaque}
      procedure Color3ub(r, g, b: byte);
      {sets 4 colors rgba for the text, with transparency}
      procedure Color4ub(r, g, b, a: byte);
      {same as conColor3ub, only takes an entire value instead of 3 individual ones}
      procedure Color3ubv(const clr: TColor3ub);
      {same as conColor3ub, only takes an entire value instead of 4 individual ones}
      procedure Color4ubv(const clr: TColor4ub);
   end;

VAR
   console: conTConsoleGlobal;

IMPLEMENTATION

CONST
   cidCLEAR = 00;

   defaultCommands: array[0..1] of conTCommand = (
      (sid: 'cls'; sHelp: 'clear console'; nID: cidCLEAR),
      (sid: 'clear'; sHelp: 'clear console'; nID: cidCLEAR)
   );

procedure defaultCommandNotify(var con: conTConsole; nID: longint);
begin
   case nID of
      cidCLEAR:
         con.Clear();
   end;
end;


{ERROR HANDLING}
procedure conTConsole.eRaise(err: longint);
begin
   error := err;
end;

procedure conTConsole.ErrorReset();
begin
   error := 0;
end;

{CONSOLE LINE}
procedure conInitLine(var line: conTLine);
begin
   Zero(line, SizeOf(conTLine));
end;

{CONSOLE}

procedure conTConsole.Initialize();
begin
   SetDefaultSizes();

   if(console.Selected = nil) then
      Select();

   Commands.Initialize(Commands);

   ErrorReset();
   if(Initialized) then
      exit;

   {call the initialization routine}
   if(Action(CON_ACTION_INITIALIZE) = CON_RESULT_FALSE) then
      exit;

   {add the default command handler}
   AddHandler(DefaultCommandsHandler, conTCommandNotifyProc(@defaultCommandNotify), defaultCommands);

   {console initialized}
   Initialized := true;
end;

procedure conTConsole.DeInitialize();
begin
   ErrorReset();
   if(not Initialized) then
      exit;

   {deactivate the console}
   DeActivate();

   {call the de-initialization routine}
   if(Action(CON_ACTION_DEINITIALIZE) = CON_RESULT_FALSE) then
      exit;

   {dispose of the console}
   Dispose();

   {console deinitialized}
   Initialized := false;
end;

procedure conTConsole.SetDefaultSizes();
begin
   if(Contents.a = 0) then
      SetContentsSize(128);

   Arguments.RequireAllocate(16);

   History.Entries.RequireAllocate(64);
end;

procedure conTConsole.Select();
begin
   console.Selected := @self;
end;

procedure conDisposeLine(var l: conTLine);
begin
   l.Txt := '';
   conInitLine(l);
end;

procedure conLineMove(var con: conTConsole; count: longint);
var
   i: longint;

begin
   {initialize}
   if(count = 0) or (not con.Initialized) or (con.Contents.a = 0) then
      exit;

   if(count > con.Contents.n) then
      count := con.Contents.n;

   {free the memory of the items to be disposed of}
   for i := 0 to (count - 1) do
      conDisposeLine(con.Contents.List[i]);

   {move the contents up}
   if(count < con.Contents.a) then
      for i := count to (con.Contents.n - 1) do
         con.Contents.List[i - count] := con.Contents.List[i];
end;

procedure conLineMoveHistory(var con: conTConsole; count: word);
var
   i: longint;

begin
   {initialize}
   if(count = 0) or (not con.Initialized) or (con.History.Entries.a = 0) then
      exit;

   if(count > con.History.Entries.n) then
      count := con.History.Entries.n;

   {free the memory of the items to be disposed of}
   for i := 0 to (count - 1) do
      con.History.Entries.List[i] := '';

   {move the History up}
   if(count < con.History.Entries.a) then
      for i := count to (con.History.Entries.n - 1) do
         con.History.Entries.List[i - count] := con.History.Entries.List[i];
end;

procedure conTConsole.Dispose();
begin
   DisposeContents();
   Arguments.Dispose();
   DisposeHistory();
   Commands.Dispose();
   DisposeHandlers();
   DisposeCHandlers();
end;

{ PROCESS }

function conProcessArguments(var con: conTConsole): boolean;
var
   arg,
   entry: StdString;

begin
   {initialize}
   Result := false;

   if(con.Initialized) and (con.Arguments.a > 0) then begin
      con.Arguments.n := 0;

      if(length(con.Entry) > 0) then begin
         entry := con.Entry;

         repeat
            StripLeadingWhiteSpace(entry);

            arg := CopyToDel(entry);
            if(arg = '') and (length(entry) <> 0) then
               continue;

            con.Arguments.List[con.Arguments.n] := arg;
            inc(con.Arguments.n);
         until (length(entry) = 0) or (con.Arguments.n = con.Arguments.a);

         if(con.Arguments.n > 0) then
            Result := true;
      end;
   end;
end;

procedure conTConsole.ResetEntry();
begin
   Entry := '';
end;

{performs a command}
function conTConsole.PerformCommand(): boolean;
var
   cur: conPHandler = nil;
   cmd: conPCommand = nil;

begin
   Result := false;

   if(Arguments.n > 0) then begin
      cur := FindCommand(Arguments.List[0], cmd);

      if(cur <> nil) then begin
         if(cur^.Notify <> nil) then begin
            cur^.Notify(@self, cmd^.nID);
            exit(true);
         end
      end;
   end;
end;

function conTConsole.PerformSimpleCommand(): boolean;
var
   callback: conTSimpleComandCallback;

begin
   Result := false;

   if(Arguments.n > 0) then begin
      callback := FindCallback(Arguments.list[0]);

      if(callback <> nil) then begin
         callback(@self);
         exit(true);
      end;
   end;
end;

CONST
   cECHO_NORMAL         = 0000;
   cECHO_ERROR          = 0001;
   cECHO_STATEMENT      = 0002;

function isEcho(var con: conTConsole): boolean;
begin
   if(con.Arguments.n > 0) then
      if(pos('echo', lowercase(con.Arguments.List[0])) > 0) then
         exit(true);

   Result := False;
end;

procedure conTConsole.ProcessEntry();
var
   Result: boolean;
   ni: longint;
   sArg: StdString;

label endit;

procedure echo(delc, typ: longint);
begin
   sArg := Entry;
   delete(sArg, 1, delc);

   if(sArg <> '') then
      if(typ = cECHO_NORMAL) then
         i(sArg)
      else if(typ = cECHO_ERROR) then
         e(sArg)
      else if(typ = cECHO_STATEMENT) then
         s(sArg);
end;

begin
   ClearArguments();

   {remove white space}
   StripWhiteSpace(Entry);

   if(Entry <> '') then begin
      {add to history and process the arguments}
      conProcessArguments(self);

      if(not isEcho(self)) then
         cmdWriteln();

      {check for a simple command}
      if(PerformSimpleCommand()) then
         goto endit;

      {check for a command}
      if(PerformCommand()) then
         goto endit;

      {otherwise a entry handler}
      if(Arguments.n > 0) then begin
         {first, try to see if any arguments can be processed by the console itself}
         sArg := LowerCase(Arguments.list[0]);

         {close the console}
         if(sArg = 'close') or (sArg = 'exit') then begin
            DeActivate();
            goto endit;
         {echo commands}
         end else if(sArg = 'echo') then begin
            echo(5, cECHO_NORMAL);
            goto endit;
         end else if(sArg = 'echoe') then begin
            echo(7, cECHO_ERROR);
            goto endit;
         end else if(sArg = 'echos') then begin
            echo(7, cECHO_STATEMENT);
            goto endit;
         {execute a console command file}
         end else if(sArg = 'conexec') then begin
            sArg := Entry;
            delete(sArg, 1, 8);

            if(sArg <> '') then begin
               s('Executing console command file: ' + sArg);
               Exec(sArg);
            end else
               e('Error: File name not specified.');

            goto endit;
         end;

         {call the primary entry processing routine}
         Result := Action(CON_ACTION_PROCESS_ENTRY) = CON_RESULT_TRUE;

         {if the primary entry processing routine failed to process the entry,
         then call all the other entry handlers.}
         if(not Result) and (EntryHandlers.n > 0) and (Arguments.n > 0) then begin
            for ni := 0 to (EntryHandlers.n - 1) do begin
               if(EntryHandlers.list[ni] <> nil) then
                  Result := EntryHandlers.list[ni](@self);

               if(Result) then
                  break;
            end;
         end;

         if(not Result) then
            e('Invalid or unknown command: ' + arguments.list[0]);
      end;

endit:
      {save whatever was entered into the history, except if the current entry is skipped}
      if(not SkipHistoryCurrent) then
         AddHistory(Entry)
      else
         SkipHistoryCurrent := false;

      {free the memory used by arguments and reset the entry}
      ClearArguments();
      ResetEntry();

      Result := Action(CON_ACTION_PROCESS_ENTRY_END) = CON_RESULT_TRUE;
   end;
end;

procedure conTConsole.ProcessEntry(const newEntry: StdString);
begin
   Entry := newEntry;
   ProcessEntry();
end;

procedure conTConsole.Exec(const fn: StdString);
var
   fl: text;
   ln: StdString;

begin
   {initialize}
   ioE := 0;
   ZeroOut(fl, SizeOf(fl));

   {open the file}
   Assign(fl, fn);
   system.Reset(fl);

   if(ioerror() <> 0) then begin
      e('IO Error(' + sf(ioE) + '): Unable to open file.');
      exit;
   end;

   {read and execute}
   repeat
      ReadLn(fl, ln);

      if(ioerror <> 0) then begin
         e('IO Error(' + sf(ioE) + '): Cannot read file.');
         break;
      end;

      ProcessEntry(ln);
   until eof(fl);

   {close the file}
   Close(fl);

   if(ioerror() <> 0) then begin
      e('IO Error(' + sf(ioE) + '): Unable to close the file.');
      exit;
   end;
end;

function conTConsole.Action(a: longint): longint;
begin
   if(ActionHandler <> nil) then
      exit(ActionHandler(a));

   Result := CON_RESULT_IGNORE;
end;

{ACTIVATION/DEACTIVATION}
procedure conTConsole.Activate();
begin
   ErrorReset();

   if(Initialized) and (not Active) then begin
      {call the activation routine}
      if(Action(CON_ACTION_ACTIVATE) = CON_RESULT_FALSE) then
         exit;

      {console activated}
      Active := true;
   end;
end;

procedure conTConsole.DeActivate();
begin
   ErrorReset();

   if(Initialized) and (Active) then begin
      {call the activation routine}
      if(Action(CON_ACTION_DEACTIVATE) = CON_RESULT_FALSE) then
         exit;

      {console deactivated}
      Active := false;
   end;
end;

procedure conTConsole.Reset();
begin
   ErrorReset();

   if(Initialized) and (Active) then begin
      DeActivate();
      Activate();
   end;
end;

{HISTORY MANAGEMENT}

procedure conTConsole.ClearHistory();
var
   ni: longint;

begin
   if(History.Entries.n > 0) then begin
      {free memory used by content data}
      for ni := 0 to (History.Entries.n - 1) do
         History.Entries.List[ni] := '';
   end;

   History.Entries.n := 0;
end;

procedure conTConsole.AddHistory(const st: StdString);
var
   ni,
   j: longint;
   temp: StdString = '';

begin
   {initialize}
   ErrorReset();
   if(History.Entries.a = 0) then
      exit;

   {first check if the same string has already been entered}
   if(History.Entries.n > 0) then
      for ni := 0 to (History.Entries.n - 1) do begin
         {if the same string is already in history then we will move it to top, only if the string is not already on top}
         if(History.Entries.List[ni] = st) and (ni < (History.Entries.n - 1)) then begin
            temp := History.Entries.List[ni];

            {stack back the other entries}
            for j := ni to (History.Entries.n - 2) do
               History.Entries.List[j] := History.Entries.List[j + 1];

            {put the string on the top}
            History.Entries.List[History.Entries.n - 1] := temp;
         end;
      end;

   {move to the next line or move or lines by 1}
   if(History.Entries.n < History.Entries.a) then
      inc(History.Entries.n)
   else
      conLineMoveHistory(self, 1);

   {write the string to the console history}
   History.Entries.List[History.Entries.n - 1] := st;
end;

procedure conTConsole.DisposeHistory();
begin
   ClearHistory();
   History.Entries.Dispose();
end;

procedure conTConsole.ClearArguments();
var
   ni: longint;

begin
   if(Arguments.n > 0) then begin
      {free memory used by argument data}
      for ni := 0 to (Arguments.n - 1) do
         Arguments.List[ni] := '';

      Arguments.n := 0;
   end;
end;

{CONTENTS}
procedure conTConsole.SetContentsSize(size: longint);
var
   ni: longint;

begin
   Contents.RequireAllocate(size);

   {initialize all contents pointers}
   for ni := 0 to (size - 1) do
      conInitLine(Contents.List[ni]);
end;

procedure conTConsole.DisposeContents();
var
   ni: longint;

begin

   for ni := 0 to (Contents.n - 1) do
      conDisposeLine(Contents.List[ni]);

   Contents.Dispose();
end;

procedure conTConsole.Clear();
var
   ni: longint;

begin
   if(Contents.n > 0) then begin
      {free memory used by content data}
      for ni := 0 to (Contents.n - 1) do
         conDisposeLine(Contents.list[ni]);

      contents.n := 0;
   end;
end;

{ENTRY HANDLERS}

procedure conTConsole.AddHandler(handler: conTEntryHandlerFunc);
begin
   EntryHandlers.Add(handler);
end;

procedure conTConsole.DisposeHandlers();
begin
   EntryHandlers.Dispose();
end;

procedure conTConsole.AddCommand(const command: StdString; callback: conTSimpleComandCallback);
var
   cmd: conTSimpleComand;

begin
   cmd.sID := command;
   cmd.Callback := callback;
   Commands.Add(cmd);
end;

function conTConsole.FindCallback(const command: StdString): conTSimpleComandCallback;
var
   ni: longint;
   sID: StdString;

begin
   if(Commands.n > 0) then begin
      sID := lowercase(command);

      for ni := 0 to (Commands.n - 1) do begin
         if(Commands.List[ni].sID = sID) then
            exit(Commands.List[ni].Callback);
      end;
   end;

   Result := nil;
end;

{COMMAND HANDLERS}

procedure conTConsole.AddHandler(var handler: conTHandler);
begin
   inc(CommandHandlers.n);
   handler.Next := nil;

   if(CommandHandlers.s = nil) then
      CommandHandlers.s := @handler
   else
      CommandHandlers.e^.Next := @handler;

   CommandHandlers.e := @handler;
end;

procedure conTConsole.AddHandler(out handler: conTHandler; notify: conTCommandNotifyProc; var cmds: array of conTCommand);
begin
   ZeroOut(handler, SizeOf(handler));

   handler.Notify := notify;
   handler.Commands := @cmds[0];
   handler.nCommands := high(cmds) + 1;

   AddHandler(handler);
end;

function conTConsole.FindCommand(var cmd: StdString; out c: conPCommand): conPHandler;
var
   cur: conPHandler;
   ni: longint;

begin
   Result := nil;
   c := nil;

   cur := CommandHandlers.s;
   {there must be at least 1 handler and 1 argument}
   if(cur <> nil) and (Arguments.n > 0) then begin
      cmd := LowerCase(Arguments.List[0]);

      {go through each handler}
      repeat
         if(cur^.nCommands > 0) then begin
            {go through each command}
            for ni := 0 to (cur^.nCommands - 1) do begin
               {check if the command matches}
               if(cmd = LowerCase(cur^.Commands^[ni].sID)) then begin
                  {if it matches then notify the command handler}
                  c := @cur^.Commands^[ni];
                  exit(cur);
               end;
            end;
         end;

         {next handler}
         cur := cur^.Next;
      until (cur = nil);
   end;
end;

procedure conTConsole.DisposeCHandlers();
begin
   CommandHandlers.s := nil;
   CommandHandlers.e := nil;
   CommandHandlers.n := 0;
end;

procedure conTConsole.RawWriteln(const s: StdString; const clr: conTColor);
var
   n: longint;

begin
   {$IFDEF WINDOWS}if(isConsole) then{$ENDIF}
   if(StdOut) then
      system.WriteLn(s);

   {initialize}
   ErrorReset();

   if(Contents.a = 0) then
      exit;

   {move to the next line or move or lines by 1}
   if(Contents.n < Contents.a) then
      inc(Contents.n)
   else
      conLineMove(self, 1);

   n := Contents.n - 1;

   {write the string to the console contents}
   if(Length(s) > 0) then begin
      Contents.List[n].Txt   := s;
      Contents.List[n].Color := clr;
      Contents.List[n].Time  := Now();
   end else
      conInitLine(Contents.List[n]);
end;

procedure conTConsole.Writeln(const s: StdString; const clr: conTColor);
begin
   RawWriteln(s, clr);

   if(LogOutput <> nil) then
      LogOutput^.i(s);
end;

procedure conTConsole.i(const s: StdString);
begin
   RawWriteln(s, Colors.Statement);

   if(LogOutput <> nil) then
      LogOutput^.i(s);
end;

procedure conTConsole.i();
begin
   i('');

   if(LogOutput <> nil) then
      LogOutput^.i();
end;

procedure conTConsole.e(const s: StdString);
begin
   RawWriteln(s, Colors.Error);

   if(LogOutput <> nil) then
      LogOutput^.e(s);
end;

procedure conTConsole.w(const s: StdString);
begin
   RawWriteln(s, Colors.Warning);

   if(LogOutput <> nil) then
      LogOutput^.w(s);
end;

procedure conTConsole.d(const s: StdString);
begin
   RawWriteln(s, Colors.Debug);

   if(LogOutput <> nil) then
      LogOutput^.d(s);
end;

procedure conTConsole.v(const s: StdString);
begin
   RawWriteln(s, Colors.Verbose);

   if(LogOutput <> nil) then
      LogOutput^.v(s);
end;

procedure conTConsole.f(const s: StdString);
begin
   RawWriteln(s, Colors.Fatal);

   if(LogOutput <> nil) then
      LogOutput^.f(s);
end;

procedure conTConsole.k(const s: StdString);
begin
   RawWriteln(s, Colors.Ok);

   if(LogOutput <> nil) then
      LogOutput^.k(s);
end;

procedure conTConsole.cmdWriteln();
var
   cmd: StdString;

begin
   cmd := '>' + Entry;
   Writeln(cmd, Colors.Command);

   if(LogOutput <> nil) then
      LogOutput^.i(cmd);
end;

procedure conTConsole.s(const st: StdString);
begin
   Writeln(st, Colors.Statement);

   if(LogOutput <> nil) then
      LogOutput^.i(st);
end;

procedure conTConsole.log(priority: loopint; const st: StdString);
var
   color: TColor4ub;

begin
   if(priority = logcINFO) then
      color := Colors.Statement
   else if(priority = logcWARNING) then
      color := Colors.Warning
   else if(priority = logcERROR) then
      color := Colors.Error
   else if(priority = logcVERBOSE) then
      color := Colors.Verbose
   else if(priority = logcFATAL) then
      color := Colors.Fatal
   else if(priority = logcDEBUG) then
      color := Colors.Debug
   else if(priority = logcOK) then
      color := Colors.Ok;

   RawWriteln(st, color);

   if(LogOutput <> nil) then
      LogOutput^.s(priority, st);
end;

procedure conTConsole.Color3ub(r, g, b: byte);
begin
   Colors.Current[0] := r;
   Colors.Current[1] := g;
   Colors.Current[2] := b;
   Colors.Current[3] := 255;
end;

procedure conTConsole.Color4ub(r, g, b, a: byte);
begin
   Colors.Current[0] := r;
   Colors.Current[1] := g;
   Colors.Current[2] := b;
   Colors.Current[3] := a;
end;

procedure conTConsole.Color3ubv(const clr: TColor3ub);
begin
   PColor3ub(@Colors.Current)^ := clr;
end;

procedure conTConsole.Color4ubv(const clr: TColor4ub);
begin
   Colors.Current := clr;
end;

{ GLOBAL }

procedure conTConsoleGlobal.Init(out con: conTConsole);
begin
   {zero out the con record}
   ZeroOut(con, SizeOf(conTConsole));

   {set the default colors}
   con.Colors.Error.Assign(255, 64, 64, 255);
   con.Colors.Fatal.Assign(255, 0, 0, 255);
   con.Colors.Warning.Assign(255, 255, 64, 255);
   con.Colors.Command.Assign(192, 192, 64, 255);
   con.Colors.Statement.Assign(220, 220, 220, 255);
   con.Colors.Verbose.Assign(127, 127, 127, 255);
   con.Colors.Debug.Assign(192, 192, 255, 255);
   con.Colors.Ok.Assign(64, 255, 64, 255);
   con.Colors.Current.Assign(255, 255, 255, 255);

   con.Commands.Increment := 128;

   con.DisplayPossibleMatches := true;
   con.Arguments.InitializeValues(con.Arguments, 16);
   con.Contents.InitializeValues(con.Contents, 128);
   con.EntryHandlers.InitializeValues(con.EntryHandlers, 16);
   con.History.Entries.InitializeValues(con.History.Entries, 64);
end;

function conTConsoleGlobal.Make(): conPConsole;
var
   con: conPConsole = nil;

begin
   new(con);

   if(con <> nil) then
      console.Init(con^);

   {success}
   Result := con;
end;

procedure conTConsoleGlobal.Dispose(var con: conPConsole);
begin
   if(con <> nil) then begin
      con^.Dispose();
      Dispose(con);
      con := nil;
   end;
end;

procedure conTConsoleGlobal.i(const s: StdString);
begin
   if(Selected <> nil) then
      Selected^.i(s);
end;

procedure conTConsoleGlobal.i();
begin
   if(Selected <> nil) then
      Selected^.i('');
end;

procedure conTConsoleGlobal.e(const s: StdString);
begin
   if(Selected <> nil) then
      Selected^.e(s);
end;

procedure conTConsoleGlobal.w(const s: StdString);
begin
   if(Selected <> nil) then
      Selected^.w(s);
end;

procedure conTConsoleGlobal.d(const s: StdString);
begin
   if(Selected <> nil) then
      Selected^.d(s);
end;

procedure conTConsoleGlobal.v(const s: StdString);
begin
   if(Selected <> nil) then
      Selected^.v(s);
end;

procedure conTConsoleGlobal.f(const s: StdString);
begin
   if(Selected <> nil) then
      Selected^.f(s);
end;

{SETTING COLORS}

procedure conTConsoleGlobal.Color3ub(r, g, b: byte);
begin
   Selected^.Color3ub(r, g, b);
end;

procedure conTConsoleGlobal.Color4ub(r, g, b, a: byte);
begin
   Selected^.Color4ub(r, g, b, a);
end;

procedure conTConsoleGlobal.Color3ubv(const clr: TColor3ub);
begin
   Selected^.Color3ubv(clr);
end;

procedure conTConsoleGlobal.Color4ubv(const clr: TColor4ub);
begin
   Selected^.Color4ubv(clr);
end;

END.
