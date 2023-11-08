{
   uScopesParser, scopes interchange format reading/writing support
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
