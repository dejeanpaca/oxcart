{
   uSimpleParser, simple parser utilities
   Copyright (C) 2010. Dejan Boras

   Created on:    27.07.2010.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uSimpleParser;

INTERFACE

   USES uStd, StringUtils, uParserBase;

CONST
   MAX_COMMENT_LEVEL                = 31;

   eSIMPLE_PARSER_PARSE_ROUTINE     = $0100;

TYPE
   PParseData = ^TParseData;

   {read/write functions}
   TParseExtMethod = function(var d): boolean;

   { TParseData }

   TParseData = object(TParserBase)
      Log: string;

      {current data}
      CurrentLine,
      {current key if in key/value mode}
      Key,
      {current value if in key/value mode}
      Value: string;

      {callbacks}
      ReadMethod,
      WriteMethod: TParseExtMethod;
      {are we in key/value mode (only applicable if reading)}
      KeyValue: boolean;
      {key/value separator}
      KeyValueSeparator: char;

      {parsing}
      StripWhitespace,
      ReadEmptyLines: boolean;

      {external data, passed from the caller}
      ExternalData: pointer;

      {perform file reading}
      function Read(const fn: string): Boolean;
      function Read(const fn: string; readFunction: TParseExtMethod): Boolean;
      {write a file}
      function Write(const fn: string): Boolean;
      function Write(const fn: string; writeFunction: TParseExtMethod): Boolean;
      {write a single line to the file}
      procedure WriteLine(const s: string);

      function OnRead(): boolean; virtual;
      function OnWrite(): boolean; virtual;

      {initialize a TParseData record}
      class procedure Init(out p: TParseData); static;
      {initialize a TParseData record}
      class procedure InitKeyValue(out p: TParseData); static;
   end;

IMPLEMENTATION

class procedure TParseData.Init(out p: TParseData);
begin
   p.Create();
   p.KeyValueSeparator := '=';
   p.StripWhitespace := true;
end;

class procedure TParseData.InitKeyValue(out p: TParseData);
begin
   Init(p);
   p.KeyValue := true;
end;


function TParseData.OnRead(): boolean;
var
   minimumLength: longint = 0;

begin
   if (readEmptyLines) then
      minimumLength := -1;

   repeat
      f.Readln(CurrentLine);
      if(f.Error <> 0) then break;

      {strip white space}
      if(StripWhitespace) then
         StringUtils.StripWhiteSpace(CurrentLine);

      if(KeyValue) then
         GetKeyValue(CurrentLine, Key, Value, KeyValueSeparator);

      if(ReadMethod <> nil) then begin
         if(Length(CurrentLine) > minimumLength) then begin
            if(not ReadMethod(self)) then begin
               SetError(eSIMPLE_PARSER_PARSE_ROUTINE, 'Read parser method failed');
               break;
            end;
         end;
      end else
         {stop if ReadMethod is unset}
         break;
   until f.EOF();

   Result := f.Error = 0;
end;

function TParseData.OnWrite(): boolean;
begin
   {call the writing routine}
   if(WriteMethod <> nil) then begin
      if(WriteMethod(self) = false) then begin
         SetError(eSIMPLE_PARSER_PARSE_ROUTINE, 'Write parser routine failed');
         exit(false);
      end;
   end;

   Result := true;
end;

function TParseData.Read(const fn: string): Boolean;
begin
   Result := inherited Read(fn);
end;

function TParseData.Read(const fn: string; readFunction: TParseExtMethod): Boolean;
begin
   ReadMethod := readFunction;

   Result := inherited Read(fn);
end;

function TParseData.Write(const fn: string): Boolean;
begin
   Result := inherited Write(fn);
end;

function TParseData.Write(const fn: string; writeFunction: TParseExtMethod): Boolean;
begin
   WriteMethod := writeFunction;
   Result := inherited Write(fn);
end;

procedure TParseData.WriteLine(const s: string);
begin
   f.Writeln(s);
end;

END.
