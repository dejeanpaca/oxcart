{
   uParserBase, basic parser helper
   Copyright (C) 2018. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uParserBase;

INTERFACE

   USES
      uStd, uError, uLog,
      uFile, uFiles;

TYPE
   PParserBase = ^TParserBase;
   { TParserBase }

   TParserBase = object
      ErrorCode: loopint;
      ErrorDescription: StdString;
      f: TFile;

      constructor Create();

      procedure SetError(code: loopint; const description: StdString = '');

      function Read(var setF: TFile): boolean;
      function Read(const fn: StdString): boolean;
      function Read(): boolean;

      function Write(var setF: TFile): boolean;
      function Write(): boolean;
      function Write(const fn: StdString): boolean;

      function OnWrite(): boolean; virtual;
      function OnRead(): boolean; virtual;

      function GetErrorString(const prefix: StdString = ''): StdString;
      procedure LogError(const start: StdString);
   end;

IMPLEMENTATION

{ TParserBase }

constructor TParserBase.Create();
begin
   ErrorCode := 0;
   ErrorDescription := '';
   ZeroOut(f, SizeOf(f));
end;

procedure TParserBase.SetError(code: loopint; const description: StdString);
begin
   if(ErrorCode = 0) then begin
      ErrorCode := code;
      ErrorDescription := description;
   end;
end;

function TParserBase.Read(var setF: TFile): boolean;
begin
   if(@f <> @setF) then
      f := setF;

   Result := Read();

   if(@f <> @setF) then
      setF := f;
end;

function TParserBase.Read(const fn: StdString): boolean;
begin
   fFile.Init(f);

   f.Open(fn);
   if(f.Error = 0) then
      Result := Read(f)
   else
      Result := false;

   f.CloseAndDestroy();
end;

function TParserBase.Read(): boolean;
begin
   Result := OnRead();

   logError('Failed reading file: ');
end;

function TParserBase.Write(var setF: TFile): boolean;
begin
   if(@f <> @setF) then
      f := setF;

   Result := Write();

   if(@f <> @setF) then
      setF := f;
end;

function TParserBase.Write(): boolean;
begin
   Result := OnWrite();

   logError('Failed writing file: ');
end;

function TParserBase.Write(const fn: StdString): boolean;
begin
   fFile.Init(f);

   f.New(fn);
   if(f.Error = 0) then begin
      Result := Write(f);
   end else
      Result := false;

   f.CloseAndDestroy();
end;

function TParserBase.OnWrite(): boolean;
begin
   Result := true;
end;

function TParserBase.OnRead(): boolean;
begin
   Result := true;
end;

function TParserBase.GetErrorString(const prefix: StdString): StdString;
var
   additional: StdString;

begin
   Result := '';

   if(f.Error <> 0) or (ErrorCode <> 0) then begin
      additional := '';

      if(ErrorCode <> 0) then begin
         if(ErrorDescription <> '') then
            additional := ' (' + GetErrorCodeString(ErrorCode) + ') ' + ErrorDescription
         else
            additional := ' ' + GetErrorCodeString(ErrorCode);
      end;

      if(f.Error <> 0) then
         additional := additional + ' {io: ' + f.GetErrorString() + '}';

      Result := prefix + f.fn + additional;
   end;
end;

procedure TParserBase.LogError(const start: StdString);
begin
   if(f.Error <> 0) or (ErrorCode <> 0) then begin
      log.e(GetErrorString(start));
   end;
end;

END.
