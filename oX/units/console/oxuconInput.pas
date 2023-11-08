{
   oxuconInput
   Copyright (C) 2019. Dejan Boras

   Manage input devices via console
}

{$INCLUDE oxheader.inc}
UNIT oxuconInput;

INTERFACE

   USES
      uStd, appuController, appuControllers,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend;

IMPLEMENTATION

CONST
   cidCONTROLLER = 0;
   cidCONTROLLERS = 1;

   conCommands: array[0..1] of conTCommand = (
      (sid: 'controller'; sHelp: 'Handles controllers (gamepads/joysticks/inputs)'; nID: cidCONTROLLER),
      (sid: 'controllers'; sHelp: 'Handles controllers (gamepads/joysticks/inputs)'; nID: cidCONTROLLERS)
   );

VAR
   conHandler: conTHandler;

procedure listControllers(var con: conTConsole);
var
   i: loopint;

begin
   if(appControllers.List.n > 0) then begin
      for i := 0 to appControllers.List.n - 1 do begin
         con.i(appControllers.List[i].GetName());
      end;
   end else
      con.i('No controllers detected/supported');
end;

{console commands}
procedure conCommandNotify(var con: conTConsole; {%H-}nID: longint);
var
   cmd: string;

begin
   if(con.arguments.n >= 2) then begin
      cmd := lowercase(con.arguments.list[1]);

      if(cmd = 'list') then
         listControllers(con)
      else
         con.w('Command not recognized/supported: ' + con.arguments.list[1]);
   end else
      con.e('Controller operation not specified');
end;

procedure Initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

INITIALIZATION
   ox.Init.Add('console.input', @Initialize);

END.
