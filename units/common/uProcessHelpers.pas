{
   uTest
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uProcessHelpers;

INTERFACE

   USES
      process, pipes, classes, SysUtils, StreamIO,
      uStd, uLog, ConsoleUtils, StringUtils;

TYPE
   {holds a (redirected) process stream}

   { TProcessStream }

   TProcessStream = record
      {is the stream opened}
      Opened: boolean;
      Stream: Text;

      class procedure Initialize(out s: TProcessStream); static;
      procedure Open(process: TStream);
      procedure Close();
   end;

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

      procedure OpenOutputStream(out s: Text);
      procedure OpenOutputStream(out s: TProcessStream);
   end;

   { TProcessHelpers }

   TProcessHelpers = record
      OutputString: AnsiString;
      ExitCode: loopint;
      LogFailure,
      LogOutput: boolean;

      function RunCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions = [poWaitOnExit]): boolean;
      function AsyncCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions = []): boolean;
      function RunCommandCurrentDir(const path: StdString; const commands: TStringArray; options: TProcessOptions = [poWaitOnExit]): boolean;

      procedure DisableLog();

      class procedure Initialize(out p: TProcessHelpers); static;
      class procedure OpenStream(stream: TStream; out s: Text); static;
   end;

VAR
   ProcessHelpers: TProcessHelpers;

IMPLEMENTATION

{ TProcessStream }

class procedure TProcessStream.Initialize(out s: TProcessStream);
begin
   ZeroOut(s, SizeOf(s));
end;

procedure TProcessStream.Open(process: TStream);
begin
   TProcessHelpers.OpenStream(process, Stream);
   Opened := true;
end;

procedure TProcessStream.Close();
begin
   if(Opened) then begin
      Opened := false;
      system.Close(Stream);
   end;
end;

{ TProcessHelpers }

function TProcessHelpers.RunCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions): boolean;
var
   i: loopint;
   p: TProcess;

begin
   Result := false;
   OutputString := '';
   ExitCode := 0;

   p := TProcess.Create(nil);
   p.ShowWindow := swoHIDE;
   p.Executable := path;
   p.Options := p.Options + options;

   if(commands <> nil) then begin
      for i := 0 to high(commands) do
         p.Parameters.Add(commands[i]);
   end;

   try
      p.Execute();

      OutputString := p.GetOutputString();
      ExitCode := p.ExitCode;

      Result := true;
   except
      on e: Exception do begin
         if(LogFailure) then
            log.e('Failed to execute: ' + path);
      end;
   end;

   if LogOutput and (OutputString <> '')then
      console.i(OutputString);

   FreeObject(p);
end;

function TProcessHelpers.AsyncCommand(const path: StdString; const commands: TStringArray; options: TProcessOptions): boolean;
begin
   Exclude(options, poWaitOnExit);
   Result := RunCommand(path, commands, options);
end;

function TProcessHelpers.RunCommandCurrentDir(const path: StdString; const commands: TStringArray; options: TProcessOptions): boolean;
begin
   Result := RunCommand(IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir()) + path, commands, options);
end;

procedure TProcessHelpers.DisableLog();
begin
   LogOutput := false;
   LogFailure := false;
end;

class procedure TProcessHelpers.Initialize(out p: TProcessHelpers);
begin
   ZeroOut(p, SizeOf(p));
   p.LogFailure := true;
   p.LogOutput := true;
end;

class procedure TProcessHelpers.OpenStream(stream: TStream; out s: Text);
begin
   ZeroOut(s, SizeOf(s));

   AssignStream(s, stream);
   Reset(s);
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
         StringUtils.StripEndLine(s);

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

procedure TProcessHelper.OpenOutputStream(out s: Text);
begin
   TProcessHelpers.OpenStream(Self.Output, s);
end;

procedure TProcessHelper.OpenOutputStream(out s: TProcessStream);
begin
   TProcessStream.Initialize(s);
   s.Open(Output);
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

INITIALIZATION
   TProcessHelpers.Initialize(ProcessHelpers);

END.
