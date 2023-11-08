{
   wdguTemplate, template widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguTemplate;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, wdguBase;

TYPE
   wdgTTemplate = class(uiTWidget)
      {override any callbacks here, and expand the class}
   end;

   wdgTTemplateGlobal = class(specialize wdgTBase<wdgTTemplate>)
     Internal: uiTWidgetClass; static;

     {adds a template widget to a window}
     function Add(const Caption: StdString; const Pos: oxTPoint; const Dim: oxTDimensions): wdgTTemplate;
   end;


VAR
   wdgTemplate: wdgTTemplateGlobal;

IMPLEMENTATION

procedure InitWidget();
begin
   wdgTemplate.internal.Instance := wdgTTemplate;
   wdgTemplate.internal.Done();

   wdgTemplate := wdgTTemplateGlobal.Create(wdgTemplate.Internal);
end;

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

INITIALIZATION
   wdgTemplate.Internal.Register('widget.template', @InitWidget);

END.
