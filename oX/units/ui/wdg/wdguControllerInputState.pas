{
   wdguControllerInputState, represents state for an input (controller) button
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguControllerInputState;

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

   { wdgTControllerButtonState }

   wdgTControllerButtonState = class(uiTWidget)
      public
         ButtonName: StdString;
         ButtonIndex: loopint;
         Pressure: single;

      procedure SetPressure(newPressure: single);

      procedure Render(); override;
      procedure GetComputedDimensions(out d: oxTDimensions); override;
   end;

   wdgTControllerButtonStateGlobal = object(specialize wdgTBase<wdgTControllerButtonState>)
   public
      Defaults: record
         Width,
         Height: loopint;

         SurfaceColor,
         HighlightColor: TColor4ub;
      end;
   end;

   { wdgTControllerDPadState }

   wdgTControllerDPadState = class(uiTWidget)
      public
         DirectionVector: TVector2;

      procedure SetDirection(newDirection: loopint);
      procedure SetDirection(newDirection: TVector2);
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
   wdgControllerButtonState: wdgTControllerButtonStateGlobal;
   wdgControllerDPadState: wdgTControllerDPadStateGlobal;

IMPLEMENTATION

{ wdgTControllerButtonState }

procedure wdgTControllerButtonState.SetPressure(newPressure: single);
begin
   Pressure := newPressure;

   vmClamp(Pressure, 0, 1.0);
end;

procedure wdgTControllerButtonState.Render();
var
   clr: TColor4ub;
   radius: single;
   r: oxTRect;

begin
   clr := wdgControllerButtonState.Defaults.SurfaceColor;

   {render surface}
   clr := TColor4ub.Interpolate(wdgControllerButtonState.Defaults.SurfaceColor,
      wdgControllerButtonState.Defaults.HighlightColor, Pressure);

   SetColor(clr);

   radius := vmMin(Dimensions.w, Dimensions.h) / 2;

   uiDraw.Disk(RPosition.x + radius, RPosition.y - radius, radius * 0.9);

   {render border}
   SetColor(GetSkinObject().Colors.Border);
   uiDraw.Circle(RPosition.x + radius, RPosition.y - radius, radius * 0.9);

   {render button name, if set}
   if(ButtonName <> '') then begin
      SetColor(GetSkinObject().Colors.TextInHighlight);
      oxf.Start();
      CachedFont.Start();

      r.Assign(RPosition, Dimensions);

      CachedFont.WriteCentered(ButtonName, r);
      oxf.Stop();
   end;
end;

procedure wdgTControllerButtonState.GetComputedDimensions(out d: oxTDimensions);
begin
   d.w := wdgControllerButtonState.Defaults.Width;
   d.h := wdgControllerButtonState.Defaults.Height;
end;

{ wdgTControllerDPadState }

procedure wdgTControllerDPadState.SetDirection(newDirection: loopint);
begin
   DirectionVector := appTControllerDevice.GetDPadDirectionVector(newDirection);
end;

procedure wdgTControllerDPadState.SetDirection(newDirection: TVector2);
begin
   DirectionVector := newDirection;
end;

procedure wdgTControllerDPadState.Render();
var
   radius: single;
   center,
   p: TVector2f;

begin
   SetColor(wdgControllerDPadState.Defaults.SurfaceColor);
   radius := vmMin(Dimensions.w, Dimensions.h) / 2;

   uiDraw.Disk(RPosition.x + radius, RPosition.y - radius, radius * 0.95);

   if(DirectionVector <> vmvZero2) then begin
      SetColor(wdgControllerDPadState.Defaults.HighlightColor);

      center[0] := RPosition.x + radius;
      center[1] := RPosition.y - radius;

      p := Center;
      p := p + (DirectionVector * radius);

      uiDraw.Line(center, p);
   end;
end;

procedure wdgTControllerDPadState.GetComputedDimensions(out d: oxTDimensions);
begin
   d := wdgControllerDPadState.Defaults.Dimensions;
end;


INITIALIZATION
   { wdgControllerButtonState }

   wdgControllerButtonState.Create('controller_button_state');

   wdgControllerButtonState.Defaults.Width := 25;
   wdgControllerButtonState.Defaults.Height := 25;

   wdgControllerButtonState.Defaults.SurfaceColor := cBlack4ub;
   wdgControllerButtonState.Defaults.HighlightColor := cRed4ub;

   { wdgControllerDPadState }

   wdgControllerDPadState.Create('controller_button_state');

   wdgControllerDPadState.Defaults.Dimensions.Assign(80, 80);

   wdgControllerDPadState.Defaults.SurfaceColor := cBlack4ub;
   wdgControllerDPadState.Defaults.HighlightColor := cRed4ub;

END.
