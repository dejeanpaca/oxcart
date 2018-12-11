{
   uJSON, json reading/writing support
   Copyright (C) 2018. Dejan Boras

   Started On:    09.01.2018,
}

{$INCLUDE oxdefines.inc}
UNIT uJSON;

INTERFACE

   USES
      uStd, uParserBase;

TYPE

   { TJSONWriter }

   TJSONParser = object(TParserBase)
      public
         CurrentLevel: loopint;
         CurrentElement: loopint;

      function OnWrite(): boolean; virtual;
   end;

IMPLEMENTATION

{ TJSONWriter }

function TJSONParser.OnWrite(): boolean;
begin
   Result := true;
end;

END.
