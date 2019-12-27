{
   wdguSlider, slider widget
   Copyright (C) 2019. Dejan Boras

   Started On:    28.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT wdguSlider;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase;

TYPE

   { wdgTSlider }

   wdgTSlider = class(uiTWidget)
      Minimum,
      Maximum,
      Value: loopint;

      function SetRange(min, max: loopint): wdgTSlider;
      function SetValue(newValue: loopint): wdgTSlider;

      procedure Render(); override;
   end;

   wdgTSliderGlobal = class(specialize wdgTBase<wdgTSlider>)
     public
     Internal: uiTWidgetClass; static;

     {adds a slider widget to a window}
     function Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTSlider;
   end;


VAR
   wdgSlider: wdgTSliderGlobal;

IMPLEMENTATION

{ wdgTSlider }

function wdgTSlider.SetRange(min, max: loopint): wdgTSlider;
begin
   Minimum := min;
   Maximum := max;

   Result := Self;
end;

function wdgTSlider.SetValue(newValue: loopint): wdgTSlider;
begin
   Value := newValue;

   Result := Self;
end;

procedure wdgTSlider.Render();
begin
end;

function wdgTSliderGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTSlider;

begin
   Result := inherited AddInternal(Pos, Dim);

  if(Result <> nil) then begin
      inherited AddDone(Result);
   end;
end;

procedure init();
begin
   wdgSlider.Internal.Done(wdgTSlider);

   wdgSlider := wdgTSliderGlobal.Create(wdgSlider.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgSlider);
end;

INITIALIZATION
   wdgSlider.Internal.Register('widget.slider', @init, @deinit);

END.
