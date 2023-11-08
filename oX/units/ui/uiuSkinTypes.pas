{
   uiuSkinTypes, UI skin types
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkinTypes;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {oX}
      oxuTexture, uiuTypes, oxuResourcePool;

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

      TitleButtonSymbols: array[0..uiwcBUTTON_MAX] of Char;

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
   uiTWidgetSkinImageDescriptor = record
      Name: StdString;
      Default: StdString;
   end;

   { widget skin bool descriptor }
   uiTWidgetSkinBoolDescriptor = record
      Name: StdString;
      Default: Boolean;
   end;

   { widget skin string descriptor }
   uiTWidgetSkinStringDescriptor = record
      Name: StdString;
      Default: StdString;
   end;

   uiPWidgetSkinImageDescriptors = ^uiTWidgetSkinImageDescriptors;
   uiTWidgetSkinImageDescriptors = array[0..1023] of uiTWidgetSkinImageDescriptor;

   uiPWidgetSkinBoolDescriptors = ^uiTWidgetSkinBoolDescriptors;
   uiTWidgetSkinBoolDescriptors = array[0..1023] of uiTWidgetSkinBoolDescriptor;

   uiPWidgetSkinStringDescriptors = ^uiTWidgetSkinStringDescriptors;
   uiTWidgetSkinStringDescriptors = array[0..1023] of uiTWidgetSkinStringDescriptor;

   { widget skin descriptor }
   uiPWidgetSkinDescriptor = ^uiTWidgetSkinDescriptor;

   uiTWidgetSkinSetupRoutine = procedure(s: TObject; descriptor: uiPWidgetSkin);

   { uiTWidgetSkinDescriptor }

   uiTWidgetSkinDescriptor = record
      Name: StdString;

      nColors,
      nImages,
      nBools,
      nStrings: loopint;

      Colors: uiPWidgetSkinColorDescriptors;
      Images: uiPWidgetSkinImageDescriptors;
      Bools: uiPWidgetSkinBoolDescriptors;
      Strings: uiPWidgetSkinStringDescriptors;
      Setup: uiTWidgetSkinSetupRoutine;

      function GetColor(colorIndex: loopint): TColor4ub;
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

      procedure SetColor(which: longint; var clr: TColor4ub);
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

procedure uiTWidgetSkin.SetColor(which: longint; var clr: TColor4ub);
begin
   if(Colors <> nil) then
      Colors[which] := clr;
end;

END.
