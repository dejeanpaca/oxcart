{
   uiuFiles, file related ui stuff
   Copyright (C) 2018. Dejan Boras

   Started On:    13.12.2018.
}

{$INCLUDE oxdefines.inc}
UNIT uiuSettings;

INTERFACE

   USES
      udvars, uStd,
      {ox}
      oxuUI;

TYPE

   { uiTSettings }

   uiTSettings = record
      NaturalScroll: boolean;

      function ScrollDirection(): loopint;
   end;

VAR
  uiSettings: uiTSettings;

IMPLEMENTATION

VAR
   dvNaturalScroll: TDVar;

{ uiTSettings }

function uiTSettings.ScrollDirection(): loopint;
begin
   if(not NaturalScroll) then
      Result := 1
   else
      Result := -1;
end;

INITIALIZATION
   oxTUI.dvg.Add(dvNaturalScroll, 'natural_scroll', dtcBOOL, @uiSettings.NaturalScroll);

END.
