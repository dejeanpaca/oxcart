{
   uiuTypes, UI types
   Copyright (C) 2013. Dejan Boras

   Started On:    07.01.2013.
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkinTypes;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {oX}
      oxuTypes, oxuTexture, uiuTypes;

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
      Shadow: TColor4ub;
   end;

   uiTWindowSkin = record
      {dimensions and offsets}
      Frames: array[0..ord(uiwFRAME_STYLE_MAX)] of uiTWindowSkinFrame;

      FrameForm: longint;

      TitleButtonSpacing: longint;
      TitleTextOffset: array[0..2] of longint;

      {title icon}
      TitleIconOffset: array[0..1] of longint;

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

      cTitleBtSymbols: array[0..uiwcbNMAX - 1] of Char;

      BackgroundTexture: oxTTexture;
   end;

   { WIDGET SKIN }

   {widget skin color descriptor }
   uiTWidgetSkinColorDescriptor = record
      Name: string;
      Color: TColor4ub;
   end;

   uiTWidgetSkinColorDescriptors = array[0..1023] of uiTWidgetSkinColorDescriptor;
   uiPWidgetSkinColorDescriptors = ^uiTWidgetSkinColorDescriptors;

   { widget skin image descriptor }
   uiTWidgetSkinImageDescriptor = record
      Name: string;
      Default: string;
   end;

   { widget skin bool descriptor }
   uiTWidgetSkinBoolDescriptor = record
      Name: string;
      Default: Boolean;
   end;

   { widget skin string descriptor }
   uiTWidgetSkinStringDescriptor = record
      Name: string;
      Default: String;
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
      Name: string;

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
      Image: string;
   end;

   uiTWidgetSkinBool = Boolean;

   { uiTWidgetSkin }

   uiTWidgetSkin = record
      Colors: array of uiTWidgetSkinColor;
      Images: array of uiTWidgetSkinImage;
      Bools: array of uiTWidgetSkinBool;
      Strings: TStringArray;

      procedure setColor(which: longint; var clr: TColor4ub);
   end;


   { uiTSkin }
   uiPSkinColorSet = ^uiTSkinColorSet;
   uiTSkinColorSet = record
      {surfaces and highlights}
      Text,
      TextInHighlight,
      InactiveText,
      Highlight,
      Shadow,
      Surface,
      LightSurface,
      Border,
      SelectedBorder,
      InputSurface,
      InputText,
      InputPlaceholder,
      InputCursor: TColor4ub;
   end;

   uiTSkin = class
      Name: string;
      Window: uiTWindowSkin;

      {widget skins}
      wdgSkins: array of uiTWidgetSkin;

      Colors,
      DisabledColors: uiTSkinColorSet;

      function Get(cID: longint): uiPWidgetSkin;
   end;

IMPLEMENTATION

{ uiTWidgetSkinDescriptor }

function uiTWidgetSkinDescriptor.GetColor(colorIndex: loopint): TColor4ub;
begin
   if(colorIndex >= 0) and (colorIndex < nColors) then
      exit(Colors^[colorIndex].Color);

   result := cWhite4ub;
end;

{ uiTSkin }

function uiTSkin.Get(cID: longint): uiPWidgetSkin;
begin
   if(wdgSkins <> nil) and (cID >= 0) and (cID < Length(wdgSkins)) then
      result := @wdgSkins[cID]
   else
     result := nil;
end;

{ uiTWidgetSkin }

procedure uiTWidgetSkin.setColor(which: longint; var clr: TColor4ub);
begin
   if(Colors <> nil) then
      Colors[which] := clr;
end;

END.
