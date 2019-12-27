{
   uDVars, manages dvar
   Copyright (c) 2011. Dejan Boras

   Started On:    01.11.2011.
}

UNIT dvaruConParamHandler;

INTERFACE

   USES ParamUtils, uDVars;

CONST
   dvarConParamHandler: TParameterHandler = (
      name: 'dvar'; 
      paramkey: '-dvar'; 
      properties: PARAM_HANDLER_CRITICAL_ARGUMENT_COUNT; 
      nArguments: 2;
      process: nil; 
      next: nil
   );

IMPLEMENTATION

function processParam(const paramkey: string; var arguments: array of string; n: longint): longint;
var
   dvar: PDVar;
   ok: boolean;

begin
   dvar := getDVar(arguments[0]);
   if(dvar <> nil) then begin
      ok := dvarSetFromString(dvar^, arguments[1]);
      if(not ok) then begin
         writeln('Error: Cannot set '+arguments[1] + ' to ' + arguments[0]);
      end;
   end else
      writeln('Error: No dvar with name ' + arguments[0] + ' was found.');

   result := 0;
end;

INITIALIZATION
   dvarConParamHandler.process := @processParam;
   addParamHandler(dvarConParamHandler);
END.

