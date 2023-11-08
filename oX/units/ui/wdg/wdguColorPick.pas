{
   wdguColorPick, color pick widget
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguColorPick;

INTERFACE

   USES
      uColors,
      {app}
      appuMouse,
      {oX}
      oxuTypes, oxuwndColorPicker, uiuWindowTypes,
      {ui}
      uiuWidget, uiWidgets, uiuWidgetRender, wdguBase;


TYPE

   { wdgTColorPick }

   wdgTColorPick = class(uiTWidget)
      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;

      procedure PickerCallback(dialog: oxwndTColorPickerDialog);

      procedure DeInitialize(); override;
   end;

   wdgTColorPickGlobal = class(specialize wdgTBase<wdgTColorPick>)
   end;

VAR
   wdgColorPick: wdgTColorPickGlobal;

IMPLEMENTATION

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

INITIALIZATION
   wdgColorPick.Create('color_pick');

END.
