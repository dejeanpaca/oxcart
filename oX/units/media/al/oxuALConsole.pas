{
   oxuALConsole, manages al console
   Copyright (C) 2009. Dejan Boras

   Started On:    12.09.2009.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT oxuALConsole;

INTERFACE

   USES
      StringUtils,
      {ox}
      uOX, oxuRunRoutines, oxuALDevices, oxuConsole, oxuConsoleBackend;

IMPLEMENTATION

CONST
   cidAL         = $00;

   conCommands: array[0..0] of conTCommand = (
      (sid: 'al'; sHelp: 'manages OpenAL'; nID: cidAL)
   );

   conHandler: conTHandler = (
      notify: nil;
      nCommands: 1;
      Commands: @conCommands;
      Next: nil
   );

procedure conCommandNotify(var con: conTConsole; nID: uint16);
var
   i, code, value: int32;
   arg: string;
   ns: string;

procedure writeHelpStatement();
begin
   con.i('Use <al help> for more help.');
end;

begin
   case nID of
      cidAL: begin
         if(con.arguments.n >= 2) then begin
            arg := LowerCase(con.arguments.list[1]);
            {list devices}
            if(arg = 'listdevices') then begin
               if(oxalDevices.nDevices > 0) then begin
                  con.i('OpenAL Devices >');
                  for i := 0 to (oxalDevices.nDevices - 1) do begin
                     ns := sf(i);
                     AddLeadingPadding(ns, '0', 2);
                     con.i('   (' + ns + ') ' + oxalDevices.Devices[i]^);
                  end;
               end else
                  con.i('No devices found.');
            end else if(arg = 'preferred') then begin
               con.i('Preferred OpenAL Device: ' + oxalDevices.Preferred);
            {set a device as preferred}
            end else if(arg = 'setdevice') then begin
               if(oxalDevices.nDevices > 1) then begin
                  if(con.arguments.n >= 3) then begin
                     {get the argument(device name or no)}
                     arg := con.Entry;
                     delete(arg, 1, 14{'dal setdevice '});

                     {let's see if this is a number}
                     val(arg, value, code);
                     {if we got a number, we need to get a name}
                     if(code = 0) then
                        arg := oxalDevices.Devices[value]^;

                     {set the preferred device}
                     arg := oxalDevices.Find(arg);
                     if(arg <> '') then begin
                        oxalDevices.Preferred := arg;
                        con.s('Set the OpenAL device to: ' + oxalDevices.GetDeviceName(oxalDevices.DeviceSpecifier));
                        con.s('Effective on reboot');
                     end else begin
                        con.e('Could not find the device specified.')
                     end;
                  end else
                     con.e('Error: Need to specify a device no. or name.');
               end else begin
                  con.e('There are no devices to choose from.');
               end;
            {if the command is not known}
            end else if(arg = 'help') then begin
               if(con.arguments.n = 2) then begin
                  con.i('dal [subcommand]');
                  con.i('Subcommands: listdevices, preferred, setdevice, help');
                  con.i('Some subcommands have additional parameters.');
                  con.i('Use <dal help [subcommand]> to view help for that subcommand.')
               end else if(con.arguments.n > 2) then begin
                  arg := LowerCase(con.arguments.list[2]);
                  if(arg = 'listdevices') then
                     con.i('Lists all OpenAL devices.')
                  else if(arg = 'preferred') then
                     con.i('Tells what the preferred device is.')
                  else if(arg = 'setdevice') then begin
                     con.i('Sets the preferred OpenAL device.');
                     con.i('dal setdevice [name]');
                     con.i('Where name is the name or nubmer of the device.');
                     con.i('Use the listdevices subcommand to view devices.');
                  end else if(arg = 'help') then begin
                     con.i('Gives general or subcommand help.');
                  end;
               end;
            end else
               con.e('Unknown subcommand.');
         end else begin
            con.e('Insufficient arguments.');
            writeHelpStatement();
         end;
      end;
      else
         con.e('Unknown dAL command.');
   end;
end;

procedure init();
begin
   conHandler.notify := conTCommandNotifyProc(@conCommandNotify);
   oxConsole.console.AddHandler(conHandler);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'console.keymappings', @init);

END.

