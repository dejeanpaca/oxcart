{
   uiuCursorRenderer, custom cursor renderer
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuCursorRenderer;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuTypes, oxuTexture, oxuTransform, oxuRender,
      {ui}
      oxuUI, uiuWindowTypes, uiuWindow, uiuDraw, uiuCursor;

IMPLEMENTATION

procedure renderCursor({%H-}wnd: uiTWindow);
var
   size: oxTDimensions;
   tex: oxTTexture;

begin
   if(uiCursor.CustomCursor > 0) and (uiCursor.CustomCursor <= uiCursor.CustomCursors.n) then begin
      tex := uiCursor.CustomCursors.List[uiCursor.CustomCursor - 1];
      if(tex.rId = 0) then
         exit;

      {get size from texture or from overriden size}
      if(uiCursor.CursorSize.w > 0) then
         size.w := uiCursor.CursorSize.w
      else
         size.w := tex.Width;

      if(uiCursor.CursorSize.h > 0) then
         size.h := uiCursor.CursorSize.h
      else
         size.h := tex.Height;

      {move into position}
      oxTransform.Identity();
      oxTransform.Translate(oxui.mSelect.startPoint.x + (size.w / 2), oxui.mSelect.startPoint.y - (size.h / 2), 0);
      oxTransform.Scale(size.w / 2, size.h / 2, 0);
      oxTransform.Apply();

      {bind texture}
      oxRender.EnableBlend();
      uiDraw.Color(1.0, 1.0, 1.0, 1.0);
      uiDraw.Quad(tex);

      oxTransform.Identity();
      oxTransform.Apply();
   end;
end;

procedure init();
begin
   uiWindow.OxwPostRender.Add(@renderCursor);
end;

INITIALIZATION
   ox.Init.Add('ui.cursor.render', @init);

END.
