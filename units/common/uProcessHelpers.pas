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

      procedure RunCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions = []);
      procedure AsyncCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions = []);
      procedure RunCommandCurrentDir(const path: StdString; const commands: TStringArray; options: TProcessOptions = []);
   end;

VAR
   ProcessHelpers: TProcessHelpers;

IMPLEMENTATION

{ TProcessHelpers }

procedure TProcessHelpers.RunCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions);
var
   i: loopint;
   p: TProcess;

begin
   OutputString := '';

   p := TProcess.Create(nil);
   p.Executable := path;
   p.Options := options;

   if(commands <> nil) then begin
      for i := 0 to high(commands) do
         p.Parameters.Add(commands[i]);
   end;

   try
      p.Execute();

      OutputString := p.GetOutputString();
   except
      on e: Exception do begin
         log.e('Failed to execute: ' + path);
      end;
   end;


   if(OutputString <> '') then
      console.i(OutputString);

   FreeObject(p);
end;

procedure TProcessHelpers.AsyncCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions);
begin
   Exclude(options, poWaitOnExit);
   RunCommand(path, commands, options);
end;

procedure TProcessHelpers.RunCommandCurrentDir(const path: StdString; const commands: TStringArray; options: TProcessOptions);
begin
   RunCommand(IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir()) + path, commands, options);
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

   if(stream <> nil) and (stream.NumBytesAvailable > 0) then begin
      length := stream.NumBytesAvailable;
      SetLength(Result, stream.NumBytesAvailable);

      stream.ReadBuffer(Result[1], length);

      if(stripEndLine) then
         StringUtils.stripEndLine(Result);

      exit;
   end;
end;

END.
