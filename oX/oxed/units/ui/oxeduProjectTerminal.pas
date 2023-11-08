{
   oxeduProjectTerminal
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectTerminal;

INTERFACE

   USES
      sysutils, uProcessHelpers,
      uStd, uLog, StringUtils,
      {app}
      appuActionEvents,
      {oxed}
      oxeduActions;

IMPLEMENTATION

procedure openTerminal();
var
   path: StdString;
   commands: TStringArray;

begin
   path := '';
   commands := nil;

   {$IFDEF WINDOWS}
   path := 'C:\Program Files\Git\git-bash.exe';
   if(not FileExists(path)) then begin
      path := 'C:\Program Files (x86)\Git\git-bash.exe';

      if(not FileExists(path)) then
         path := '';
   end;

   {found git bash}
   if(path = '') then
      path := 'cmd.exe';
   {$ENDIF}

   if(path <> '') then begin
      log.v('Opening terminal from: ' + path);
      ProcessHelpers.AsyncCommand(path, commands);
   end;
end;

INITIALIZATION
   oxedActions.OPEN_PROJECT_TERMINAL := appActionEvents.SetCallback(@openTerminal);

END.
