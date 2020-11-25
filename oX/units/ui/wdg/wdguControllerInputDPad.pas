{
   wdguControllerInputDPad, represents state for an input (controller) directional pad
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguControllerInputDPad;

INTERFACE

   USES
      uStd, uColors, vmMath, vmVector,
      {app}
      appuController,
      {oX}
      oxuTypes, oxumPrimitive, oxuFont, oxuMaterial,
      {ui}
      uiuWidget, uiWidgets, uiuDraw, uiuRegisteredWidgets, oxuUI,
      wdguBase;

TYPE

   { wdgTControllerDPadState }

   wdgTControllerDPadState = class(uiTWidget)
      public
         Direction: loopint;

      procedure SetDirection(newDirection: loopint);
      procedure Render(); override;
      procedure GetComputedDimensions(out d: oxTDimensions); override;
   end;

   wdgTControllerDPadStateGlobal = object(specialize wdgTBase<wdgTControllerDPadState>)
   public
      Defaults: record
         Dimensions: oxTDimensions;

         SurfaceColor,
         HighlightColor: TColor4ub;
      end;
   end;

VAR
   wdgControllerDPadState: wdgTControllerDPadStateGlobal;

IMPLEMENTATION

procedure wdgTControllerDPadState.SetDirection(newDirection: loopint);
begin
   Direction := newDirection;
end;

procedure wdgTControllerDPadState.Render();
var
   radius: single;
   center,
   v,
   p: TVector2f;

begin
   SetColor(wdgControllerDPadState.Defaults.SurfaceColor);
   radius := vmMin(Dimensions.w, Dimensions.h) / 2;

   uiDraw.Disk(RPosition.x + radius, RPosition.y - radius, radius * 0.95);

   if(Direction <> appCONTROLLER_DIRECTION_NONE) then begin
      SetColor(wdgControllerDPadState.Defaults.HighlightColor);

      center[0] := RPosition.x + radius;
      center[1] := RPosition.y - radius;

      p := Center;
      v := appTControllerDevice.GetDPadDirectionVector(Direction);
      p := p + (v * radius);

      uiDraw.Line(center, p);
   end;
end;

procedure wdgTControllerDPadState.GetComputedDimensions(out d: oxTDimensions);
begin
   d := wdgControllerDPadState.Defaults.Dimensions;
end;

INITIALIZATION
   wdgControllerDPadState.Create('controller_button_state');

   wdgControllerDPadState.Defaults.Dimensions.Assign(80, 80);

   wdgControllerDPadState.Defaults.SurfaceColor := cBlack4ub;
   wdgControllerDPadState.Defaults.HighlightColor := cRed4ub;

END.
