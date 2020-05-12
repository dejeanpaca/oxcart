{
   wdguWorkbar, empty bar to place other widgets to, creates a bar of sorts
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguWorkbar;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiWidgets, uiuDraw, uiuRegisteredWidgets, uiuWindow, uiuControl,
      wdguBase;

CONST
   wdgWORKBAR_HEIGHT = 22;

TYPE
   wdgTWorkbarPositionTarget = (
      wdgWORKBAR_POSITION_NONE,
      wdgWORKBAR_POSITION_TOP,
      wdgWORKBAR_POSITION_RIGHT,
      wdgWORKBAR_POSITION_BOTTOM,
      wdgWORKBAR_POSITION_LEFT
   );

   { wdgTWorkbar }

   wdgTWorkbar = class(uiTWidget)
      Height: longint;
      {auto position}
      AutoPositionTarget: wdgTWorkbarPositionTarget;
      RenderShadows: boolean;

      constructor Create(); override;
      procedure AutoPosition();

      procedure Initialize; override;

      procedure Render(); override;

      procedure ParentSizeChange; override;
   end;

   { wdgTWorkbarGlobal }

   wdgTWorkbarGlobal = object(specialize wdgTBase<wdgTWorkbar>)
      {default height}
      Height: longint; static;
      Shadows: boolean; static;

      function Add(wnd: uiTWindow): wdgTWorkbar;

      protected
         procedure OnAdd(wdg: wdgTWorkbar); virtual;
   end;

VAR
   wdgWorkbar: wdgTWorkbarGlobal;

IMPLEMENTATION

{ wdgTWorkbar }

constructor wdgTWorkbar.Create;
begin
   inherited;

   AutoPositionTarget := wdgWORKBAR_POSITION_TOP;

   {by default, we'll prevent maximization of windows over the workbar}
   ObscuresMaximization := uiCONTROL_MAXIMIZATION_OBSCURE_VERTICAL;

   Height := wdgWorkbar.Height;
   RenderShadows := wdgWorkbar.Shadows;
end;

procedure wdgTWorkbar.AutoPosition();
var
   p: oxTPoint;
   d: oxTDimensions;

begin
   if(AutoPositionTarget <> wdgWORKBAR_POSITION_NONE) then begin
      if(Parent.ControlType = uiCONTROL_WINDOW) then
         uiTWindow(wnd).GetMaximizationCoords(p, d, Self)
      else begin
         p.x := 0;
         p.y := Parent.Dimensions.h - 1;

         d := Parent.Dimensions;
      end;

      if(AutoPositionTarget = wdgWORKBAR_POSITION_BOTTOM) then
         p.y := p.y - d.h + Height;

      if(AutoPositionTarget = wdgWORKBAR_POSITION_TOP) or (AutoPositionTarget = wdgWORKBAR_POSITION_BOTTOM) then
         d.h := Height;

      if(AutoPositionTarget = wdgWORKBAR_POSITION_RIGHT) then
         p.x := d.w - Height;

      if(AutoPositionTarget = wdgWORKBAR_POSITION_LEFT) or (AutoPositionTarget = wdgWORKBAR_POSITION_RIGHT) then
         d.w := Height;

      Move(p);
      Resize(d);
   end;
end;

procedure wdgTWorkbar.Initialize;
begin
   inherited Initialize;

   Color := uiTSkin(uiTWindow(wnd).Skin).Colors.Surface;
end;

procedure wdgTWorkbar.Render;
var
   x2,
   y2: loopint;

begin
   SetColor(Color);
   uiDraw.Box(RPosition, Dimensions);

   if(RenderShadows) then begin
      x2 := RPosition.x + Dimensions.w - 1;
      y2 := RPosition.y - Dimensions.h + 1;

      SetColor(Color.Lighten(1.4));

      uiDraw.HLine(RPosition.x, RPosition.y, x2);
      uiDraw.VLine(RPosition.x, RPosition.y - 1, y2 + 1);

      SetColor(Color.Darken(0.4));
      uiDraw.HLine(RPosition.x, y2, RPosition.x + Dimensions.w - 1);
      uiDraw.VLine(x2, Rposition.y, y2);
   end;
end;

procedure wdgTWorkbar.ParentSizeChange;
begin
   inherited ParentSizeChange;

   AutoPosition();
end;

{ wdgTWorkbarGlobal }

function wdgTWorkbarGlobal.Add(wnd: uiTWindow): wdgTWorkbar;
begin
   uiWidget.SetTarget(wnd);
   Result := inherited Add();
end;

procedure wdgTWorkbarGlobal.OnAdd(wdg: wdgTWorkbar);
begin
   wdg.AutoPosition();
end;

procedure init();
begin
   wdgWorkbar.Internal.Done(wdgTWorkbar);
end;

INITIALIZATION
   wdgWorkbar.Create();
   wdgWorkbar.Internal.Register('workbar', @init);

   wdgWorkbar.Height := wdgWORKBAR_HEIGHT;
   wdgWorkbar.Shadows := true;

END.
