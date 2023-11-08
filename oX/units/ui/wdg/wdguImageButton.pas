{
   wdguImageButton, image button widget
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguImageButton;

INTERFACE

   USES
      uStd, uColors, uFile, vmVector,
      {app}
      appuEvents,
      {oX}
      oxuTypes, oxuRender, oxuTransform, oxuTexture, oxuTextureGenerate, oxumPrimitive,
      oxuFont, oxuResourcePool,
      {ui}
      uiuTypes, uiuWidget, uiWidgets, uiuWindowTypes, uiuWindow, uiuSkinTypes, oxuMaterial, oxuUI,
      wdguBase, wdguButton, wdguImage;

CONST

  wdgscIMAGE_BUTTON_REGULAR = 0;
  wdgscIMAGE_BUTTON_REGULAR_DISABLED = 1;
  wdgscIMAGE_BUTTON_HIGHLIGHT = 2;

  wdgImageButtonSkinColorDescriptor: array[0..2] of uiTWidgetSkinColorDescriptor = (
      (
         Name: 'regular';
         Color: (255, 255, 255, 255)
      ),
      (
         Name: 'regular_disabled';
         Color: (127, 127, 127, 255)
      ),
      (
         Name: 'highlight';
         Color: (192, 192, 255, 255)
      )
   );

TYPE
   { wdgTImageButton }

   wdgTImageButton = class(wdgTButton)
      public
         Texture: wdgTImageTexture;

         {does the button consists only of image(s)}
         UseOnlyImage: boolean;

         ImageWidth,
         ImageHeight: longint;

      constructor Create(); override;

      procedure Initialize(); override;
      procedure DeInitialize(); override;

      procedure Render(); override;

      procedure SetImage(const fn: StdString);
      procedure SetImage(tex: oxTTexture);
      procedure CalculateQuad();

      procedure GetComputedDimensions(out d: oxTDimensions); override;

      {returns spacing, if any required}
      function GetSpacing(f: oxTFont): loopint;

      {set the button to only use the image}
      function OnlyImage(): wdgTImageButton;

      protected
         {quad used to render the image}
         Quad: oxTPrimitiveModel;

         procedure SizeChanged; override;
         procedure CaptionChanged; override;
   end;

   { wdgTImageButtonGlobal }

   wdgTImageButtonGlobal = object(specialize wdgTBase<wdgTImageButton>)
      function Add(const fn: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions; action: TEventID = 0): wdgTImageButton;

      function Add(const fn: StdString; const Caption: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions; action: TEventID = 0): wdgTImageButton;

      function Add(const fn: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions; callback: TProcedure): wdgTImageButton;

      function Add(const fn: StdString; const Caption: StdString;
            const Pos: oxTPoint; const Dim: oxTDimensions; callback: TProcedure): wdgTImageButton;
   end;

VAR
   wdgImageButton: wdgTImageButtonGlobal;

IMPLEMENTATION

{ wdgTImageButton }

constructor wdgTImageButton.Create();
begin
   inherited Create;

   oxmPrimitive.Init(Quad);
   SetPadding(0);
   SetBorder(1);
end;

procedure wdgTImageButton.Initialize();
begin
   inherited Initialize;

   Color := GetColor(wdgscIMAGE_BUTTON_REGULAR);
end;

procedure wdgTImageButton.DeInitialize();
begin
   inherited DeInitialize();

   oxResource.Destroy(Texture);
end;

procedure wdgTImageButton.Render();
var
   f: oxTFont;
   spc,
   w,
   h,
   x,
   y,
   captionLength,
   captionY,
   imageY: loopint;
   m: TMatrix4f;

begin
   m := oxTransform.Matrix;

   if(not UseOnlyImage) then
      RenderBase();

   f := CachedFont;

   {we'll assume we have nothing to render}
   w := 0;
   h := 0;

   y := RPosition.y;

   {set width to texture width and height to texture height}
   if(Texture.Has) then begin
      inc(w, Texture.Texture.Width);
      h := Texture.Texture.Height;
   end;

   {use font height if greater}
   if(f.GetHeight() > h) then
      h := f.GetHeight();

   {there is only spacing if we have both an image and caption}
   spc := GetSpacing(f);
   inc(w, spc);

   if(Pressed) then
      y := y - 2;

   {if there is a caption, increase total size by it, and determine where to put it}
   if(Caption <> '') then begin
      captionLength := f.GetLength(Caption);
      inc(w, captionLength);
      captionY := y - ((Dimensions.h - f.GetHeight()) div 2) - f.GetHeight();
   end else begin
      captionLength := 0;
      captionY := 0;
   end;

   {the start position of our content (image, spacing, caption), centered}
   x := RPosition.x + ((Dimensions.w - w) div 2);

   if(Pressed) then
      x := x + 2;

   {render image if any}
   if(Texture.Has()) then begin
      imageY := y - ((Dimensions.h - ImageHeight) div 2);

      if(wdgpENABLED in Properties) then begin
         if(not Hovering()) then begin
            if(not Texture.Texture.HasAlpha()) then
               SetColor(Color)
            else
               SetColorBlended(Color);
         end else begin
            if(not Texture.Texture.HasAlpha()) then
               SetColor(wdgscIMAGE_BUTTON_HIGHLIGHT)
            else
               SetColorBlended(wdgscIMAGE_BUTTON_HIGHLIGHT);
         end;
      end else begin
         if(not Texture.Texture.HasAlpha()) then
            SetColor(wdgscIMAGE_BUTTON_REGULAR_DISABLED)
         else
            SetColorBlended(wdgscIMAGE_BUTTON_REGULAR_DISABLED);
      end;

      oxTransform.Translate(x, imageY, 0);
      oxTransform.Apply();

      Quad.Render();
      uiDraw.ClearTexture();

      oxTransform.Apply(m);
   end;

   {render caption if any}
   if(Caption <> '') then begin
      f.Start();
      SetColorBlendedEnabled(
         uiTSkin(uiTWindow(wnd).Skin).Colors.Text,
         uiTSkin(uiTWindow(wnd).Skin).DisabledColors.Text);

      f.Write(x + w - captionLength, captionY, Caption);
      oxf.Stop();
   end;
end;

procedure wdgTImageButton.SetImage(const fn: StdString);
begin
   if(Texture.SetImage(fn)) then
      CalculateQuad();
end;

procedure wdgTImageButton.SetImage(tex: oxTTexture);
begin
   if(Texture.SetImage(tex)) then begin
      AutoSize();
      CalculateQuad();
   end;
end;

procedure wdgTImageButton.CalculateQuad();
var
   w,
   h: loopint;

begin
   if(Texture.Has()) then begin
      w := Texture.Texture.Width;
      h := Texture.Texture.Height;

      if(Dimensions.w < w) and (Dimensions.w > 0) then
         w := Dimensions.w;

      if(Dimensions.h < h) and (Dimensions.h > 0) then
         h := Dimensions.h;

      ImageWidth := w;
      ImageHeight := h;

      Quad.Quad();

      Quad.Scale(round(w / 2), round(h / 2), 0);
      Quad.Translate(round(w / 2), -round(h / 2), 0);
   end;
end;

procedure wdgTImageButton.GetComputedDimensions(out d: oxTDimensions);
var
   f: oxTFont;
   h: longint;

begin
   f := CachedFont;

   d.w := 0;
   d.h := 0;

   if(not UseOnlyImage) then begin
      inc(d.w, PaddingLeft + PaddingTop + Border);
      inc(d.h, PaddingBottom + PaddingTop + Border);
   end;

   h := 0;

   if(Caption <> '') then begin
      inc(d.w, f.GetLength(Caption));

      h := f.GetHeight();
   end;

   if(Texture.Has()) then begin
      inc(d.w, Texture.Texture.Width);

      if(Texture.Texture.Height > h) then
         h := Texture.Texture.Height;
   end;

   inc(d.w, GetSpacing(f));

   inc(d.h, h);
end;

function wdgTImageButton.GetSpacing(f: oxTFont): loopint;
begin
   if(Texture.Has() and (Caption <> '')) then
      Result := f.GetWidth() div 2
   else
      Result := 0;
end;

function wdgTImageButton.OnlyImage(): wdgTImageButton;
begin
   UseOnlyImage := true;
   AutoSize();

   Result := Self;
end;

procedure wdgTImageButton.SizeChanged;
begin
   inherited SizeChanged;

   CalculateQuad();
end;

procedure wdgTImageButton.CaptionChanged;
begin
   inherited CaptionChanged;

   CalculateQuad();
end;

function wdgTImageButtonGlobal.Add(const fn: StdString;
      const Pos: oxTPoint; const Dim: oxTDimensions; action: TEventID = 0): wdgTImageButton;

begin
   Result := Add(fn, '', Pos, Dim, action);
end;

function wdgTImageButtonGlobal.Add(const fn: StdString; const Caption: StdString;
   const Pos: oxTPoint; const Dim: oxTDimensions; action: TEventID = 0): wdgTImageButton;

begin
   Result := inherited AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      Result.SetImage(fn);
      Result.ActionEvent := action;

      AddDone(Result);

      Result.CalculateQuad();
   end;
end;

function wdgTImageButtonGlobal.Add(const fn: StdString; const Pos: oxTPoint;
   const Dim: oxTDimensions; callback: TProcedure): wdgTImageButton;
begin
   Result := Add(fn, '', Pos, Dim, callback);
end;

function wdgTImageButtonGlobal.Add(const fn: StdString; const Caption: StdString;
   const Pos: oxTPoint; const Dim: oxTDimensions; callback: TProcedure): wdgTImageButton;
begin
   Result := Add(fn, Caption, Pos, Dim, 0);
   Result.Callback.Use(callback);
end;

INITIALIZATION
   wdgImageButton.Create('image_button');
   wdgImageButton.Internal.SkinDescriptor.UseColors(wdgImageButtonSkinColorDescriptor);

END.
