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
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgColorPick: wdgTColorPickGlobal;

IMPLEMENTATION

procedure initializeWidget();
begin
   wdgColorPick.Internal.Instance := wdgTColorPick;
   wdgColorPick.Internal.Done();

   wdgColorPick := wdgTColorPickGlobal.Create(wdgColorPick.Internal);
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

INITIALIZATION
   wdgColorPick..Register('widget.color_pick', @initializeWidget);

END.
