{
   uiuFiles, file related ui stuff
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuSettings;

INTERFACE

   USES
      udvars, uStd,
      {ox}
      uiuUI;

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
   uiTUI.dvg.Add(dvNaturalScroll, 'natural_scroll', dtcBOOL, @uiSettings.NaturalScroll);

END.
