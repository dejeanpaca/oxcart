{
   wdguGroup, ui group widget
   Copyright (C) 2016. Dejan Boras

   Started On:    29.11.2016.
}

{$INCLUDE oxdefines.inc}
UNIT wdguGroup;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiuWindow, uiWidgets, uiuWidgetRender, uiuDraw,
      wdguBase;

TYPE

   { wdgTGroup }
   wdgTGroup = class(uiTWidget)
      {is the group transparent}
      Transparent,
      {should the border render}
      RenderBorder: boolean;

      constructor Create(); override;

      procedure Render(); override;
   end;

   { wdgTGroupGlobal }

   wdgTGroupGlobal = class(specialize wdgTBase<wdgTGroup>)
      Internal: uiTWidgetClass; static;

      function Add(const Caption: StdString;
                 const Pos: oxTPoint; const Dim: oxTDimensions): wdgTGroup;
   end;

VAR
   wdgGroup: wdgTGroupGlobal;

IMPLEMENTATION

constructor wdgTGroup.Create();
begin
   inherited;

   Transparent := true;
   RenderBorder := true;
   SetPadding(4);
end;

procedure wdgTGroup.Render();
var
   f: oxTFont;
   fh: loopint;

begin
   f := CachedFont;
   fh := f.GetHeight();

   if(not Transparent) then begin
      SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Surface);
      uiDraw.Box(RPosition, Dimensions);
   end;

   if(RenderBorder) then begin
      SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Text);
      uiRenderWidget.CurvedFrame(RPosition.x, RPosition.y - Dimensions.h + 1, RPosition.x + Dimensions.w - 1, RPosition.y - fh div 2);
   end;

   if(Caption <> '') then begin
      if(RenderBorder) then begin
         if(not Transparent) then
            SetColor(uiTSkin(uiTWindow(wnd).Skin).Colors.Surface)
         else
            SetColor(Parent.GetSurfaceColor());

         uiDraw.HLine(RPosition.x + 4, RPosition.y - fh div 2, RPosition.x + 12 + f.GetLength(Caption));
      end;

      SetColorBlended(uiTSkin(uiTWindow(wnd).Skin).Colors.Text);
      f.Start();
         f.Write(RPosition.x + 8, RPosition.y - fh, Caption);
      oxf.Stop();
   end;
end;

procedure InitWidget();
begin
   wdgGroup.Internal.NonSelectable := true;
   wdgGroup.Internal.Instance := wdgTGroup;
   wdgGroup.Internal.Done();

   wdgGroup := wdgTGroupGlobal.Create(wdgGroup.Internal);
end;

function wdgTGroupGlobal.Add(const Caption: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions): wdgTGroup;
begin
   Result := inherited AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      AddDone(Result);
   end;
end;

INITIALIZATION
   wdgGroup.Internal.Register('widget.group', @InitWidget);

END.
