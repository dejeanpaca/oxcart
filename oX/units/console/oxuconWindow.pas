{
   oxuconWindow, window console extension
   Copyright (C) 2012 Dejan Boras

   Configure windows via the console
}

{$INCLUDE oxdefines.inc}
UNIT oxuconWindow;

INTERFACE

   USES
      StringUtils,
      {oX}
      uOX, oxuRunRoutines, oxuWindowTypes, oxuWindows, oxuWindow, oxuConsoleBackend;

IMPLEMENTATION

CONST
   cidWINDOW = 0;

   conCommands: array[0..0] of conTCommand = (
      (sid: 'window'; sHelp: 'Handles window operations'; nID: cidWINDOW)
   );

VAR
   selectedWindow: longint;
   conHandler: conTHandler;

function getIntParameter(const con: conTConsole; const prefix: string; out value: longint; index: longint = 2): boolean;
var
   temp_value, code: longint;

begin
   if(con.arguments.n >= index + 1) then begin
      val(con.arguments.list[index], temp_value, code);

      if(code = 0) then begin
         value := temp_value;
         exit(true);
      end else
         con.e('Value for ' + prefix + ' (' + con.arguments.list[index] + ') is not a valid integer');
   end else
      con.e('Must specify value for ' + prefix);

   result := false;
end;

procedure selectWindow(const con: conTConsole);
var
   index, code: longint;

begin
   if(con.arguments.n >= 3) then begin
      val(con.arguments.list[2], index, code);

      if(code = 0) then begin
         if((index >= 0) and (index < oxWindows.n)) then
            selectedWindow := index
         else
            con.e('Specified window index is out of allowed window index range (0..' + sf(oxWindows.n - 1) + ')');
      end else
         con.e('Not a number ' + con.arguments.list[1]);
   end else
      con.e('Window index not specified');
end;

procedure writeOutDimensions(const con: conTConsole);
begin
   con.i('Dimensions: ' + sf(oxWindows.w[selectedWindow].Dimensions.w) + 'x' + sf(oxWindows.w[selectedWindow].Dimensions.h));
end;

procedure setGetDimensions(const con: conTConsole);
var
   ok: boolean;
   w, h, code: longint;
   wString, hString, wdString: string;

begin
   if(con.arguments.n >= 3) then begin
      ok := false;
      wdString := con.arguments.list[2];

      w := 0;
      h := 0;

      if(Pos('x', wdString) > 0) then begin
         wString := Copy(wdString, 1, pos('x', wdString) - 1);
         hString := Copy(wdString, pos('x', wdString) + 1, Length(wdString));

         if(wString <> '') and (hString <> '') then begin
            val(wString, w, code);

            if(code = 0) then begin
               val(hString, h, code);

               if(code = 0) then
                  ok := true;
            end;
         end;

         if(not ok) then
            con.e('Invalid dimensions format or values (should be WxH, e.g. 1280x720): ' + con.arguments.list[2]);
      end;

      if(not ok) then begin
         if(getIntParameter(con, 'width', w, 2) and getIntParameter(con, 'height', h, 3)) then
            ok := true;
      end;

      if(ok) then begin
         if(w <= 0) then
            con.e('Width must be a positive value')
         else if(h <= 0) then
            con.e('Height must be a positive value')
         else
            oxWindows.w[selectedWindow].SetDimensions(w, h);
      end;
   end else
      writeOutDimensions(con);
end;

procedure showInfo(const con: conTConsole);
var
   wnd: oxTWindow;

begin
   wnd := oxWindows.w[selectedWindow];

   writeOutDimensions(con);
   con.i('Fullscreen: ' + sf(wnd.oxProperties.Fullscreen));
end;

{console commands}
procedure conCommandNotify(var con: conTConsole; {%H-}nID: longint);
var
   cmd: string;

begin
   if(con.arguments.n >= 2) then begin
      cmd := lowercase(con.arguments.list[1]);

      if(cmd = 'select') then
         selectWindow(con)
      else if(cmd = 'dimensions') then
         setGetDimensions(con)
      else if(cmd = 'fullscreen') then
         oxWindows.w[selectedWindow].ToggleFullscreen()
      else if(cmd = 'windowed_fullscreen') then
         oxWindows.w[selectedWindow].ToggleWindowedFullscreen()
      else if(cmd = 'info') then
         showinfo(con)
      else if(cmd = 'maximize') then
         oxWindows.w[selectedWindow].Maximize()
      else if(cmd = 'minimize') then
         oxWindows.w[selectedWindow].Minimize()
      else if(cmd = 'restore') then
         oxWindows.w[selectedWindow].Restore()
      else
         con.w('Command not recognized/supported: ' + con.arguments.list[1]);
   end else
      con.e('Window operation not specified');
end;

procedure Initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

INITIALIZATION
   ox.Init.Add('console.window', @Initialize);

END.
