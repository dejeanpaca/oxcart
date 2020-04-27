{
   oxuiuConsoleSkin, console UI skin
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuiuConsoleSkin;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      uiuTypes, uiuSkin, uTVideo, uTVideoColors, ConsoleUtils;

VAR
   oxuiConsoleSkin: uiTSkin;

IMPLEMENTATION

{ DEFAULT SKIN }
procedure InitConsoleSkin();
var
   normal,
   dialog,
   dockable: loopint;

begin
   oxuiConsoleSkin := uiTSkin.Create();
   oxuiConsoleSkin.Name := 'console';

   {set up title and frame sizes}
   normal := ord(uiwFRAME_STYLE_NORMAL);
   dialog := ord(uiwFRAME_STYLE_DIALOG);
   dockable := ord(uiwFRAME_STYLE_DOCKABLE);

   { WINDOW }
   with oxuiConsoleSkin.Window do begin
      Frames[normal].TitleHeight   := 1;
      Frames[normal].FrameWidth    := 0;
      Frames[normal].FrameHeight   := 9;
      Frames[normal].FrameForm     := uiwFRAME_FORM_NICE;

      Frames[dialog].TitleHeight   := 1;
      Frames[dialog].FrameWidth    := 0;
      Frames[dialog].FrameHeight   := 0;
      Frames[dialog].FrameForm     := uiwFRAME_FORM_SIMPLE;

      Frames[dockable].TitleHeight := 1;
      Frames[dockable].FrameWidth  := 0;
      Frames[dockable].FrameHeight := 0;
      Frames[dockable].FrameForm   := uiwFRAME_FORM_SIMPLE;

      {window colors}
      Colors.cTitle := tvGetColor4ub(console.White, console.LightBlue);
      Colors.cTitleText := tvGetColor4ub(console.White, console.Transparent);
      Colors.cBackground := tvGetColor4ub(console.White, console.Black);
      Colors.cFrame := tvGetColor4ub(console.White, console.Transparent);
      Colors.cInnerFrame := tvGetColor4ub(console.White, console.Transparent);
      Colors.cTitleBt := tvGetColor4ub(console.White, console.Transparent);
      Colors.cTitleBtHighlight := tvGetColor4ub(console.Yellow, console.Transparent);
      Colors.Shadow := tvGetColor4ub(console.Transparent, console.Black);

      InactiveColors := Colors;

      InactiveColors.cTitle := tvGetColor4ub(console.White, console.Blue);
      InactiveColors.cTitleText := tvGetColor4ub(console.White, console.Blue);
      InactiveColors.cTitleBt:= tvGetColor4ub(console.White, console.Blue);

      {look and feel settings}
      TitleTextAlignment := uiwTITLE_ALIGNLEFT;
      ShadowSize := 1;

      {title button symbols}
      cTitleBtSymbols := uiSkin.StandardSkin.Window.cTitleBtSymbols;
   end;

   { COLORS }

   with oxuiConsoleSkin.Colors do begin
      {text colors}
      Text := tvGetColor4ub(console.White, console.Transparent);
      TextInHighlight := tvGetColor4ub(console.LightBlue, console.Transparent);
      InactiveText := tvGetColor4ub(console.LightGray, console.Transparent);

      {general colors}
      Highlight := tvGetColor4ub(console.White, console.LightBlue);
      Shadow := tvGetColor4ub(console.Black, console.Black);
      Surface := tvGetColor4ub(console.White, console.DarkGray);
      LightSurface := tvGetColor4ub(console.White, console.LightGray);
      SelectedBorder := tvGetColor4ub(console.White, console.Transparent);
      Border := tvGetColor4ub(console.White, console.Transparent);

      {input colors}
      InputSurface := tvGetColor4ub(console.White, console.Black);
      InputText := tvGetColor4ub(console.White, console.Transparent);
      InputPlaceholder := tvGetColor4ub(console.DarkGray, console.Black);
      InputCursor := tvGetColor4ub(console.White, console.Black);
   end;

   { disabled colors }
   oxuiConsoleSkin.DisabledColors := oxuiConsoleSkin.Colors;

   with oxuiConsoleSkin.DisabledColors do begin
      InputText := tvGetColor4ub(console.DarkGray, console.Transparent);
      Highlight := tvGetColor4ub(console.DarkGray, console.Black);
      TextInHighlight := tvGetColor4ub(console.DarkGray, console.Transparent);
   end;

   uiSkin.Process(oxuiConsoleSkin);
end;

procedure Initialize();
begin
   InitConsoleSkin();

   uiSkin.SetupDefaultWidget(oxuiConsoleSkin);
end;

procedure DeInitialize();
begin
   uiSkin.Dispose(oxuiConsoleSkin);
end;

INITIALIZATION
   oxui.InitializationProcs.Add('console_skin', @Initialize, @DeInitialize);

END.
