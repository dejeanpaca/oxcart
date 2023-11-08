{
   uTest
   Copyright (C) 2019. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uProcessHelpers;

INTERFACE

   USES
      process, pipes, SysUtils, StreamIO,
      uStd, uLog, ConsoleUtils, StringUtils;

TYPE
   { TProcessUtils }

   TProcessUtils = record
      {get a input pipe stream as a string}
      class function GetString(stream: TInputPipeStream; stripEndLine: boolean = true): StdString; static;
   end;

   { TProcessHelper }

   TProcessHelper = class helper for TProcess
      function GetOutputString(stripEndLine: boolean = true): StdString;
      function GetOutputStrings(stripEndLine: boolean = true; maxLines: loopint = -1): TSimpleStringList;
      function GetOutputStrings(maxLines: loopint): TSimpleStringList;
   end;

   { TProcessHelpers }

   TProcessHelpers = record
      OutputString: AnsiString;

      procedure RunCommand(const exename: StdString; const commands: TStringArray);
      procedure RunCommandCurrentDir(const exename: StdString; const commands: TStringArray);
   end;

VAR
   ProcessHelpers: TProcessHelpers;

IMPLEMENTATION

{ TProcessHelpers }

procedure TProcessHelpers.RunCommand(const exename: StdString; const commands: TStringArray);
var
   ansiCommands: array of String;

begin
   OutputString := '';
   ansiCommands := commands.GetAnsiStrings();

   if(not process.RunCommand(exename, ansiCommands, outputString)) then
      log.e('Failed to run process: ' + exename);

   if(outputString <> '') then
      console.i(outputString);
end;

procedure TProcessHelpers.RunCommandCurrentDir(const exename: StdString; const commands: TStringArray);
begin
   RunCommand(IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir()) + exename, commands);
end;

{ TProcessHelper }

function TProcessHelper.GetOutputString(stripEndLine: boolean): StdString;
begin
   Result := TProcessUtils.GetString(Output, stripEndLine);
end;

function TProcessHelper.GetOutputStrings(stripEndLine: boolean; maxLines: loopint): TSimpleStringList;
var
   s: StdString;
   f: TextFile;

begin
   TSimpleStringList.Initialize(Result);

   {we do nothing}
   if(maxLines = 0) then
      exit;

   ZeroOut(f, SizeOf(f));

   AssignStream(f, Output);
   Reset(f);

   while(not eof(f)) do begin
      ReadLn(f, s);

      if(stripEndLine) then
         StringUtils.stripEndLine(s);

      Result.Add(s);

      {check if we have the desired number of lines}
      if(maxLines > 0) and (Result.n >= maxLines) then
         break;
   end;

   Close(f);
end;

function TProcessHelper.GetOutputStrings(maxLines: loopint): TSimpleStringList;
begin
   Result := GetOutputStrings(true, maxLines);
end;

class function TProcessUtils.GetString(stream: TInputPipeStream; stripEndLine: boolean): StdString;
var
   length: loopint;

begin
   Result := '';

   if(stream.NumBytesAvailable > 0) then begin
      length := stream.NumBytesAvailable;
      SetLength(Result, stream.NumBytesAvailable);

      stream.ReadBuffer(Result[1], length);

      if(stripEndLine) then
         StringUtils.stripEndLine(Result);

      exit;
   end;
end;

END.
