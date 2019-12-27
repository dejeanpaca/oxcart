{
   wdguStatusbar, serves as an empty are to place other widgets to, creates a bar at the bottom of a window
   Copyright (C) 2017. Dejan Boras

   Started On:    05.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT wdguStatusbar;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuWidget, uiWidgets, uiuRegisteredWidgets,
      wdguBase, wdguWorkbar;

TYPE

   { wdgTStatusbar }

   wdgTStatusbar = class(wdgTWorkbar)
      constructor Create(); override;

      procedure Initialize; override;
      procedure Render; override;
   end;

   { wdgTStatusbarGlobal }

   wdgTStatusbarGlobal = class(specialize wdgTBase<wdgTStatusbar>)
      Internal: uiTWidgetClass; static;

      {default height}
      Height: longint; static;
      Color: TColor4ub; static;

      function Add(wnd: uiTWindow): wdgTStatusbar;

      protected
         procedure OnAdd(wdg: wdgTStatusbar); override;
   end;

VAR
   wdgStatusbar: wdgTStatusbarGlobal;

IMPLEMENTATION

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

function wdgTStatusbarGlobal.Add(wnd: uiTWindow): wdgTStatusbar;
begin
   uiWidget.SetTarget(wnd);
   Result := inherited Add();
end;

procedure wdgTStatusbarGlobal.OnAdd(wdg: wdgTStatusbar);
begin
   wdg.AutoPositionTarget := wdgWORKBAR_POSITION_BOTTOM;
   wdg.AutoPosition();
end;

procedure init();
begin
   wdgStatusbar.Internal.Done(wdgTStatusbar);

   wdgStatusbar := wdgTStatusbarGlobal.Create(wdgStatusbar.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgStatusbar);
end;

INITIALIZATION
   wdgStatusbar.Internal.Register('widget.statusbar', @init, @deinit);

   wdgStatusbar.Height := wdgWORKBAR_HEIGHT;
   wdgStatusbar.Color.Assign(255, 127, 0, 255);

END.
