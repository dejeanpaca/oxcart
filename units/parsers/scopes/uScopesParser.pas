{
   uScopesParser, scopes interchange format reading/writing support
   Copyright (C) 2018. Dejan Boras

   Started On:    09.01.2018,
}

{$INCLUDE oxdefines.inc}
UNIT uScopesParser;

INTERFACE

   USES
      uStd, uParserBase;

TYPE
   PScopesParser = ^TScopesParser;

   { TScopesParser }

   TScopesParser = object(TParserBase)
      public
         CurrentLevel: loopint;
         CurrentElement: loopint;

      function OnWrite(): boolean; virtual;
   end;

IMPLEMENTATION

{ TScopesParser }

function TScopesParser.OnWrite(): boolean;
begin
   Result := true;
end;

END.
