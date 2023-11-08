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

   wdgTTemplateGlobal = class(specialize wdgTBase<wdgTTemplate>)
     Internal: uiTWidgetClass; static;

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

   wdgTemplate := wdgTTemplateGlobal.Create(wdgTemplate.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgTemplate);
end;

INITIALIZATION
   wdgTemplate.Internal.Register('template', @init, @deinit);

END.
