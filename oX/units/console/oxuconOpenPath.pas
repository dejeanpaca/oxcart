{
   open file manager to a path by name
   Copyright (C) 2020 Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuconOpenPath;

INTERFACE

   USES
      uStd, {$IFNDEF NOLOG}uLog,{$ENDIF}
      {app}
      appuPaths, uApp,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend;

IMPLEMENTATION

CONST
   conCommands: array[0..0] of conTCommand = (
      (sid: 'openpath'; sHelp: 'open file manager to a path by name'; nID: 0));

VAR
   conHandler: conTHandler;

procedure open(const path: StdString);
begin
   app.OpenFileManager(path);
end;

{console commands}
procedure conCommandNotify(var con: conTConsole; {%H-}nID: longint);
var
    arg: string = '';

begin
   if(con.Arguments.n > 1) then begin
      arg := LowerCase(con.Arguments.List[1]);

      if(arg = 'config') then
         open(appPath.Configuration.Path)
      {$IFNDEF NOLOG}
      else if(arg = 'logs') or (arg = 'log') then
         open(log.Settings.Path)
      {$ENDIF}
      else if(arg = 'userconfig') then
         open(appPath.Get(appPATH_CONFIG))
      else if(arg = 'userconfig_shared') then
         open(appPath.Get(appPATH_CONFIG_SHARED))
      else if(arg = 'home') then
         open(appPath.Get(appPATH_HOME))
      else if(arg = 'temp') then
         open(appPath.Get(appPATH_TEMP))
      else if(arg = 'local') then
         open(appPath.Get(appPATH_LOCAL))
      else if(arg = 'documents') then
         open(appPath.Get(appPATH_DOCUMENTS));
   end;
end;

procedure initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

INITIALIZATION
   ox.Init.Add('console.openpath', @initialize);

END.
