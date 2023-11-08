{
   uiuTypes, UI types
   Copyright (C) 2013. Dejan Boras

   Started On:    07.01.2013.
}

{$INCLUDE oxdefines.inc}
UNIT uiuTypes;

INTERFACE

   USES
      uStd, uColors, StringUtils,
      {app}
      appuEvents,
      {oX}
      oxuTypes;

TYPE
   {background type}
   uiTWindowBackgroundType = (
      uiwBACKGROUND_NONE,
      uiwBACKGROUND_SOLID,
      uiwBACKGROUND_TEX
   );

   {background texture fit}
   uiTWindowBackgroundFit = (
      uiwBACKGROUND_TEX_STRETCH,
      uiwBACKGROUND_TEX_FIT,
      uiwBACKGROUND_TEX_TILE
   );

   uiTWindowEvents = (
      uiWINDOW_EVENT_NONE,
      {event actions}
      uiWINDOW_CREATE,
      uiWINDOW_DESTROY,

      {size and position}
      uiWINDOW_RESIZE,
      uiWINDOW_MOVE,
      uiWINDOW_MINIMIZE,
      uiWINDOW_MAXIMIZE,
      uiWINDOW_TRAY,
      uiWINDOW_RESTORE,

      {state}
      uiWINDOW_ACTIVATE,
      uiWINDOW_DEACTIVATE,
      uiWINDOW_INITIALIZE,
      uiWINDOW_DEINITIALIZE,
      uiWINDOW_OPEN,
      uiWINDOW_CLOSE,
      uiWINDOW_CLOSE_ON_ESCAPE,
      uiWINDOW_SHOW,
      uiWINDOW_HIDE,

      uiWINDOW_NO_HOVER,
      uiWINDOW_HOVER,

      {commands}
      uiWINDOW_RENDER,
      uiWINDOW_RENDER_SURFACE,
      uiWINDOW_RENDER_POST
   );

   uiTMessageBoxStyle = (
      uimbsNONE,
      uimbsNOTIFICATION,
      uimbsQUESTION,
      uimbsWARNING,
      uimbsCRITICAL
   );

   uiTCursorType = (
      uiCURSOR_TYPE_DEFAULT,
      uiCURSOR_TYPE_NORMAL,
      uiCURSOR_TYPE_INPUT,
      uiCURSOR_TYPE_BUSY,
      uiCURSOR_TYPE_DENIED,
      uiCURSOR_TYPE_HAND,
      uiCURSOR_TYPE_RESIZE_LR,
      uiCURSOR_TYPE_RESIZE_TB,
      uiCURSOR_TYPE_RESIZE_TRBL,
      uiCURSOR_TYPE_RESIZE_TLBR,
      uiCURSOR_TYPE_RESIZE_TL,
      uiCURSOR_TYPE_RESIZE_TR,
      uiCURSOR_TYPE_RESIZE_BL,
      uiCURSOR_TYPE_RESIZE_BR
   );

CONST
   {maximum level of ui controls that can be nested}
   uiMAXIMUM_LEVELS              = 64;

   {window title buttons}
   uiwBUTTON_CLOSE               = 0;
   uiwBUTTON_MINIMIZE            = 1;
   uiwBUTTON_MAXIMIZE            = 2;
   uiwBUTTON_HELP                = 3;
   uiwBUTTON_TOTRAY              = 4;

   uiwcBUTTON_MAX                = 4;
   uiwcbNMAX                     = 5;

   {window title button bit-masks}
   uiwbCLOSE                     = $0001;
   uiwbMINIMIZE                  = $0002;
   uiwbMAXIMIZE                  = $0004;
   uiwbHELP                      = $0008;
   uiwbTOTRAY                    = $0010;

   { BACKGROUND }
   uiwBACKGROUND_TEX_DEFAULT     = uiwBACKGROUND_TEX_STRETCH;

   {centering of the title}
   uiwTITLE_CENTER               = 1;
   uiwTITLE_ALIGNLEFT            = 2;
   uiwTITLE_ALIGNRIGHT           = 3;

   {window frame complexity}
   uiwFRAME_FORM_SIMPLE          = 0;
   uiwFRAME_FORM_NICE            = 1;


   {message box buttons}
   uimbcNONE                  = $0000;
   uimbcOK                    = $0001;
   uimbcCANCEL                = $0002;
   uimbcYES                   = $0004;
   uimbcNO                    = $0008;
   uimbcRETRY                 = $0010;
   uimbcIGNORE                = $0020;
   uimbcABORT                 = $0040;
   uimbcNBUTTONS              = 7;

   uimbcOK_CANCEL             = uimbcOK or uimbcCANCEL;
   uimbcYES_NO                = uimbcYES or uimbcNO;
   uimbcYES_NO_CANCEL         = uimbcYES or uimbcNO or uimbcCANCEL;
   uimbcRETRY_CANCEL          = uimbcRETRY or uimbcCANCEL;
   uimbcRETRY_IGNORE_ABORT    = uimbcRETRY or uimbcIGNORE or uimbcABORT;

   {message box properties}
   uimbpSYSTEM               = $0001; {use the system message box functionality}
   uimbpCBDONTSHOWAGAIN      = $0002; {provide a 'don't show again' checkbox}
   uimbpCBDONTSHOWAGAINTRUE  = $0004; {sets the above checkbox to true by default}
   uimbpASYNC                = $0008; {run the message box asynchronously / has no effect currently}
   uimbpSURFACE              = $0020; {creates a surface covering the entire window, to prevent input to other parts of the program while the message box is shown}
   uimbpINPUT                = $0040; {message box will have an input field}
   {default properties}
   uimbpDEFAULT              = uimbpSURFACE;

   {what the user chose on the message box}
   uimbcWHAT_ELSE             = 0000;
   uimbcWHAT_BUTTON           = 0001;

   uiWIDGET_TARGET_STACK_COUNT = 8;
   uiWIDGET_TARGET_STACK_MAX = uiWIDGET_TARGET_STACK_COUNT - 1;

TYPE
   uiTHoverEvent = (
      uiHOVER_START, {the pointer started hovering over}
      uiHOVER_NO, {the pointer is no longer hovering over}
      uiHOVER {the pointer is still hovering}
   );

   {window frame styles}
   uiTWindowFrameStyle = (
      {none}
      uiwFRAME_STYLE_NONE,
      {normal window}
      uiwFRAME_STYLE_NORMAL,
      {dialog window}
      uiwFRAME_STYLE_DIALOG,
      {per window frame style}
      uiwFRAME_STYLE_DOCKABLE
   );

   uiTHorizontalJustify = (
      uiJUSTIFY_HORIZONTAL_NONE,
      uiJUSTIFY_HORIZONTAL_LEFT,
      uiJUSTIFY_HORIZONTAL_RIGHT,
      uiJUSTIFY_HORIZONTAL_CENTER
   );

   uiTVerticalJustify = (
      uiJUSTIFY_VERTICAL_NONE,
      uiJUSTIFY_VERTICAL_TOP,
      uiJUSTIFY_VERTICAL_BOTTOM,
      uiJUSTIFY_VERTICAL_CENTER
   );

CONST
   uiwFRAME_STYLE_MAX      = uiwFRAME_STYLE_DOCKABLE;
   uiwFRAME_STYLE_DEFAULT  = uiwFRAME_STYLE_NORMAL;

TYPE
   {POINTER CAPTURE TYPES}
   uiTPointerCaptureType = (
      {no pointer capture}
      uiPOINTER_CAPTURE_NONE,
      {pointer is captured by window move}
      uiPOINTER_CAPTURE_WND_OPERATIONS,
      {widget is capturing the pointer}
      uiPOINTER_CAPTURE_WIDGET,
      {window is capturing the pointer}
      uiPOINTER_CAPTURE_WINDOW
   );

   {POINTER CAPTURE TYPES}
   uiTPointerWindowOperation = (
      uiWINDOW_POINTER_NONE,
      {no pointer capture}
      uiWINDOW_POINTER_MOVE,
      {resize window top}
      uiWINDOW_POINTER_SIZE_TOP,
      {resize window on the right}
      uiWINDOW_POINTER_SIZE_RIGHT,
      {resize window bottom}
      uiWINDOW_POINTER_SIZE_BOTTOM,
      {resize window left}
      uiWINDOW_POINTER_SIZE_LEFT,
      {resize window top left}
      uiWINDOW_POINTER_SIZE_TL,
      {resize window top right}
      uiWINDOW_POINTER_SIZE_TR,
      {resize window bottom left}
      uiWINDOW_POINTER_SIZE_BL,
      {resize window bottom right}
      uiWINDOW_POINTER_SIZE_BR
   );

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
      Texture: oxTTextureID;
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

VAR
   {event handler}
   uievhWINDOW: appTEventHandler;
   uievhpWINDOW: appPEventHandler = @uievhWINDOW;

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
