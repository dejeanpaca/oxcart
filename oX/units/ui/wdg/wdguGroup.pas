{
   wdguGroup, ui group widget
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguGroup;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, oxuFont,
      {ui}
      uiuWindowTypes, uiuSkinTypes,
      uiuWidget, uiuWindow, uiWidgets, uiuWidgetRender, uiuRegisteredWidgets, uiuDraw,
      wdguBase;

CONST
  wdgscGROUP_BORDER = 0;
  wdgscGROUP_SURFACE = 1;

  {TODO: Setup skin, to pickup from default colors}

  wdgGroupSkinColorDescriptor: array[0..1] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'border';
         Color: (18, 18, 18, 255)
      ),
      (
         Name: 'surface';
         Color: (36, 36, 36, 255)
      )
   );

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

   wdgTGroupGlobal = object(specialize wdgTBase<wdgTGroup>)
      function Add(const Caption: StdString;
                 const Pos: oxTPoint; const Dim: oxTDimensions): wdgTGroup;
      function Add(const Caption: StdString): wdgTGroup;
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
      SetColor(GetColor(wdgscGROUP_SURFACE));
      uiDraw.Box(RPosition, Dimensions);
   end;

   if(RenderBorder) then begin
      SetColor(GetColor(wdgscGROUP_BORDER));

      uiRenderWidget.CurvedFrame(RPosition.x, RPosition.y - Dimensions.h + 1,
         RPosition.x + Dimensions.w - 1, RPosition.y - fh div 2);
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

function wdgTGroupGlobal.Add(const Caption: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions): wdgTGroup;
begin
   Result := inherited AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.SetCaption(Caption);

      AddDone(Result);
   end;
end;

function wdgTGroupGlobal.Add(const Caption: StdString): wdgTGroup;
begin
   Result := Add(Caption, oxNullPoint, oxNullDimensions);
end;

INITIALIZATION
   wdgGroup.Create('group');
   wdgGroup.Internal.NonSelectable := true;
   wdgGroup.Internal.SkinDescriptor.UseColors(wdgGroupSkinColorDescriptor);

END.
