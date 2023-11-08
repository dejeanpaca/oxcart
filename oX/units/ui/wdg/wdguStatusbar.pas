{
   wdguStatusbar, serves as an empty are to place other widgets to, creates a bar at the bottom of a window
   Copyright (C) 2017. Dejan Boras

   Started On:    05.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguStatusbar;

INTERFACE

   USES
      uColors,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuWidget, uiWidgets,
      wdguWorkbar;

TYPE

   { wdgTStatusbar }

   wdgTStatusbar = class(wdgTWorkbar)
      constructor Create(); override;

      procedure Initialize; override;
      procedure Render; override;
   end;

   { wdgTStatusbarGlobal }

   wdgTStatusbarGlobal = record
      {default height}
      Height: longint;
      Color: TColor4ub;

      class function Add(wnd: uiTWindow): wdgTStatusbar; static;
      class function Add(): wdgTStatusbar; static;
   end;

VAR
   wdgStatusbar: wdgTStatusbarGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := wdgTStatusbar;
   internal.Done();
end;

{ wdgTStatusbar }

constructor wdgTStatusbar.Create;
begin
   inherited;

   Height := wdgStatusbar.Height;
end;

procedure wdgTStatusbar.Initialize;
begin
   inherited Initialize;

   Color := wdgStatusbar.Color;
end;

procedure wdgTStatusbar.Render;
var
   r: oxTRect;

begin
   inherited Render;

   r.Assign(RPosition, Dimensions);
   r.x := r.x + wdgDEFAULT_SPACING;
   r.w := r.w - wdgDEFAULT_SPACING;

   CachedFont.Start();
   SetColorBlended(GetColorset()^.Text);
   CachedFont.WriteCentered(Caption, r, [oxfpCenterLeft, oxfpCenterVertical]);
   oxf.Stop();
end;


{ wdgTStatusbarGlobal }

class function wdgTStatusbarGlobal.Add(wnd: uiTWindow): wdgTStatusbar;
begin
   uiWidget.SetTarget(wnd);
   result := Add();
end;

class function wdgTStatusbarGlobal.Add(): wdgTStatusbar;
begin
   result := wdgTStatusbar(uiWidget.Add(internal, oxNullPoint, oxNullDimensions));
   result.AutoPositionTarget := wdgWORKBAR_POSITION_BOTTOM;
   result.AutoPosition();
end;

INITIALIZATION
   internal.Register('widget.statusbar', @initializeWidget);

   wdgStatusbar.Height := wdgWORKBAR_HEIGHT;
   wdgStatusbar.Color.Assign(255, 127, 0, 255);
END.

