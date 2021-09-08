{
   oxuconHelp, help console commands
   Copyright (C) 2021 Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuconHelp;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend;

IMPLEMENTATION

CONST
   conCommands: array[0..0] of conTCommand = (
      (sid: 'help'; sHelp: 'Handles window operations'; nID: 0)
   );

VAR
   conHandler: conTHandler;

procedure consoleHelp(var con: conTConsole; filter: string = '');
var
   i: loopint;
   handler: conPHandler;
   lfilter, lcommand: string;

   function filterCommand(const command: string): boolean;
   begin
      lcommand := LowerCase(command);

      if(pos(lfilter, lcommand) <= 0) then
        exit(false);

      Result := true;
   end;

begin
   handler := con.CommandHandlers.s;

   if(filter <> '') then
     lfilter := LowerCase(filter);

   while(handler <> nil) do begin
      for i := 0 to handler^.nCommands -1 do begin
         if(filter <> '') and (not filterCommand(handler^.Commands^[i].sID)) then
           continue;

         if(handler^.Commands^[i].sHelp <> '') then
            log.i(handler^.Commands^[i].sID + ' > `' + handler^.Commands^[i].sHelp)
         else
            log.i(handler^.Commands^[i].sID);
      end;

      handler := handler^.Next;
   end;

   for i := 0 to con.Commands.n - 1 do begin
      if(filter <> '') and (not filterCommand(con.Commands.List[i].sID)) then
         continue;

      log.i(con.Commands.List[i].sID);
   end;

   log.i();
end;


{console commands}
procedure conCommandNotify(var con: conTConsole);
var
   filter: string = '';

begin
   if(con.Arguments.n > 1) then
      filter := con.Arguments.List[1];

   consoleHelp(con, filter);
end;

procedure Initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

INITIALIZATION
   ox.Init.Add('console.help', @Initialize);

END.
