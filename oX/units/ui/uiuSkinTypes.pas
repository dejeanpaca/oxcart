{
   uiuSkinTypes, UI skin types
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuSkinTypes;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {oX}
      oxuTexture, uiuTypes, oxuResourcePool, oxuGlyph;

TYPE
   { SKINS }
   uiPWidgetSkin = ^uiTWidgetSkin;

   uiTWindowSkinFrame = record
      TitleHeight,
      FrameWidth,
      FrameHeight: longint;
      FrameForm: longword;
   end;

   uiPWindowSkinColors = ^uiTWindowSkinColors;

   uiTWindowSkinColors = record
      cTitle,
      cTitleText,
      cBackground,
      cFrame,
      cInnerFrame,
      cTitleBt,
      cTitleBtHighlight,
      cTitleIcon,
      Shadow: TColor4ub;
   end;

   { uiTWindowSkin }

   uiTWindowSkin = record
      {dimensions and offsets}
      Frames: array[0..ord(uiwFRAME_STYLE_MAX)] of uiTWindowSkinFrame;

      FrameForm: loopint;

      {look and feel settings}
      TitleTextAlignment,
      ShadowSize: loopint;

      {fonts}
      TitleTextFont,
      TitleButtonsFont,
      TextFont: pointer;

      {colors}
      Colors,
      InactiveColors: uiTWindowSkinColors;

      {glyphs}
      TitleButtonSymbols: array[0..uiwcBUTTON_MAX] of Char;
      TitleButtonGlyphs: array[0..uiwcBUTTON_MAX] of oxTGlyph;

      Textures: record
         Background: oxTTexture;
      end;
   end;

   { WIDGET SKIN }

   {widget skin color descriptor }
   uiTWidgetSkinColorDescriptor = record
      Name: StdString;
      Color: TColor4ub;
   end;

   uiTWidgetSkinColorDescriptors = array[0..1023] of uiTWidgetSkinColorDescriptor;
   uiPWidgetSkinColorDescriptors = ^uiTWidgetSkinColorDescriptors;

   { widget skin image descriptor }
   uiTWidgetSkinDescriptorString = record
      Name: StdString;
      Default: StdString;
   end;

   { widget skin image descriptor }
   uiTWidgetSkinImageDescriptor = uiTWidgetSkinDescriptorString;

   { widget skin image descriptor }
   uiTWidgetSkinGlyphDescriptor = uiTWidgetSkinDescriptorString;

   { widget skin bool descriptor }
   uiTWidgetSkinBoolDescriptor = record
      Name: StdString;
      Default: Boolean;
   end;

   uiPWidgetSkinImageDescriptors = ^uiTWidgetSkinImageDescriptors;
   uiTWidgetSkinImageDescriptors = array[0..1023] of uiTWidgetSkinImageDescriptor;

   uiPWidgetSkinGlyphDescriptors = ^uiTWidgetSkinGlyphDescriptors;
   uiTWidgetSkinGlyphDescriptors = array[0..1023] of uiTWidgetSkinGlyphDescriptor;

   uiPWidgetSkinBoolDescriptors = ^uiTWidgetSkinBoolDescriptors;
   uiTWidgetSkinBoolDescriptors = array[0..1023] of uiTWidgetSkinBoolDescriptor;

   uiPWidgetSkinStringDescriptors = ^uiTWidgetSkinStringDescriptors;
   uiTWidgetSkinStringDescriptors = array[0..1023] of uiTWidgetSkinDescriptorString;

   { widget skin descriptor }
   uiPWidgetSkinDescriptor = ^uiTWidgetSkinDescriptor;

   { called when widget skin is being setup }
   uiTWidgetSkinSetupRoutine = procedure(skin: TObject; descriptor: uiPWidgetSkin);

   { called when widget skin is loaded }
   uiTWidgetSkinOnLoad = procedure (skin: TObject; descriptor: uiPWidgetSkin);

   { uiTWidgetSkinDescriptor }

   uiTWidgetSkinDescriptor = record
      Name: StdString;

      nColors,
      nImages,
      nGlyphs,
      nBools,
      nStrings: loopint;

      Colors: uiPWidgetSkinColorDescriptors;
      Images: uiPWidgetSkinImageDescriptors;
      Glyphs: uiPWidgetSkinGlyphDescriptors;
      Bools: uiPWidgetSkinBoolDescriptors;
      Strings: uiPWidgetSkinStringDescriptors;
      Setup: uiTWidgetSkinSetupRoutine;

      {called when this widget skin is loaded}
      OnLoad: uiTWidgetSkinOnLoad;

      function GetColor(colorIndex: loopint): TColor4ub;

      procedure UseColors(var colorDescriptor: array of uiTWidgetSkinColorDescriptor);
      procedure UseImages(var imageDescriptor: array of uiTWidgetSkinImageDescriptor);
      procedure UseGlyphs(var glyphDescriptor: array of uiTWidgetSkinGlyphDescriptor);
      procedure UseStrings(var stringDescriptor: array of uiTWidgetSkinDescriptorString);
      procedure UseBools(var boolDescriptor: array of uiTWidgetSkinBoolDescriptor);

      class procedure Initialize(out descriptor: uiTWidgetSkinDescriptor; const setName: StdString = ''); static;
   end;

   { widget skin color }
   uiTWidgetSkinColor = TColor4ub;

   { widget skin image }
   uiTWidgetSkinImage = record
      Texture: oxTTexture;
      Image: StdString;
   end;

   uiTWidgetSkinBool = Boolean;

   { uiTWidgetSkin }

   uiTWidgetSkin = record
      Colors: array of uiTWidgetSkinColor;
      Images: array of uiTWidgetSkinImage;
      Bools: array of uiTWidgetSkinBool;
      Strings: TStringArray;
      Glyphs: array of oxTGlyph;
      GlyphStrings: array of String;

      procedure SetColor(which: loopint; var clr: TColor4ub);
      function GetColor(which: loopint): TColor4ub;
   end;


   { uiTSkin }
   uiPSkinColorSet = ^uiTSkinColorSet;
   uiTSkinColorSet = record
      {surfaces and highlights}
      Text,
      TextInHighlight,
      InactiveText,
      Highlight,
      Focal,
      Shadow,
      Surface,
      LightSurface,
      Border,
      SelectedBorder,
      InputSurface,
      InputText,
      InputPlaceholder,
      InputCursor,
      Delete: TColor4ub;
   end;

   uiTSkin = class
      Name: StdString;
      Window: uiTWindowSkin;
      {path for this skins resources}
      ResourcePath: StdString;

      {widget skins}
      wdgSkins: array of uiTWidgetSkin;

      Colors,
      DisabledColors: uiTSkinColorSet;

      {glyphs}
      ChevronRight: oxTGlyph;

      destructor Destroy(); override;

      function Get(cID: longint): uiPWidgetSkin;
   end;

IMPLEMENTATION

{ uiTWidgetSkinDescriptor }

function uiTWidgetSkinDescriptor.GetColor(colorIndex: loopint): TColor4ub;
begin
   if(colorIndex >= 0) and (colorIndex < nColors) then
      exit(Colors^[colorIndex].Color);

   Result := cWhite4ub;
end;

procedure uiTWidgetSkinDescriptor.UseColors(var colorDescriptor: array of uiTWidgetSkinColorDescriptor);
begin
   nColors := Length(colorDescriptor);
   Colors := @colorDescriptor[0];
end;

procedure uiTWidgetSkinDescriptor.UseImages(var imageDescriptor: array of uiTWidgetSkinImageDescriptor);
begin
   nImages := Length(imageDescriptor);
   Images := @imageDescriptor[0];
end;

procedure uiTWidgetSkinDescriptor.UseGlyphs(var glyphDescriptor: array of uiTWidgetSkinGlyphDescriptor);
begin
   nGlyphs := Length(glyphDescriptor);
   Glyphs := @glyphDescriptor[0];
end;

procedure uiTWidgetSkinDescriptor.UseStrings(var stringDescriptor: array of uiTWidgetSkinDescriptorString);
begin
   nStrings := Length(stringDescriptor);
   Strings := @stringDescriptor[0];
end;

procedure uiTWidgetSkinDescriptor.UseBools(
   var boolDescriptor: array of uiTWidgetSkinBoolDescriptor);
begin
   nBools := Length(boolDescriptor);
   Bools := @boolDescriptor[0];
end;

class procedure uiTWidgetSkinDescriptor.Initialize(out descriptor: uiTWidgetSkinDescriptor; const setName: StdString);
begin
   ZeroOut(descriptor, SizeOf(descriptor));
   descriptor.Name := setName;
end;

{ uiTSkin }

destructor uiTSkin.Destroy();
begin
   inherited Destroy;

   oxResource.Free(Window.Textures.Background);
end;

function uiTSkin.Get(cID: longint): uiPWidgetSkin;
begin
   if(wdgSkins <> nil) and (cID >= 0) and (cID < Length(wdgSkins)) then
      Result := @wdgSkins[cID]
   else
      Result := nil;
end;

{ uiTWidgetSkin }

procedure uiTWidgetSkin.SetColor(which: loopint; var clr: TColor4ub);
begin
   if(Colors <> nil) then
      Colors[which] := clr;
end;

function uiTWidgetSkin.GetColor(which: loopint): TColor4ub;
begin
   if(Colors <> nil) then
      Result := Colors[which]
   else
      Result := cWhite4ub;
end;

END.
