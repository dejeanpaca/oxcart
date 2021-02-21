{
   wdguImage, image widget
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguImage;

INTERFACE

   USES
      uStd, vmVector, uFile, uLog,
      {oX}
      oxuTypes, oxuRender, oxuTransform, oxuTexture, oxuTextureGenerate, oxumPrimitive, oxuPaths, oxuPrimitives,
      oxuResourcePool, oxuUI,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, uiuDraw, uiuWindow, wdguBase;

TYPE

   { wdgTImageTexture }

   wdgTImageTexture = record
      {texture file name used for the image}
      FileName: String;
      {texture used for the image}
      Texture: oxTTexture;

      {set and load a file for the image}
      function SetImage(const fn: StdString): boolean;
      {set an existing texture as the image}
      function SetImage(newTexture: oxTTexture): boolean;

      function Has(): boolean;

      procedure Destroy();
   end;

   { wdgTImage }

   wdgTImage = class(uiTWidget)
     public
        Texture: wdgTImageTexture;

   public
      constructor Create(); override;

      {set and load a file for the image}
      procedure SetImage(const fn: StdString);
      {set an existing texture as the image}
      procedure SetImage(newTexture: oxTTexture);

      procedure Render(); override;

      procedure DeInitialize(); override;

   protected
      {quad used to render the image}
      Quad: oxTPrimitiveModel;

      {create and calculate the image quad}
      procedure CalculateQuad();
      procedure SizeChanged(); override;
   end;

   { wdgTImageGlobal }

   wdgTImageGlobal = object(specialize wdgTBase<wdgTImage>)
      {adds a image to a window}
      function Add(const fn: StdString; const Pos: oxTPoint; const Dim: oxTDimensions): wdgTImage;
      function Add(): wdgTImage;
   end;

VAR
   wdgImage: wdgTImageGlobal;

IMPLEMENTATION

{ wdgTImageTexture }

function wdgTImageTexture.SetImage(const fn: StdString): boolean;
begin
   Result := false;
   oxResource.Destroy(Texture);
   FileName := fn;
   Texture := nil;

   oxTextureGenerate.Generate(fn, Texture);

   Result := Texture <> nil;
end;

function wdgTImageTexture.SetImage(newTexture: oxTTexture): boolean;
begin
   Result := false;
   oxResource.Destroy(Texture);
   FileName := '';
   Texture := newTexture;

   Result := Texture <> nil;
end;

function wdgTImageTexture.Has(): boolean;
begin
   Result := (Texture <> nil) and (Texture.rId <> 0);
end;

procedure wdgTImageTexture.Destroy();
begin
   oxResource.Destroy(Texture);
end;

constructor wdgTImage.Create();
begin
   inherited;

   oxmPrimitive.Init(Quad);
end;

procedure wdgTImage.SetImage(const fn: StdString);
begin
   if(Texture.SetImage(fn)) then
      CalculateQuad();
end;

procedure wdgTImage.SetImage(newTexture: oxTTexture);
begin
   if(Texture.SetImage(newTexture)) then
      CalculateQuad();
end;

procedure wdgTImage.Render();
var
   m: TMatrix4f;

begin
   m := oxTransform.Matrix;
   oxTransform.Translate(RPosition.x, RPosition.y, 0);
   oxTransform.Apply();

   SetColor(Color);

   if(Texture.Has()) then begin
      uiDraw.Texture(Texture.Texture);
      oxRender.TextureCoords(QuadTexCoords[0]);
      Quad.Render();
      uiDraw.ClearTexture();
   end else
      uiDraw.Box(0, 0, Dimensions.w - 1, -(Dimensions.h - 1));

   oxTransform.Apply(m);
end;

procedure wdgTImage.DeInitialize();
begin
   inherited DeInitialize();

   Texture.Destroy();
end;

procedure wdgTImage.CalculateQuad();
begin
   if(Texture.Has()) then begin
      Quad.Quad();
      Quad.Scale(round(Dimensions.w / 2), round(Dimensions.h / 2), 0);
      Quad.Translate(round(Dimensions.w / 2), -round(Dimensions.h / 2), 0);
   end;
end;

procedure wdgTImage.SizeChanged();
begin
   inherited SizeChanged;
   CalculateQuad();
end;

function wdgTImageGlobal.Add(const fn: StdString; const Pos: oxTPoint; const Dim: oxTDimensions): wdgTImage;

begin
   Result := inherited AddInternal(Pos, Dim);

   if(Result <> nil) then begin
      Result.SetImage(fn);
      AddDone(Result);
   end;
end;

function wdgTImageGlobal.Add(): wdgTImage;
begin
   Result := Add('', oxNullPoint, oxNullDimensions);
end;

INITIALIZATION
   wdgImage.Create('image');

END.
