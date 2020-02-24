{
   lpitool, manipulates lpi files
   Copyright (c) 2015. Dejan Boras

   Required packages
   @lazpackage LazUtils
}

{$MODE OBJFPC}{$H+}{$I-}
PROGRAM lpitool;

   USES
      sysutils, uBuild, appuLog, uLog, uStd, uLPI, ConsoleUtils, ParamUtils;

VAR
   mode: TLPIMode = lpiMODE_NONE;
   source: StdString;

function parameterProcess(const p: StdString; const lp: StdString): boolean;
begin
   result := true;

   if(lp = '-create') then
      mode := lpiMODE_CREATE
   else if(lp = '-update') then
      mode := lpiMODE_UPDATE
   else if(lp = '-test') then
      mode := lpiMODE_TEST
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

      if(mode = lpiMODE_CREATE) then
         lpi.Create(source)
      else if(mode = lpiMODE_UPDATE) then
         lpi.Update(source)
      else if(mode = lpiMODE_TEST) then
         lpi.Test(source)
      else
         log.e('Error: Did not specify a (valid) mode.');
   end else
      log.e('LPI system not initialized. Cannot do anything.');
END.

