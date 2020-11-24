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
      {how many subdivisions to use for rendering}
      RenderSubdivisions: loopint;

      function ScrollDirection(): loopint;
   end;

VAR
  uiSettings: uiTSettings;

IMPLEMENTATION

VAR
   dvNaturalScroll,
   dvRenderSubdivisions: TDVar;

{ uiTSettings }

function uiTSettings.ScrollDirection(): loopint;
begin
   if(not NaturalScroll) then
      Result := 1
   else
      Result := -1;
end;

INITIALIZATION
   uiSettings.RenderSubdivisions := 64;

   uiTUI.dvg.Add(dvNaturalScroll, 'natural_scroll', dtcBOOL, @uiSettings.NaturalScroll);
   uiTUI.dvg.Add(dvRenderSubdivisions, 'render_subdivisions', dtcLOOPINT, @uiSettings.RenderSubdivisions);

END.
