{
   wdguImage, image widget
   Copyright (C) 2016. Dejan Boras

   Started On:    02.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT wdguImage;

INTERFACE

   USES
      vmVector, uFile, uLog,
      {oX}
      oxuTypes, oxuRender, oxuTransform, oxuTexture, oxuTextureGenerate, oxumPrimitive,
      oxuResourcePool, oxuUI,
      {ui}
      uiuWidget, uiWidgets, uiuDraw, uiuWindow;

TYPE

   { wdgTImageTexture }

   wdgTImageTexture = record
      {texture file name used for the image}
      FileName: String;
      {texture used for the image}
      Texture: oxTTexture;

      {set and load a file for the image}
      function SetImage(const fn: string): boolean;
      {set an existing texture as the image}
      function SetImage(newTexture: oxTTexture): boolean;

      function Has(): boolean;
   end;

   { wdgTImage }

   wdgTImage = class(uiTWidget)
     public
        Texture: wdgTImageTexture;

   public
      constructor Create(); override;

      {set and load a file for the image}
      procedure SetImage(const fn: string);
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

   { uiTWidgetImageGlobal }

   uiTWidgetImageGlobal = record
      {adds a image to a window}
      function Add(const fn: string;
            const Pos: oxTPoint; const Dim: oxTDimensions): wdgTImage;
   end;

VAR
   wdgImage: uiTWidgetImageGlobal;

IMPLEMENTATION

VAR
   internal: uiTWidgetClass;

{ wdgTImageTexture }

function wdgTImageTexture.SetImage(const fn: string): boolean;
begin
   Result := false;
   oxResource.Destroy(Texture);
   FileName := fn;
   Texture := nil;

   oxTextureGenerate.Generate(fn, Texture);

   if(Texture <> nil) then begin
      Texture.MarkUsed();
      Result := true;
   end;
end;

function wdgTImageTexture.SetImage(newTexture: oxTTexture): boolean;
begin
   Result := false;
   oxResource.Destroy(Texture);
   FileName := '';
   Texture := newTexture;

   if(Texture <> nil) then begin
      Texture.MarkUsed();
      Result := true;
   end;
end;

function wdgTImageTexture.Has(): boolean;
begin
   Result := (Texture <> nil) and (Texture.rId <> 0);
end;

constructor wdgTImage.Create();
begin
   inherited;

   oxmPrimitive.Init(Quad);
end;

procedure wdgTImage.SetImage(const fn: string);
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
      Quad.Render();
      oxui.Material.ApplyTexture('texture', nil);
   end else
      uiDraw.Box(0, 0, Dimensions.w - 1, -(Dimensions.h - 1));

   oxTransform.Apply(m);
end;

procedure wdgTImage.DeInitialize();
begin
   inherited DeInitialize();

   oxResource.Destroy(Texture.Texture);
end;

procedure wdgTImage.CalculateQuad();
begin
   if(Texture.Has()) then begin
      Quad.Quad();
      Quad.Scale(round(Dimensions.w / 2), round(Dimensions.h / 2), 0);
      Quad.Offset(round(Dimensions.w / 2), -round(Dimensions.h / 2), 0);
   end;
end;

procedure wdgTImage.SizeChanged();
begin
   inherited SizeChanged;
   CalculateQuad();
end;

procedure InitWidget();
begin
   internal.Instance := wdgTImage;
   internal.Done();
end;

function uiTWidgetImageGlobal.Add(const fn: string;
      const Pos: oxTPoint; const Dim: oxTDimensions): wdgTImage;

begin
   Result := wdgTImage(uiWidget.Add(internal, Pos, Dim));

   if(Result <> nil) then
      Result.SetImage(fn);
end;

INITIALIZATION
   internal.Register('widget.image', @InitWidget);

END.
