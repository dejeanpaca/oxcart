{
   wdguSlider, slider widget
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
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

   wdgTSliderGlobal = object(specialize wdgTBase<wdgTSlider>)
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

INITIALIZATION
   wdgSlider.Create('slider');

END.
