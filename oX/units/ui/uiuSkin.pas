{
   uiuSkin, UI skin management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkin;

INTERFACE

   USES
      uStd, uColors, uLog,
      {oX}
      oxuRunRoutines, oxuPlatform,
      {ui}
      uiuTypes, uiuSkinTypes,
      uiuBase, uiuPlatform;

CONST
   {window rendering constants}
   uicsrALL                         = $01;
   uicsrWINDOW_FRAME                = $02;
   uicsrTITLE_TEXT                  = $03;
   uicsrTITLE_BUTTONS               = $04;
   uicsrTITLE_ICON                  = $05;
   uicsrBACKGROUND                  = $06;

TYPE
   uiTSkinProcedure = procedure(skin: uiTSkin);

   { uiTSkinGlobal }

   uiTSkinGlobal = record
     Loader: uiTSkinProcedure;

     { GENERAL }

     { skins }
     nSkins: longint;
     Skins: array of uiTSkin;

     {standard internal skin}
     StandardSkin: uiTSkin;

     { SKINS }
     {processes a skin}
     procedure Process(skin: uiTSkin);
     {sets up a widget skin from a descriptor}
     procedure SetupWidget(s: uiTSkin; var skin: uiTWidgetSkin; var descriptor: uiTWidgetSkinDescriptor);

     {dispose a widget skin}
     procedure DisposeWidget(var skin: uiTWidgetSkin);
     {dispose a skin}
     procedure Dispose(var s: uiTSkin);

     {disposes all skins from a renderer}
     procedure Dispose();

     {load a skin via the hooked loader}
     procedure Load(skin: uiTSkin);
   end;

VAR
   uiSkin: uiTSkinGlobal;

IMPLEMENTATION

{ SKINS }
procedure uiTSkinGlobal.DisposeWidget(var skin: uiTWidgetSkin);
begin
   SetLength(skin.Colors, 0);
   SetLength(skin.Images, 0);
   SetLength(skin.Bools, 0);
   SetLength(skin.Strings, 0);
end;

procedure uiTSkinGlobal.Dispose(var s: uiTSkin);
var
   i: longint;

begin
   if(s <> nil) then begin
      for i := 0 to Length(s.wdgSkins) - 1 do
         DisposeWidget(s.wdgSkins[i]);

      FreeObject(s);
   end;
end;

procedure uiTSkinGlobal.Dispose();
var
   i: longint;

begin
   for i := 0 to (nSkins - 1) do begin
      if(Skins[i] <> nil) then
         FreeObject(Skins[i]);

      SetLength(Skins, 0);
      Skins := nil;
      nSkins := 0;
   end;
end;

procedure uiTSkinGlobal.Load(skin: uiTSkin);
begin
   if(skin <> nil) and (Loader <> nil) then
      Loader(skin);
end;

procedure uiTSkinGlobal.Process(skin: uiTSkin);
var
   none: loopint;

begin
   none := ord(uiwFRAME_STYLE_NONE);

   {setup the NONE frame style}
   skin.Window.Frames[none].TitleHeight   := 0;
   skin.Window.Frames[none].FrameWidth    := 0;
   skin.Window.Frames[none].FrameHeight   := 0;
end;

procedure uiTSkinGlobal.SetupWidget(s: uiTSkin; var skin: uiTWidgetSkin; var descriptor: uiTWidgetSkinDescriptor);
var
   i: longint;

begin
   if(descriptor.nColors > 0) and (descriptor.Colors <> nil) then begin
      {set size for colors array, and copy from default colors}
      SetLength(skin.Colors, descriptor.nColors);

      for i := 0 to (descriptor.nColors - 1) do
         skin.Colors[i] := descriptor.Colors^[i].Color;
   end;

   if(descriptor.nImages > 0) and (descriptor.Images <> nil) then begin
      {set size for images array, and copy from default image names}
      SetLength(skin.Images, descriptor.nImages);

      for i := 0 to descriptor.nImages - 1 do
         skin.Images[i].Image := descriptor.Images^[i].Default;
   end;

   if(descriptor.nBools > 0) and (descriptor.Bools <> nil) then begin
      {set size for bools array, and copy from default bools}
      SetLength(skin.Bools, descriptor.nBools);

      for i := 0 to descriptor.nBools - 1 do
         skin.Bools[i] := descriptor.Bools^[i].Default;
   end;

   if(descriptor.nStrings > 0) and (descriptor.Strings <> nil) then begin
      {set size for bools array, and copy from default bools}
      SetLength(skin.Strings, descriptor.nStrings);

      for i := 0 to descriptor.nStrings - 1 do
         skin.Strings[i] := descriptor.Strings^[i].Default;
   end;

   if(descriptor.Setup <> nil) then
      descriptor.Setup(TObject(s), @skin);
end;

{ DEFAULT SKIN }
procedure InitStandardSkin();
var
   normal,
   dialog,
   dockable: loopint;

begin
   uiSkin.StandardSkin := uiTSkin.Create();
   uiSkin.StandardSkin.Name := 'standard';

   {set up title and frame sizes}
   normal := ord(uiwFRAME_STYLE_NORMAL);
   dialog := ord(uiwFRAME_STYLE_DIALOG);
   dockable := ord(uiwFRAME_STYLE_DOCKABLE);

   { WINDOW }
   with uiSkin.StandardSkin.Window do begin
      Frames[normal].TitleHeight   := 22;
      Frames[normal].FrameWidth    := 4;
      Frames[normal].FrameHeight   := 4;
      Frames[normal].FrameForm     := uiwFRAME_FORM_NICE;

      Frames[dialog].TitleHeight   := 18;
      Frames[dialog].FrameWidth    := 1;
      Frames[dialog].FrameHeight   := 1;
      Frames[dialog].FrameForm     := uiwFRAME_FORM_SIMPLE;

      Frames[dockable].TitleHeight := 18;
      Frames[dockable].FrameWidth  := 1;
      Frames[dockable].FrameHeight := 1;
      Frames[dockable].FrameForm   := uiwFRAME_FORM_SIMPLE;

      TitleButtonSpacing := 1;

      {window colors}
      Colors.cTitle.Assign(84, 122, 201, 255);
      Colors.cTitleText  := cWhite4ub;
      Colors.cBackground.Assign(42, 42, 42, 248);
      Colors.cFrame := Colors.cTitle;
      Colors.cInnerFrame.Assign(16, 16, 16, 255);
      Colors.cTitleBt.Assign(255, 255, 255, 255); {close}
      Colors.cTitleBtHighlight.Assign(255, 0, 0, 255); {close}
      Colors.cTitleIcon.Assign(255, 255, 255, 255); {close}
      Colors.Shadow.Assign(0, 0, 0, 63);

      InactiveColors := Colors;

      InactiveColors.cTitle.Assign(72, 72, 72, 255);
      InactiveColors.cTitleText.Assign(127, 127, 127, 255);
      InactiveColors.cFrame := InactiveColors.cTitle;
      InactiveColors.cInnerFrame.Assign(0, 0, 0, 255);
      InactiveColors.cTitleBt.Assign(127, 127, 127, 255);

      {set up title text offset}
      TitleTextOffset[0] := 5;
      TitleTextOffset[1] := 3;
      TitleTextOffset[2] := 5;

      {look and feel settings}
      TitleTextAlignment := uiwTITLE_ALIGNLEFT;
      ShadowSize := 2;

      {title button symbols}
      cTitleBtSymbols[0] := 'X';
      cTitleBtSymbols[1] := '_';
      cTitleBtSymbols[2] := '^';
      cTitleBtSymbols[3] := '?';
      cTitleBtSymbols[4] := '>';
   end;


   { COLORS }

   with uiSkin.StandardSkin.Colors do begin
      {text colors}
      Text.Assign(255, 255, 255, 255);
      TextInHighlight.Assign(255, 255, 255, 255);
      InactiveText.Assign(127, 127, 127, 255);

      {general colors}
      Highlight.Assign(127, 127, 255, 255);
      Focal.Assign(96, 96, 112, 255);
      Shadow := cBlack4ub;
      Surface.Assign(48, 48, 48, 255);
      LightSurface.Assign(80, 80, 80, 255);
      SelectedBorder.Assign(63, 127, 255, 255);
      Border.Assign(16, 16, 16, 255);

      {input colors}
      InputSurface.Assign(232, 232, 232, 255);
      InputText := cBlack4ub;
      InputPlaceholder.Assign(140, 140, 140, 255);
      InputCursor := cBlack4ub;
   end;

   { disabled colors }
   uiSkin.StandardSkin.DisabledColors := uiSkin.StandardSkin.Colors;

   with uiSkin.StandardSkin.DisabledColors do begin
      InputText.Assign(32, 32, 32, 255);
      InputSurface.Assign(192, 192, 192, 255);
      InputPlaceholder.Assign(160, 160, 160, 255);
      Highlight.Assign(224, 224, 224, 255);
      TextInHighlight.Assign(192, 192, 192, 255);
      Text.Assign(160, 160, 160, 255);
   end;

   uiSkin.Process(uiSkin.StandardSkin);
end;

procedure Initialize();
var
   platform: uiTPlatformComponent;

begin
   platform := uiTPlatformComponent(oxPlatform.GetComponent('ui.platform'));

   if(platform <> nil) then
      log.v('System theme: ' + platform.GetSystemTheme());

   InitStandardSkin();
end;

procedure DeInitialize();
begin
   uiSkin.Dispose(uiSkin.StandardSkin);
   uiSkin.Dispose();
end;

procedure skinLoad();
begin
   uiSkin.Load(uiSkin.StandardSkin);
end;


INITIALIZATION
   ui.BaseInitializationProcs.Add('skin', @Initialize, @DeInitialize);
   ui.InitializationProcs.Add('skin.load', @skinLoad);

END.

