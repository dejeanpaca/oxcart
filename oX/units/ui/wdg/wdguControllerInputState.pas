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

         mBorder,
         mSurface: oxTPrimitiveModel;

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

procedure wdgTControllerButtonState.Initialize();
begin
   {TODO: Get subdivisions from UI settings}
   {TODO: Get primitive models from global UI primitive models}

   mBorder.InitCircle(1.0, 32);
   mBorder.InitDisk(1.0, 32);
end;

procedure wdgTControllerButtonState.SetPressure(newPressure: single);
begin
   Pressure := newPressure;

   vmClamp(Pressure, 0, 1.0);
end;

procedure wdgTControllerButtonState.Render();
var
   clr: TColor4ub;

begin
   {render surface}
   clr := GetSkinObject().Colors.Highlight;
   clr[3] := round(Pressure * 255);

   oxui.Material.SetColor('color', clr);

   mSurface.Render();

   {render border}
   SetColor(GetSkinObject().Colors.Border);
   mBorder.Render();

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
