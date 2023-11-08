{
   oxuconHelp, help console commands
   Copyright (C) 2021 Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuconDefaultCommands;

INTERFACE

   USES
      uStd, uLog, StringUtils, ConsoleUtils,
      {app}
      appuActionEvents,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend, oxuConsole, oxuRun;

IMPLEMENTATION

CONST
   cidCON            = 00;
   cidQUIT           = 01;
   cidCLEAR_CONSOLE  = 02;
   cidRESTART        = 03;

   conCommands: array[0..3] of conTCommand = (
      (sID: 'con'; sHelp: 'console setup'; nID: cidCON),
      (sID: 'quit'; sHelp: 'quit the program'; nID: cidQUIT),
      (sID: 'clear_console'; sHelp: 'clears the attached console (terminal) output'; nID: cidCLEAR_CONSOLE),
      (sID: 'restart'; sHelp: 'Restarts the program'; nID: cidRESTART)
   );

VAR
   conHandler: conTHandler;

procedure consoleWriteSettings();
begin
   oxConsole.Console.i('   Alpha enabled : ' + sf(oxConsole.Alpha) + '.');
   oxConsole.Console.i('   Alpha value   : ' + sf(oxConsole.Colors.Background[3]));
   oxConsole.Console.i('   Fullscreen    : ' + sf(oxConsole.Fullscreen) + '.');
end;

procedure conWriteInvalidArgument();
begin
   oxConsole.Console.w('The specified argument or value is not valid.');
end;

procedure conWriteInsufficientArguments();
begin
   oxConsole.Console.w('Insufficient arguments.');
end;

procedure consoleCommand(var con: conTConsole);
var
   i: loopint;
   cmd: StdString;

begin
   if(con.arguments.n > 1) then begin
      cmd := LowerCase(con.arguments.list[1]);
      con.SkipHistoryCurrent := true;

      if(cmd = 'info') then begin
         con.i('Console information: ');
         consoleWriteSettings();
         oxConsole.Console.i();
      end else if(cmd = 'history') then begin
         for i := 0 to (con.History.Entries.n - 1) do
            con.s(con.History.Entries.List[i]);
      end else if(cmd = 'fullscreen') then begin
         oxConsole.Fullscreen := not oxConsole.Fullscreen;
         log.i('Console fullscreen set to: ' + sf(oxConsole.Fullscreen));
         oxConsole.AdjustSize();
      end else
         con.w('Unknown or unsupported console command.');
   end else
      con.w('No console command arguments specified.');
end;

procedure conCommandNotify(var con: conTConsole);
begin
   case con.CommandID of
      cidCON:
         consoleCommand(con);
      cidQUIT:
         appActionEvents.QueueQuitEvent();
      cidRESTART:
         oxRun.Restart();
      cidCLEAR_CONSOLE:
         ConsoleUtils.console.Clear();
      else
         con.e('Error: Unknown console command.');
   end;
end;

procedure Initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

INITIALIZATION
   ox.Init.Add('console.default', @Initialize);

END.
