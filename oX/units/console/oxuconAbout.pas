{
   oxuConsole, command console front-end
   Copyright (c) 2011. Dejan Boras

   Started On:    30.07.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuconAbout;

INTERFACE

   USES
      uStd, uLog, uColors,
      {app}
      uAppInfo,
      {ox}
      uOX, oxuRunRoutines,
      oxuConsoleBackend, oxuConsole;

IMPLEMENTATION

VAR
   firstAboutWrite: boolean = true;

procedure command(con: conPConsole);
var
   color: TColor4ub;
   previousLog: PLog;
   s: StdString;

begin
   previousLog := con^.LogOutput;

   if(firstAboutWrite) then begin
      con^.LogOutput := nil;
      firstAboutWrite := false;
   end;

   color := con^.Colors.Current;

   con^.Color4ub(192, 192, 255, 255);

   con^.i();

   s := appInfo.GetVersionString();
   con^.i(s);

   con^.i(oxEngineName + ' Engine v' + oxsVersion);
   con^.i();
   con^.i('Copyright (c) 2007. Dejan Boras');
   con^.i();

   con^.Colors.Current := color;
   con^.LogOutput := previousLog;
end;

procedure Initialize();
begin
   oxConsole.console.AddCommand('about', @command);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.iAdd(initRoutines, 'console.about', @Initialize);

END.
