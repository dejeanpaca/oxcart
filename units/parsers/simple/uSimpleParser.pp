{
   uSimpleParser, simple parser utilities
   Copyright (C) 2010. Dejan Boras

   Created on:    27.07.2010.
}

{$INCLUDE oxheader.inc}
UNIT uSimpleParser;

INTERFACE

   USES
      uStd, StringUtils, uParserBase, uFileUtils;

CONST
   MAX_COMMENT_LEVEL                = 31;

   eSIMPLE_PARSER_PARSE_ROUTINE     = $0100;

TYPE
   PParseData = ^TParseData;

   {read/write functions}
   TParseMethod = function(var d): boolean;

   { TParseData }

   TParseData = object(TParserBase)
      Log: StdString;

      {current data}
      CurrentLine,
      {current key if in key/value mode}
      Key,
      {current value if in key/value mode}
      Value: StdString;

      {callbacks}
      ReadMethod,
      WriteMethod: TParseMethod;
      {are we in key/value mode (only applicable if reading)}
      KeyValue: boolean;
      {key/value separator}
      KeyValueSeparator: char;

      {parsing}
      StripWhitespace,
      ReadEmptyLines: boolean;

      {external data, passed from the caller}
      ExternalData: pointer;

      constructor Create();
      constructor CreateKeyValue();

      {perform file reading}
      function Read(const fn: StdString): Boolean;
      function Read(const fn: StdString; readFunction: TParseMethod): Boolean;
      {write a file}
      function Write(const fn: StdString): Boolean;
      function Write(const fn: StdString; writeFunction: TParseMethod): Boolean;
      {write a single line to the file}
      procedure WriteLine(const s: StdString);

      function OnRead(): boolean; virtual;
      function OnWrite(): boolean; virtual;
   end;

   { TSimpleParserGlobal }

   TSimpleParserGlobal = record
      {load file strings as a list of key value pairs}
      function LoadKeyValues(const fn: StdString; var kv: TStringPairs; const separator: char = '='): loopint;
   end;

VAR
   SimpleParser: TSimpleParserGlobal;

IMPLEMENTATION

function loadKeyValuesParse(var p: TParseData): boolean;
var
   kv: PStringPairs;
   pair: TStringPair;

begin
   kv := p.ExternalData;

   pair[0] := p.Key;
   pair[1] := p.Value;

   kv^.Add(pair);

   Result := true;
end;

{ TSimpleParserGlobal }

function TSimpleParserGlobal.LoadKeyValues(const fn: StdString; var kv: TStringPairs; const separator: char = '='): loopint;
var
   parse: TParseData;

begin
   Result := 0;

   parse.CreateKeyValue();
   parse.KeyValueSeparator := separator;
   parse.ExternalData := @kv;

   parse.Read(fn, TParseMethod(@loadKeyValuesParse));
end;

function TParseData.OnRead(): boolean;
var
   minimumLength: longint = 0;

begin
   if (ReadEmptyLines) then
      minimumLength := -1;

   if(ReadMethod = nil) then
      exit(f.Error = 0);

   repeat
      f.Readln(CurrentLine);

      if(f.Error <> 0) then
         break;

      {strip white space}
      if(StripWhitespace) then
         StringUtils.StripWhiteSpace(CurrentLine);

      if(Length(CurrentLine) > minimumLength) then begin
         if(KeyValue) then
            GetKeyValue(CurrentLine, Key, Value, KeyValueSeparator);

         if(not ReadMethod(self)) then begin
            SetError(eSIMPLE_PARSER_PARSE_ROUTINE, 'Read parser method failed');
             break;
         end;
      end;
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

constructor TParseData.Create();
begin
   inherited;

   KeyValueSeparator := '=';
   StripWhitespace := true;
end;

constructor TParseData.CreateKeyValue();
begin
   inherited;

   KeyValueSeparator := '=';
   StripWhitespace := true;
   KeyValue := true;
end;

function TParseData.Read(const fn: StdString): Boolean;
begin
   Result := inherited Read(fn);
end;

function TParseData.Read(const fn: StdString; readFunction: TParseMethod): Boolean;
begin
   ReadMethod := readFunction;

   Result := inherited Read(fn);
end;

function TParseData.Write(const fn: StdString): Boolean;
begin
   Result := inherited Write(fn);
end;

function TParseData.Write(const fn: StdString; writeFunction: TParseMethod): Boolean;
begin
   WriteMethod := writeFunction;
   Result := inherited Write(fn);
end;

procedure TParseData.WriteLine(const s: StdString);
begin
   f.Writeln(s);
end;

END.
