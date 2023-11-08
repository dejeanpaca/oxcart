{
   wdguTemplate, template widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguTemplate;

INTERFACE

   USES
      {oX}
      oxuTypes,
      {ui}
      uiuWindowTypes, uiuWidget, uiWidgets;

TYPE
   wdgTTemplate = class(uiTWidget)
      {override any callbacks here, and expand the class}
   end;

   uiTWidgetTemplateGlobal = record
     {adds a template widget to a window}
     function Add(var wnd: uiTWindow; const Caption: StdString;
                 const Pos: oxTPoint; const Dim: oxTDimensions): wdgTTemplate;
   end;


VAR
   wdgTemplate: uiTWidgetTemplateGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetInternal;

procedure InitWidget();
begin
   internal.wdgClass.Instance := wdgTTemplate;
   internal.Done();
end;

function uiTWidgetTemplateGlobal.Add(var wnd: uiTWindow; const Caption: StdString;
      const Pos: oxTPoint; const Dim: oxTDimensions): wdgTTemplate;

begin
   result := wdgTTemplate(uiWidget.Add(wnd, internal.wdgClass, Pos, Dim));
   if(result <> nil) then begin
      {setup the caption}
      result.SetCaption(Caption);

      {auto set dimensions if the widget supports it}
      result.AutoSize();

      {NOTE: Perform extra initialization here}
   end;
end;

INITIALIZATION
   internal.Register('widget.template', @InitWidget);

END.
