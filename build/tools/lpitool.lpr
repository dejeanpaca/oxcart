{
   lpitool, manipulates lpi files

   Started On: 18.09.2015.
}

{$MODE OBJFPC}{$H+}{$I-}
PROGRAM lpitool;

   USES
      sysutils, uBuild, appuLog, uLog, uStd, uLPI, ConsoleUtils, ParamUtils;

TYPE
   TMode = (
      {do nothing}
      MODE_NONE,
      {create an lpi file}
      MODE_CREATE,
      {update existing lpi files with include paths}
      MODE_UPDATE
   );

VAR
   mode: TMode = MODE_NONE;
   source: string;

function parameterProcess(const p: string; const lp: string): boolean;
begin
   result := true;

   if(lp = '-create') then
      mode := MODE_CREATE
   else if(lp = '-update') then
      mode := MODE_UPDATE
   else if(lp = '-verbose') then
      lpi.Verbose := true
   else
      source := p;
end;

BEGIN
   build.Initialize();
   lpi.Initialize();

   if(lpi.Initialized) then begin
      parameters.Process(@parameterProcess);

      if(mode = MODE_CREATE) then
         lpi.Create(source)
      else if(mode = MODE_UPDATE) then
         lpi.Update(source)
      else
         log.e('Error: Did not specify a (valid) mode.');
   end else
      log.e('LPI system not initialized. Cannot do anything.');
END.

