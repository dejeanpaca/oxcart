{
   oxufScopesSerialization, scopes file serialization
   Copyright (C) 2018. Dejan Boras

   Started On:    04.03.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxufScopesSerialization;

INTERFACE

   USES
      uStd, sysutils, typinfo, uFile, uLog,
      {ox}
      oxuSerialization, uScopesParser;

TYPE

   { oxTScopesSerialization }

   oxTScopesSerialization = record
      f: TFile;
      parser: PScopesParser;

      procedure Init();

      function Read(): TObject;
      function Write(obj: TObject): boolean;
   end;

IMPLEMENTATION

{ oxTScopesSerialization }

procedure oxTScopesSerialization.Init();
begin
   ZeroOut(Self, SizeOf(Self));
end;

function oxTScopesSerialization.Read(var f: TFile): TObject;
begin

end;

function oxTScopesSerialization.Write(var f: TFile; obj: TObject): boolean;
begin

end;

END.
