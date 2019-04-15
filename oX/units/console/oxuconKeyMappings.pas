{
   oxuconKeyMappings, keymappings console extension
   Copyright (C) 2017. Dejan Boras

   Started On:    08.01.2017.

   Configure key mappings via the console
}

{$INCLUDE oxdefines.inc}
UNIT oxuconKeyMappings;

INTERFACE

   USES
      appuKeyMappings,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend;

IMPLEMENTATION

CONST
   cidKM = 0;

   conCommands: array[0..0] of conTCommand = (
      (sid: 'keymap'; sHelp: 'Handles key mappings'; nID: cidKM)
   );

VAR
   conHandler: conTHandler;

procedure listKeyGroup(var con: conTConsole; const g: appTKeyMappingGroup);
var
   i: longint;
   k: appPKeyMapping;

begin
   if(g.Keys.n > 0) then begin
      for i := 0 to (g.Keys.n - 1) do begin
         k := @g.Keys.List[i];
         con.i('   ' + k^.Name + ': ' + k^.ToString() + ' (' + k^.Description + ')');
      end;
   end else
      con.i('   Empty');
end;

procedure listKeyMappings(var con: conTConsole);
var
   i: longint;
   g: appPKeyMappingGroup;

begin
   if(appKeyMappings.Groups.n > 0) then begin
      for i := 0 to (appKeyMappings.Groups.n - 1) do begin
         g := appKeyMappings.Groups.List[i];

         con.w(':' + g^.Name + ' (' + g^.Description + ')');

         listKeyGroup(con, g^);
      end;
   end else
      con.w('No key mappings');
end;

{console commands}
procedure conCommandNotify(var con: conTConsole; {%H-}nID: longint);
var
   cmd: string;

begin
   if(con.arguments.n >= 2) then begin
      cmd := lowercase(con.arguments.list[1]);

      if(cmd = 'list') then
         listKeyMappings(con)
      else
         con.w('Command not recognized/supported: ' + con.arguments.list[1]);
   end else
      con.e('Keymap operation not specified');
end;

procedure Initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.iAdd(initRoutines, 'console.keymappings', @Initialize);

END.
