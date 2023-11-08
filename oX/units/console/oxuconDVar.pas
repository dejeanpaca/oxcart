{
   oxuconDVar, dvars console extension
   Copyright (C) 2012 Dejan Boras

   Started On:    16.06.2009.

   This unit serves to give the user ability to manipulate and list
   variables via console commands.
}

{$INCLUDE oxdefines.inc}
UNIT oxuconDVar;

INTERFACE

   USES
      uStd, udvars,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend;

IMPLEMENTATION

CONST
   cidLISTVAR           = $0000;
   cidSETVAR            = $0001;
   cidGETVAR            = $0002;
   cidDVARAT            = $0003;

   conCommands: array[0..5] of conTCommand = (
      (sid: 'dvlist'; sHelp: 'list dvar variable(s)'; nID: cidLISTVAR),
      (sid: 'sv'; sHelp: 'set dvar variable'; nID: cidSETVAR),
      (sid: 'setvar'; sHelp: 'set dvar variable(s)'; nID: cidSETVAR),
      (sid: 'lv'; sHelp: 'list dvar variable'; nID: cidLISTVAR),
      (sid: 'getvar'; sHelp: 'get a dvar variable'; nID: cidGETVAR),
      (sid: 'dvar@'; sHelp: 'set the dvar selector to a group'; nID: cidDVARAT));

VAR
   selectedDV: string = '';
   conHandler: conTHandler;

procedure notValidNumValue(var con: conTConsole);
begin
   con.e('The specified value is not a number.');
end;

procedure InsufficientArgs(var con: conTConsole);
begin
   con.e('Insufficient arguments.')
end;

TYPE
   TListVarData = record
      groupName,
      filterVar: string;
      groupsOnly: boolean;
   end;

procedure listVariables(var con: conTConsole; var cG: TDVarGroup; var data: TListVarData);
var
   cV: PDVar;
   subG: PDVarGroup;
   groupWritten: boolean;
   groupName: string;

procedure writeOutGroup();
begin
   if(not groupWritten) then begin
      groupWritten := true;

      if(data.groupName <> '') then
         con.w('< ' + data.groupName + ' >');
   end;
end;

begin
   cV := cG.vs;
   groupWritten := false;
   groupName := data.groupName;

   if(not data.groupsOnly) then begin
      if(cV <> nil) then begin
         repeat
            if(data.filterVar = '') or (pos(LowerCase(data.filterVar), LowerCase(cv^.Name)) <> 0) then begin
               if(not (dvarINVISIBLE in cV^.Properties)) then begin
                  writeOutGroup();
                  con.i(cV^.Name + ' = ' + cV^.GetAsString());
               end;
            end;

            cV := cV^.Next;
         until (cV = nil);
      end;
   end else
      writeOutGroup();

   { go through sub-groups }
   subG := cG.sub.s;
   if(subG <> nil) then repeat
      if(groupName <> '') then
         data.groupName := groupName + '.'  + subG^.Name
      else
         data.groupName := subG^.Name;

      listVariables(con, subG^, data);

      subG := subG^.Next;
   until (subG = nil);
end;

{lists all variables in a console}
procedure listVar(var con: conTConsole);
var
   curG: PDVarGroup;
   data: TListVarData;
   arg: string = '';

begin
   ZeroOut(data, SizeOf(data));

   if(con.Arguments.n > 1) then
      arg := con.Arguments.List[1];

   {if a variable is specified (filter starts with a '.'), then only filter by the variable }
   if(Pos('.', arg) = 1) then begin
      data.filterVar := copy(arg, 2, 255);
   end else if (arg = '-') then
      data.groupsOnly := true
   {if a group is specified, try to filter by group}
   else if(arg <> '') then begin
      curG := dvar.GetGroup(arg);

      if(curG <> nil) then begin
         {found group, list it}
         con.s('Listing group <' + arg + '>:');
         data.groupName := curG^.Name;

         listVariables(con, curG^, data);
      end else
         {did not find a group}
         con.e('Error: Group <' + arg + '> not found.');

      exit;
   end else
      data.groupName := '';

   listVariables(con, dvar.dvars, data);
end;

{gets the value of a variable}
procedure getVar(var con: conTConsole);
var
   pV: PDVar;

begin
   if(con.arguments.n >= 2) then begin
      pV := dvar.Get(con.arguments.list[1]);

      con.i(con.arguments.list[1] + ' = ' + pV^.GetAsString());
   end else
      con.e('dvar not specified');
end;

{sets the value for a variable}
procedure setVar(var con: conTConsole);
var
   pV: PDVar;
   ok: boolean;
   arg: string;

begin
   if(con.arguments.n >= 3) then begin
      arg := con.arguments.list[1];

      {get dvar}
      pV := dvar.Get(arg);
      if(pV <> nil) then begin
         if(dvarREADONLY in pv^.Properties) then begin
            con.w('dvar ' + arg + ' is read only');
            exit;
         end;

         {set value and check for errors}
         ok := pV^.AssignFromString(con.arguments.list[2]);

         if(ok) then begin
            con.s('Set dvar ' + arg + ' to value: ' + con.arguments.list[2])
         end else
            con.e('Failed to set dvar ' + arg + ' to value: ' + con.arguments.list[2]);
      end else
         con.e('No variable found(' + (arg) + ')');
   end else
      InsufficientArgs(con);
end;

{sets the value of the dvar selector}
procedure dvarAt(con: conTConsole);
begin
   if(con.arguments.list[1] <> '') then begin
      selectedDV := con.arguments.list[1];
   end else
      selectedDV := '';
end;

{console commands}
procedure conCommandNotify(var con: conTConsole; nID: longint);
begin
   case nID of
      cidLISTVAR: listVar(con);
      cidSETVAR: setVar(con);
      cidGETVAR: getVar(con);
      cidDVARAT: dvarAt(con);
   end;
end;

procedure Initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'console.dvar', @Initialize);

END.
