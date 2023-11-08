{
   wdguControllerInputState, represents state for an input (controller) button
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguControllerInputState;

INTERFACE

   USES
      uStd, uColors, vmMath,
      {oX}
      oxuTypes, oxumPrimitive, oxuFont, oxuMaterial,
      {ui}
      uiuWidget, uiWidgets, uiuDraw, uiuRegisteredWidgets, oxuUI,
      wdguBase;

TYPE

   { wdgTControllerButtonState }

   wdgTControllerButtonState = class(uiTWidget)
      public
         ButtonName: StdString;
         Pressure: single;

      procedure Initialize(); override;

      procedure SetPressure(newPressure: single);

      procedure Render(); override;
      procedure GetComputedDimensions(out d: oxTDimensions); override;
   end;

   wdgTControllerButtonStateGlobal = object(specialize wdgTBase<wdgTControllerButtonState>)
   public
      Defaults: record
        Width,
        Height: loopint;
      end;
   end;

VAR
   wdgControllerButtonState: wdgTControllerButtonStateGlobal;

IMPLEMENTATION

procedure wdgTControllerButtonState.SetPressure(newPressure: single);
begin
   Pressure := newPressure;

   vmClamp(Pressure, 0, 1.0);
end;

procedure wdgTControllerButtonState.Render();
var
   clr: TColor4ub;
   r: single;

begin
   {render surface}
   clr := GetSkinObject().Colors.Highlight;
   clr[3] := round(Pressure * 255);

   oxui.Material.SetColor('color', clr);

   r := vmMin(Dimensions.w, Dimensions.h);

   uiDraw.Disk(RPosition.x, RPosition.y, r);

   {render border}
   SetColor(GetSkinObject().Colors.Border);
   uiDraw.Circle(RPosition.x, RPosition.y, r);

   {render button name, if set}
   if(ButtonName <> '') then begin
      SetColor(GetSkinObject().Colors.TextInHighlight);
      oxf.Start();
      CachedFont.Start();
      CachedFont.Write(RPosition.x, RPosition.y, ButtonName);
      oxf.Stop();
   end;
end;

procedure wdgTControllerButtonState.GetComputedDimensions(out d: oxTDimensions);
begin
   d.w := wdgControllerButtonState.Defaults.Width;
   d.h := wdgControllerButtonState.Defaults.Height;
end;

INITIALIZATION
   wdgControllerButtonState.Create('controller_button_state');

   wdgControllerButtonState.Defaults.Width := 20;
   wdgControllerButtonState.Defaults.Height := 20;

END.
