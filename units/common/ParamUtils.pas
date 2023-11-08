{
   ParamUtils, utilities for managing parameters
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ParamUtils;

INTERFACE

   USES
      uStd, ConsoleUtils, StringUtils;

CONST
   {maximum arguments a parameter can have}
   MAX_PARAMETER_ARGUMENTS                   = 16;
   MAX_PARAMETER_ARGUMENTS_STR               = '16'; // a string representation of MAX_PARAMETER_ARGUMENTS

   { ERROR CODES }
   ePARAMETER_OK                             = 0000;
   ePARAMETER_UNSPECIFIED                    = 0001;
   ePARAMETER_INVALID                        = 0002;

   { HANDLER ERROR CODES }
   eHANDLER_ARGUMENTS_INVALID                = 0001;

   { HANDLER PROPERTIES }
   {parameters must have exact argument count}
   PARAM_HANDLER_CRITICAL_ARGUMENT_COUNT     = 0001;
   {required parameter must not be omitted}
   PARAM_HANDLER_REQUIRED                    = 0002;
   {this is set by ProcessParameters() to 1 if the parameter handler was called for this parameter}
   PARAM_HANDLER_CALLED                      = 0004;

TYPE
   TProcessParametersRoutine = function(const pstr: StdString; const lstr: StdString): boolean;

   {a parameter handler}
   TParameterHandlerRoutine = function(const paramKey: StdString; var params: array of StdString; n: longint): boolean;

   PParameterHandler = ^TParameterHandler;
   TParameterHandler = record
      Name: StdString;
      ParamKey: StdString;
      Properties: longword;
      nArguments: longint;
      Process: TParameterHandlerRoutine;
      Next: PParameterHandler;
   end;

   {parameter handlers}
   TParameterHandlers = record
      n: longint;
      s,
      e: PParameterHandler;
   end;

   { TParameterGlobal }

   TParameterGlobal = record
      CurParameter,
      ParameterCount: loopint;

      Handlers: TParameterHandlers;
      HandledParameters: array of boolean;

      UseCustomParameters: boolean;
      CustomParameters: TStringArray;

      {get the next parameter}
      function Next(): StdString;
      {get the next parameter as lowercase}
      function NextLowercase(): StdString;
      {get the next parameter as integer, and return true if successful}
      function Next(var i: longint): longint;
      function Next(var i: int64): longint;
      {get the current parameter}
      function Current(): StdString;
      {get the current parameter as integer, and return true if successful}
      function Current(var i: longint): longint;
      function Current(var i: int64): longint;
      {get the current parameter index}
      function GetIndex(): longint;
      {did we get to the last parameter}
      function IsEnd(): boolean;

      {reset parameter procedure}
      procedure Reset();

      {mark a parameter as hanled so we don't produce a warning over it}
      procedure MarkParameterHandled(parameter: loopint);

      { FINDING }
      {find a flag}
      function FindFlag(const flagName: StdString): boolean;
      function FindFlagLowercase(const flagName: StdString): boolean;

      {get custom parameter if they're used, if not use regular parameters}
      function GetCustom(parameter: loopint): StdString;
      {get a parameter and mark it as handled}
      function GetParameter(parameter: loopint): StdString;

      { HANDLERS }
      {finds a parameter handler for the specified paramKey, returns nil if none found}
      function FindHandler(const paramKey: StdString): PParameterHandler;
      {marks all handlers as not called}
      procedure SetHandlersUncalled();
      {checks if a parameter handler has the PARAM_HANDLER_CALLED property set}
      function IsHandlerCalled(var handler: TParameterHandler): boolean; inline;
      {adds a parameter handler to the parameterHandlers list}
      procedure AddHandler(var handler: TParameterHandler);
      {adds a parameter handler to the parameterHandlers list}
      procedure AddHandler(out handler: TParameterHandler; const name, key: StdString;
         process: TParameterHandlerRoutine = nil; nArguments: loopint = 1);

      { PROCESSING }
      {uses a callback routine to handle parameters}
      procedure Process(callback: TProcessParametersRoutine);
      {processes parameters via registered handlers}
      function Process(): boolean;

      {build all parameters as string}
      function ToString(): StdString;
      {use custom parameters string to replace the one provided by the system}
      procedure SetParameters(var params: TStringArray);

      {get all parameters as an array (except the 0th parameter)}
      function GetArray(): TStringArray;
   end;

VAR
   parameters: TParameterGlobal;

IMPLEMENTATION

function TParameterGlobal.Next(): StdString;
begin
	inc(CurParameter);

   Result := GetCustom(CurParameter);
end;

function TParameterGlobal.NextLowercase(): StdString;
begin
   inc(CurParameter);

   Result := lowercase(GetCustom(CurParameter));
end;

function TParameterGlobal.Next(var i: longint): longint;
var
	code: longint;
	s: StdString;

begin
	s := Next();

   if(s <> '') then begin
		val(s, i, code);

      if(code = 0) then
         Result := 0
      else
         Result := ePARAMETER_INVALID;
	end else
      Result := ePARAMETER_UNSPECIFIED;
end;

function TParameterGlobal.Next(var i: int64): longint;
var
	code: longint;
	s: StdString;

begin
	s := Next();

   if(s <> '') then begin
		val(s, i, code);

      if(code = 0) then
         Result := 0
      else
         Result := ePARAMETER_INVALID;
	end else
      Result := ePARAMETER_UNSPECIFIED;
end;

function TParameterGlobal.Current(): StdString;
begin
   Result := GetCustom(CurParameter);
end;

function TParameterGlobal.Current(var i: longint): longint;
var
	code: longint;
	s: StdString;

begin
	s := Current();

   if(s <> '') then begin
		val(s, i, code);

      if(code = 0) then
         Result := 0
      else
         Result := ePARAMETER_INVALID;
	end else
      Result := ePARAMETER_UNSPECIFIED;
end;

function TParameterGlobal.Current(var i: int64): longint;
var
	code: longint;
	s: StdString;

begin
	s := Current();

   if(s <> '') then begin
		val(s, i, code);

      if(code = 0) then
         Result := 0
      else
         Result := ePARAMETER_INVALID;
	end else
      Result := ePARAMETER_UNSPECIFIED;
end;

function TParameterGlobal.GetIndex(): longint;
begin
	Result := CurParameter;
end;

function TParameterGlobal.IsEnd(): boolean;
begin
   Result := CurParameter >= ParameterCount;
end;

procedure TParameterGlobal.Reset();
begin
   CurParameter := 0;
end;

procedure TParameterGlobal.MarkParameterHandled(parameter: loopint);
begin
   if(parameter > 0) and (parameter <= ParameterCount) then
      HandledParameters[parameter - 1] := true;
end;

function TParameterGlobal.FindFlag(const flagName: StdString): boolean;
var
   i: longint;

begin
   for i := 1 to ParameterCount do begin
      if(GetCustom(i) = flagName) then begin
         MarkParameterHandled(i);
         exit(true);
      end;
   end;

   Result := false;
end;

function TParameterGlobal.FindFlagLowercase(const flagName: StdString): boolean;
var
   i: longint;
   flagNameLC: StdString;

begin
   flagNameLC := lowercase(flagName);

   for i := 1 to ParameterCount do begin
      if(LowerCase(GetCustom(i)) = flagNameLC) then begin
         MarkParameterHandled(i);
         exit(true);
      end;
   end;

   Result := false;
end;

function TParameterGlobal.GetCustom(parameter: loopint): StdString;
begin
   if(not UseCustomParameters) or (parameter = 0) then
      Result := ParamStr(parameter)
   else
      Result := CustomParameters[parameter - 1];
end;

function TParameterGlobal.GetParameter(parameter: loopint): StdString;
begin
   if(parameter >= 0) and (parameter <= ParameterCount) then begin
      Result := GetCustom(parameter);
      MarkParameterHandled(parameter);
   end else
      Result := '';
end;

{ HANDLERS }

function TParameterGlobal.FindHandler(const paramKey: StdString): PParameterHandler;
var
   cur: PParameterHandler;

begin
   Result := nil;
   cur := Handlers.s;

   if(cur <> nil) then repeat
      if(cur^.ParamKey = paramKey) then
         exit(cur);

      cur := cur^.Next;
   until (cur = nil);
end;

procedure TParameterGlobal.SetHandlersUncalled();
var
   curHandler: PParameterHandler;

begin
   curHandler := Handlers.s;

   if(curHandler <> nil) then begin
      repeat
         curHandler^.Properties := curHandler^.Properties and PARAM_HANDLER_CALLED xor curHandler^.Properties;
         curHandler := curHandler^.Next;
      until (curHandler = nil);
   end;
end;

function TParameterGlobal.IsHandlerCalled(var handler: TParameterHandler): boolean; inline;
begin
   Result := handler.Properties and PARAM_HANDLER_CALLED > 0;
end;

procedure TParameterGlobal.AddHandler(var handler: TParameterHandler);
begin
   handler.Next := nil;

   if(handlers.s = nil) then
      handlers.s := @handler
   else
      handlers.e^.Next := @handler;

   handlers.e := @handler;
end;

procedure TParameterGlobal.AddHandler(out handler: TParameterHandler; const name, key: StdString;
   process: TParameterHandlerRoutine; nArguments: loopint);
begin
   ZeroOut(handler, SizeOf(handler));

   handler.Name := name;
   handler.ParamKey := key;
   handler.Process := process;
   handler.nArguments := nArguments;

   AddHandler(handler);
end;

{ PROCESSING }

procedure TParameterGlobal.Process(callback: TProcessParametersRoutine);
var
   s: StdString;

begin
   Reset();

   if(callback <> nil) then begin
      repeat
         s := Next();

         if(s <> '') then
            if(callback(s, LowerCase(s)) = false) then
               break;
      until (IsEnd());
   end;
end;

function TParameterGlobal.Process(): boolean;
var
   cur: StdString;
   curHandler: PParameterHandler;

   nArguments,
   gotnArguments,
   i: loopint;
   ok: boolean;
   arguments: array[0..MAX_PARAMETER_ARGUMENTS-1] of StdString;

   omittedRequiredParameters: boolean;

procedure unknownOrUnsupportedParam();
begin
   console.w('Parameter ' + cur + ' is unknown or unsupported.');
end;

begin
   Reset();
   Result := false;

   {mark all parameter handlers as uncalled}
   setHandlersUncalled();

   {go through parameters}
   repeat
      cur := Next();

      if(cur <> '') then begin
         {find the parameter in the list of parameter handlers}
         curHandler := FindHandler(cur);

         if(curHandler <> nil) then begin
            MarkParameterHandled(CurParameter);

            {get arguments for this parameter}
            nArguments := curHandler^.nArguments;

            if(nArguments <= MAX_PARAMETER_ARGUMENTS) then begin
               {initialize arguments list}
               gotnArguments := 0;

               for i := 0 to (MAX_PARAMETER_ARGUMENTS - 1) do
                  arguments[i] := '';

               {build argument list, if any arguments are required}
               if(nArguments > 0) then
                  for i := 0 to (nArguments-1) do begin
                     arguments[i] := Next();

                     {check if we got an argument, and if not it means the argument count is not correct}
                     if(arguments[i] = '') then begin
                        if(curHandler^.Properties and PARAM_HANDLER_CRITICAL_ARGUMENT_COUNT > 0) then begin
                           console.w('Parameter ' + cur + ' has insufficient arguments(' + sf(gotnArguments) +
                              '), but requires ' + sf(nArguments) + '.');
                           exit;
                        end;
                     end else
                        inc(gotnArguments);
                  end;

               {call the handler}
               if(curHandler^.Process <> nil) then begin
                  ok := curHandler^.Process(cur, arguments, gotnArguments);

                  if(ok) then
                     curHandler^.Properties := curHandler^.Properties or PARAM_HANDLER_CALLED
                  else begin
                     console.w('Aborted handling parameters due to errors.');
                     exit(false);
                  end;
               end else
                  console.w('Warning: Parameter ' + cur + ' has a handler with no processing routine.');
            end else begin
               console.w('Parameter ' + cur + ' has more arguments(' + sf(nArguments) +
                  ') than supported(' + MAX_PARAMETER_ARGUMENTS_STR + ').');
               exit();
            end;
         end else begin
            if(CurParameter > 0) and (HandledParameters[CurParameter - 1] = false) then begin
               unknownOrUnsupportedParam();
               exit(false);
            end;
            {NOTE: Should add support for generic handlers which get called if there is no specific handler associated with a key}
         end;
      end;
   until (IsEnd());

   {check if any required parameters were omitted}
   curHandler := handlers.s;
   omittedRequiredParameters := false;

   if(curHandler <> nil) then repeat
      if(curHandler^.Properties and PARAM_HANDLER_REQUIRED > 0) and (curHandler^.Properties and PARAM_HANDLER_CALLED = 0) then begin
         console.w('Omitted required parameter: ' + curHandler^.ParamKey);
         omittedRequiredParameters := true;
      end;

      curHandler := curHandler^.Next;
   until (curHandler = nil);

   { if any parameters }
   if(omittedRequiredParameters) then begin
      console.w('Error: One or more required parameters were omitted.');
      exit();
   end;

   Result := true;
end;

function TParameterGlobal.ToString(): StdString;
var
   i: loopint;

begin
   Result := '';

   for i := 1 to ParameterCount do begin
      if(i < ParameterCount) then
         Result := Result + GetCustom(i) + ' '
      else
         Result := Result + GetCustom(i);
   end;
end;

procedure TParameterGlobal.SetParameters(var params: TStringArray);
begin
   UseCustomParameters := true;
   CustomParameters := params;
   ParameterCount := Length(params);
end;

function TParameterGlobal.GetArray(): TStringArray;
var
   i: loopint;

begin
   Result := nil;
   SetLength(Result, ParameterCount);

   for i := 1 to ParameterCount do begin
      Result[i - 1] := ParamStr(i);
   end;
end;

INITIALIZATION
   parameters.CurParameter := 0;
   parameters.ParameterCount := ParamCount();
   SetLength(parameters.HandledParameters, parameters.ParameterCount);

END.
