{
   Tests ParamUtils and ConsoleUtils units.

   Copyright (C) 2011. Dejan Boras
}

PROGRAM test;

   USES ParamUtils;

function FullscreenParam(const paramkey: string; var arguments: array of string; n: longint): longint;
begin
   result := 0;
end;

VAR
   paramFullscreenHandler: TParameterHandler = (
      name: 'fullscreen'; 
      paramkey: '-fullscreen';
      properties: PARAM_HANDLER_CRITICAL_ARGUMENT_COUNT or PARAM_HANDLER_REQUIRED;
      nArguments: 1; 
      process: @FullscreenParam; 
      next: nil
   );

BEGIN
   addParamHandler(paramFullscreenHandler);

   ProcessParameters();
END.

