{
   wdguColorPick, color pick widget
   Copyright (C) 2018. Dejan Boras

   Started On:    10.02.2018.
}

{$INCLUDE oxdefines.inc}
UNIT wdguColorPick;

INTERFACE

   USES
      uColors,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuwndColorPicker, uiuWindowTypes,
      {ui}
      uiuWidget, uiWidgets, uiuWidgetRender;


TYPE

   { wdgTColorPick }

   wdgTColorPick = class(uiTWidget)
      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;

      procedure PickerCallback(dialog: oxwndTColorPickerDialog);

      procedure DeInitialize(); override;
   end;

   uiTWidgetColorPickGlobal = record
     function Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTColorPick;
   end;

VAR
   wdgColorPick: uiTWidgetColorPickGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

procedure initializeWidget();
begin
   internal.Instance := wdgTColorPick;
   internal.Done();
end;

procedure wdgTColorPick.Render();
begin
   uiRenderWidget.Box(uiTWidget(self), Color, uiTWindow(wnd).Skin.Colors.Border);
end;

procedure wdgTColorPick.Point(var e: appTMouseEvent; x, y: longint);
begin
   if(e.IsReleased()) then begin
      oxwndColorPicker.ObjectCallback := @PickerCallback;
      oxwndColorPicker.Open();
   end;
end;

procedure wdgTColorPick.PickerCallback(dialog: oxwndTColorPickerDialog);
begin
   if(not dialog.Canceled) then
      Color := dialog.SelectedColor;
end;

procedure wdgTColorPick.DeInitialize();
begin
   inherited DeInitialize();

   if(oxwndColorPicker <> nil) and (oxwndColorPicker.ObjectCallback = @PickerCallback) then
      oxwndColorPicker.ObjectCallback := nil;
end;

function uiTWidgetColorPickGlobal.Add(const Pos: oxTPoint; const Dim: oxTDimensions): wdgTColorPick;
begin
   result := wdgTColorPick(uiWidget.Add(internal, Pos, Dim));
end;

INITIALIZATION
   internal.Register('widget.color_pick', @initializeWidget);

END.

