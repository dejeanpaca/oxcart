{
   oxuTextureGenerate, texture generation
   Copyright (c) 2016. Dejan Boras

   Started On:    07.02.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuTextureGenerate;

INTERFACE

   USES
     uStd, uLog, StringUtils, uColors, vmVector, uFile,
     uImage, imguRW, imguOperations,
     {oX}
     uOX, oxuRunRoutines, oxuRenderer, oxuRenderers, oxuTypes, oxuTexture, oxuPaths;
  
TYPE
   { oxTTextureGenerate }

   oxTTextureGenerate = record
      public

      Filter: oxTTextureFilter;
      RepeatType: oxTTextureRepeat;
      Image: imgTImage;

      {texture origin}
      Origin: longint;

      {preferred pixel format for textures without and with alpha, loaded textures are converted into this format,
      unless -1 is specified, which means no conversion}
      PreferedPIXF,
      PreferedPIXFAlpha: longint;

      {gamma correction settings}
      GammaCorrection: boolean;
      GammaFactor: single;
      {mimpam count, 0 means none, -1 is auto}
      MipCount: longint;

      {border color of the texture}
      BorderColor: TColor4f;
      {texture dimensions (for textures created procedurally)}
      Dimensions: TVector2i;

      procedure OnLoad();
      function Load(const fileName: string): longint;
      function Load(const extension: string; var f: TFile): longint;

      {specify the texture generation size, only valid for textures whose size is unknown}
      procedure SetSize(width, height: longword);

      {generates a texture after all has been set}
      function Generate(out tex: oxTTextureID): longint;
      function Generate(out tex: oxTTexture): longint;

      {loads up an texture image file and immediately generates a texture out of it.}
      function Generate(const filename: string; out Tex: oxTTextureID): longint;
      function Generate(const filename: string; out Tex: oxTTexture): longint;
      function Generate(const extension: string; var f: TFile; out tex: oxTTextureID): longint;
      function Generate(var img: imgTImage; out tex: oxTTextureID): longint;
      function Generate(var img: imgTImage; out tex: oxTTexture): longint;
      function Generate(const fn: string; var f: TFile; out tex: oxTTexture): longint;

      procedure FromGenerated(texId: oxTTextureId; out Tex: oxTTexture);

      class procedure Init(out t: oxTTextureGenerate); static;

      {dispose of generation data}
      procedure Dispose();

      private

      function checkPot(): boolean;
   end;

   oxTTextureGenerateSettings = record
      public
      {logging}
      LogNameAlways: boolean;

      {loaded texture is transformed to have this origin, which mostly depends on the renderer, -1 for unchanged}
      Origin,
      {preferred pixel format for textures without and with alpha}
      PreferedPIXF,
      PreferedPIXFAlpha: longword;

      {default filter used when generating textures}
      DefaultFilter: oxTTextureFilter;
      {default repeat type}
      DefaultRepeatType: oxTTextureRepeat;
      {default dimensions for procedurally generated textures}
      DefaultDimensions: TVector2i;

      {gamma correction settings}
      GammaCorrection: boolean;
      GammaFactor: single;
   end;

   { oxTTextureGenerateComponent }

   oxTTextureGenerateComponent = class
      public
      function Generate(var {%H-}gen: oxTTextureGenerate; var {%H-}tex: oxTTextureID): longint; virtual;
   end;


VAR
   oxTextureGenerate: oxTTextureGenerate;
   oxTextureGenerateSettings: oxTTextureGenerateSettings;

IMPLEMENTATION

VAR
   component: oxTTextureGenerateComponent;

{ oxTTextureGenerateComponent }

function oxTTextureGenerateComponent.Generate(var gen: oxTTextureGenerate; var {%H-}tex: oxTTextureID): longint;
begin
   Result := 0;
end;

{ oxTTextureGenerate }

procedure oxTTextureGenerate.OnLoad();
var
   hasAlpha: boolean;

begin
   {NOTE: Transformation is done before setting origin, as the imgSetOrigin
   routine is more likely to work on the texture with the new format.}

   {transform the texture to the preferred pixel format}
   hasAlpha := imgcPIXFHasAlpha[image.PixF];

   if(not hasAlpha) then begin
      if(PreferedPIXF <> -1) and (image.PixF <> PreferedPIXF) then
         imgOperations.Transform(image, PreferedPIXF);
   end else
      if(PreferedPIXFAlpha <> -1) and (image.PixF <> PreferedPIXFAlpha) then
         imgOperations.Transform(image, PreferedPIXFAlpha);

   {set the image to the origin we need}
   if(Origin <> -1) then
      imgOperations.SetOrigin(image, Origin);
end;

function oxTTextureGenerate.Load(const fileName: string): longint;
var
   imgProps: imgTRWProperties;
   fn: string;

procedure logFile(err: boolean);
var
   s: string;
   errCount: longint;

procedure addError(const errors: string);
begin
   if(errCount > 0) then
      s := s + ', ' + errors
   else
      s := s + errors;

   inc(errCount);
end;

begin
   s := 'texture > ';

   if(err) then begin
      errCount := 0;
      s := s + 'error(';

      if(imgProps.error.e <> 0) then
         addError('image: ' + GetErrorCodeName(imgProps.Error.e));

      if(imgProps.error.f <> 0) then
         addError('file: ' + fFile.GetErrorString(imgProps.Error.f, imgProps.Error.io));

      if(imgProps.error.description <> '') then
         addError(imgProps.error.description);

      s := s + ') ';
   end;

   s := s + 'loading: ' + fn;
   log.e(s);

   if(err) and (imgProps.error.description <> '') then
      log.w('description: ' + imgProps.error.description);
end;

begin
   {log the filename}
   if(oxTextureGenerateSettings.logNameAlways) then
      logFile(false);

   fn := oxAssetPaths.Find(fileName);

   {load the image}
   imgFile.Init(imgProps);
   imgProps.supressLog := true;
   Result := imgFile.Load(image, fn, imgProps);

   {check for errors}
   if(Result = 0) then begin
      OnLoad()
   end else begin
      if(not oxTextureGenerateSettings.logNameAlways) then
         logFile(true);

      image.Dispose();
      Result := oxeIMAGE;
   end;
end;

function oxTTextureGenerate.Load(const extension: string; var f: TFile): longint;
var
   imgProps: imgTRWProperties;

begin
   {load the image}
   imgFile.Init(imgProps);
   imgProps.supressLog := true;
   imgProps.setToDefaultOrigin := false;
   Result := imgFile.Load(image, extension, f, imgProps);

   {check for errors}
   if(Result = 0) then
      OnLoad()
   else begin
      log.e('Failed to load image: ' + image.FileName + ' (' + GetErrorCodeName(Result) + ', ' +
         GetErrorCodeName(Image.error) + ', ' + f.GetErrorString() + ')');
      image.Dispose();
      Result := oxeIMAGE;
   end;
end;

procedure oxTTextureGenerate.SetSize(width, height: longword);
begin
   {correct and assign values}
   if(width < 32) then
      width := 32;

   if(height < 32) then
      height := 32;

   Dimensions[0] := width;
   Dimensions[1] := height;
end;

function oxTTextureGenerate.Generate(out tex: oxTTextureID): longint;
var
   canPot: boolean;

begin
   tex := 0;

   canPot := checkPot();

   if(not canPot) then begin
      log.v('Texture is not pow2 (' + sf(Image.Width) + 'x' + sf(Image.Height) + '): ' + Image.FileName);

      exit(0);
   end;

   if(component <> nil) then
      Result := component.Generate(self, tex)
   else
      Result := 0;
end;

function oxTTextureGenerate.Generate(out tex: oxTTexture): longint;
var
   texId: oxTTextureID;

begin
   Result := Generate(texId);

   if(Result = 0) then
      FromGenerated(texId, tex)
   else
      tex := nil;
end;

{loads up an texture image file and immediately generates a texture out of it.}
function oxTTextureGenerate.Generate(const filename: string; out Tex: oxTTextureID): longint;
begin
   Result := Load(filename);
   if(Result <> 0) then
      exit();

   {call the texture generation routine}
   Result := Generate(Tex);
end;

function oxTTextureGenerate.Generate(const filename: string; out Tex: oxTTexture): longint;
var
   texId: oxTTextureID;

begin
   Result := Generate(filename, texId);

   if(Result = 0) then
      FromGenerated(texId, Tex)
   else
      Tex := nil;
end;

function oxTTextureGenerate.Generate(const extension: string; var f: TFile; out tex: oxTTextureID): longint;
begin
   Result := Load(extension, f);
   if(Result <> 0) then
      exit();

   {call the texture generation routine}
   Result := Generate(Tex);
end;

function oxTTextureGenerate.Generate(var img: imgTImage; out tex: oxTTextureID): longint;
var
   tempImage: imgTImage;

begin
   tempImage := Image;

   Image := img;

   {call the texture generation routine}
   Result := Generate(Tex);

   Image := tempImage;
end;

function oxTTextureGenerate.Generate(var img: imgTImage; out tex: oxTTexture): longint;
var
   tempImage: imgTImage;

begin
   tempImage := Image;

   Image := img;

   Result := Generate(tex);

   Image := tempImage;
end;

function oxTTextureGenerate.Generate(const fn: string; var f: TFile; out tex: oxTTexture): longint;
begin
   tex := nil;

   if(Load(fn, f) <> eNONE) then
      exit;

   Result := Generate(tex);
end;

procedure oxTTextureGenerate.FromGenerated(texId: oxTTextureId; out Tex: oxTTexture);
begin
   Tex := oxTex.Instance();

   Tex.rId := texId;
   Tex.Path := Image.FileName;
   Tex.Width := Image.Width;
   Tex.Height := Image.Height;

   if(Image.HasAlpha()) then
      Tex.Properties.Prop(oxTEXTURE_HAS_ALPHA);

   Tex.PixelFormat := Image.PixF;

   Tex.TextureType := oxTEXTURE_2D;
end;

class procedure oxTTextureGenerate.Init(out t: oxTTextureGenerate);
begin
   ZeroOut(t, SizeOf(t));
   t.Origin := oxTextureGenerateSettings.Origin;
   t.Filter := oxTextureGenerateSettings.DefaultFilter;
   t.RepeatType := oxTextureGenerateSettings.DefaultRepeatType;

   t.PreferedPIXF := oxTextureGenerateSettings.PreferedPIXF;
   t.PreferedPIXFAlpha := oxTextureGenerateSettings.PreferedPIXFAlpha;

   t.Dimensions := oxTextureGenerateSettings.DefaultDimensions;
   t.GammaFactor := oxTextureGenerateSettings.GammaFactor;
   t.MipCount := -1;
end;

procedure oxTTextureGenerate.Dispose();
begin
   FreeObject(image);
end;

function oxTTextureGenerate.checkPot(): boolean;
begin
   Result := oxTex.IsPot(image.Width, image.Height) or (oxRenderer.Properties.Textures.NonPowerOf2);

   {the texture is not power of 2, and such are not supported, so warn}
   if(not Result) and (not oxRenderer.Properties.Textures.WarnedPot) then begin
      log.w('Non power of 2 textures are not supported for renderer: ' + oxRenderer.Name);
      oxRenderer.Properties.Textures.WarnedPot := true;
   end;
end;

procedure onUse();
begin
   component := oxTTextureGenerateComponent(oxRenderer.GetComponent('texture.generate'));
end;

procedure Finalize();
begin
   oxTextureGenerate.Dispose();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxTextureGenerateSettings.DefaultFilter := oxTEXTURE_FILTER_TRILINEAR;
   oxTextureGenerateSettings.DefaultRepeatType := oxTEXTURE_CLAMP_TO_EDGE;
   oxTextureGenerateSettings.DefaultDimensions[0] := 64;
   oxTextureGenerateSettings.DefaultDimensions[1] := 64;

   oxTextureGenerateSettings.Origin := imgcORIGIN_BL;
   oxTextureGenerateSettings.PreferedPIXF := PIXF_RGB;
   oxTextureGenerateSettings.PreferedPIXFAlpha := PIXF_RGBA;

   oxTextureGenerateSettings.GammaFactor := 10;

   oxTTextureGenerate.Init(oxTextureGenerate);

   ox.Init.dAdd(initRoutines, 'texture.generate', @Finalize);
   oxRenderers.UseRoutines.Add(@onUse);

END.

