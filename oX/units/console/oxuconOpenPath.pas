{
   open file manager to a path by name
   Copyright (C) 2020 Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuconOpenPath;

INTERFACE

   USES
      uStd, uLog,
      {app}
      appuPaths, uApp,
      {oX}
      uOX, oxuRunRoutines, oxuConsoleBackend;

IMPLEMENTATION

CONST
   cidOPENPATH = $0000;

   conCommands: array[0..0] of conTCommand = (
      (sid: 'openpath'; sHelp: 'open file manager to a path by name'; nID: cidOPENPATH));

(*   appPATH_CONFIG, {configuration path}
   appPATH_CONFIG_SHARED, {shared configuration for all users}
   appPATH_HOME, {user profile home}
   appPATH_TEMP, {temporary files directory}
   {NOTE: local is applicable to windows mostly due to the distinction of roaming and local profile}
   appPATH_LOCAL, {local configuration path (should house non-critical things, which aren't quite temporary (logs, caches))}
   appPATH_DOCUMENTS {documents directory}               *)

VAR
   conHandler: conTHandler;

procedure open(const path: StdString);
begin
   app.OpenFileManager(path);
end;

procedure openPath(var con: conTConsole);
var
    arg: string = '';

begin
   if(con.Arguments.n > 1) then begin
      arg := LowerCase(con.Arguments.List[1]);

      if(arg = 'config') then
         Open(appPath.Get(appPATH_CONFIG))
      else if(arg = 'config_shared') then
         Open(appPath.Get(appPATH_CONFIG_SHARED))
      else if(arg = 'home') then
         Open(appPath.Get(appPATH_HOME))
      else if(arg = 'temp') then
         Open(appPath.Get(appPATH_TEMP))
      else if(arg = 'local') then
         Open(appPath.Get(appPATH_LOCAL))
      else if(arg = 'documents') then
         Open(appPath.Get(appPATH_DOCUMENTS));
   end;
end;

{console commands}
procedure conCommandNotify(var con: conTConsole; nID: longint);
begin
   case nID of
      cidOPENPATH: openPath(con);
   end;
end;

procedure initialize();
begin
   console.Selected^.AddHandler(conHandler, conTCommandNotifyProc(@conCommandNotify), conCommands);
end;

INITIALIZATION
   ox.Init.Add('console.openpath', @initialize);

END.
