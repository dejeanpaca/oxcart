{
   wdguTemplate, template widget for the UI
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguTemplate;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase;

TYPE
   wdgTTemplate = class(uiTWidget)
      {override any callbacks here, and expand the class}
   end;

   wdgTTemplateGlobal = object(specialize wdgTBase<wdgTTemplate>)
     {adds a template widget to a window}
     function Add(const Caption: StdString; const Pos: oxTPoint; const Dim: oxTDimensions): wdgTTemplate;
   end;

VAR
   wdgTemplate: wdgTTemplateGlobal;

IMPLEMENTATION

function wdgTTemplateGlobal.Add(const Caption: StdString; const Pos: oxTPoint; const Dim: oxTDimensions): wdgTTemplate;

begin
   Result := inherited AddInternal(Pos, Dim);

  if(Result <> nil) then begin
      {setup the caption}
      Result.SetCaption(Caption);

      {NOTE: Perform extra initialization here}

      inherited AddDone(Result);
   end;
end;

procedure init();
begin
   wdgTemplate.internal.Done(wdgTTemplate);
end;

INITIALIZATION
   wdgTemplate.Create();
   wdgTemplate.Internal.Register('template', @init);

END.
