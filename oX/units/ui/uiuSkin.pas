{
   uiuSkin, UI skin management
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkin;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuRunRoutines,
      {ui}
      oxuUI, uiuTypes, uiuWindowTypes;

CONST
   {window rendering constants}
   uicsrALL                         = $01;
   uicsrWINDOW_FRAME                = $02;
   uicsrTITLE_TEXT                  = $03;
   uicsrTITLE_BUTTONS               = $04;
   uicsrTITLE_ICON                  = $05;
   uicsrBACKGROUND                  = $06;

TYPE
   uiTSkinGlobal = record
     { GENERAL }

     { SKINS }
     {set a skin to the window}
     procedure SetWindow(var wnd: uiTWindow; cSkin: longint);
     {set the default skin to the window}
     procedure SetWindowDefault(var wnd: uiTWindow);
     {processes a skin}
     procedure Process(skin: uiTSkin);
     {set the default skin for an interface}
     procedure SetDefault(skin: uiTSkin);
     {sets up a widget skin from a descriptor}
     procedure SetupWidget(s: uiTSkin; var skin: uiTWidgetSkin; var descriptor: uiTWidgetSkinDescriptor);
     {setups default widget skins}
     procedure SetupDefaultWidget(skin: uiTSkin);

     {dispose a widget skin}
     procedure DisposeWidget(var skin: uiTWidgetSkin);
     {dispose a skin}
     procedure Dispose(var s: uiTSkin);

     {disposes all skins from a renderer}
     procedure Dispose();
   end;

VAR
   uiSkin: uiTSkinGlobal;

IMPLEMENTATION

{ SKINS }
procedure uiTSkinGlobal.SetWindow(var wnd: uiTWindow; cSkin: longint);
begin
   if(cSkin = 0) then
      wnd.Skin := oxui.DefaultSkin
   else begin
      dec(cSkin);

      if(cSkin < oxui.nSkins) then
         wnd.Skin := oxui.Skins[cSkin];
   end;
end;

procedure uiTSkinGlobal.SetWindowDefault(var wnd: uiTWindow);
begin
   SetWindow(wnd, 0);
end;

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
   for i := 0 to (oxui.nSkins - 1) do begin
      if(oxui.Skins[i] <> nil) then
         FreeObject(oxui.Skins[i]);

      SetLength(oxui.Skins, 0);
      oxui.Skins := nil;
      oxui.nSkins := 0;
   end;
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

procedure uiTSkinGlobal.SetDefault(Skin: uiTSkin);
begin
   oxui.DefaultSkin := Skin;
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

procedure uiTSkinGlobal.SetupDefaultWidget(skin: uiTSkin);
begin
   try
      if(oxui.nWidgetTypes > 0) then begin
         SetLength(skin.wdgSkins, oxui.nWidgetTypes);
         ZeroOut(skin.wdgSkins[0], int64(SizeOf(uiTWidgetSkin)) * int64(oxui.nWidgetTypes));
      end;
   except
      exit;
   end;
end;

{ DEFAULT SKIN }
procedure InitStandardSkin();
var
   normal,
   dialog,
   dockable: loopint;

begin
   oxui.StandardSkin := uiTSkin.Create();
   oxui.StandardSkin.Name := 'standard';

   {set up title and frame sizes}
   normal := ord(uiwFRAME_STYLE_NORMAL);
   dialog := ord(uiwFRAME_STYLE_DIALOG);
   dockable := ord(uiwFRAME_STYLE_DOCKABLE);

   { WINDOW }
   with oxui.StandardSkin.Window do begin
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
      Colors.cBackground.Assign(42, 42, 42, 244);
      Colors.cFrame := Colors.cTitle;
      Colors.cInnerFrame.Assign(16, 16, 16, 255);
      Colors.cTitleBt.Assign(255, 255, 255, 255); {close}
      Colors.cTitleBtHighlight.Assign(255, 0, 0, 255); {close}
      Colors.Shadow.Assign(0, 0, 0, 63);

      InactiveColors := Colors;

      InactiveColors.cTitle := Colors.cTitle.Darken(0.2);
      InactiveColors.cTitleText.Assign(127, 127, 127, 255);
      InactiveColors.cFrame := InactiveColors.cTitle;
      InactiveColors.cInnerFrame.Assign(0, 0, 0, 255);
      InactiveColors.cTitleBt.Assign(64, 64, 64, 255);

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

   with oxui.StandardSkin.Colors do begin
      {text colors}
      Text.Assign(255, 255, 255, 255);
      TextInHighlight.Assign(255, 255, 255, 255);
      InactiveText.Assign(127, 127, 127, 255);

      {general colors}
      Highlight.Assign(127, 127, 255, 255);
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
   oxui.StandardSkin.DisabledColors := oxui.StandardSkin.Colors;

   with oxui.StandardSkin.DisabledColors do begin
      InputText.Assign(192, 192, 192, 255);
      Highlight.Assign(224, 224, 224, 255);
      TextInHighlight.Assign(192, 192, 192, 255);
      Text.Assign(160, 160, 160, 255);
   end;

   uiSkin.Process(oxui.StandardSkin);

   oxui.DefaultSkin := oxui.StandardSkin;
end;

procedure Initialize();
begin
   InitStandardSkin();

   uiSkin.SetupDefaultWidget(oxui.DefaultSkin);
end;

procedure DeInitialize();
begin
   uiSkin.Dispose(oxui.StandardSkin);
   oxui.DefaultSkin := nil;
   uiSkin.Dispose();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxui.BaseInitializationProcs.Add(initRoutines, 'skin', @Initialize, @DeInitialize);

END.

