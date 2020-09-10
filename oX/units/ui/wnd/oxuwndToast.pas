{
   oxuwndToast, toast message box
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuwndToast;

INTERFACE

   USES
      uStd, uImage, uColors, uTiming,
      {app}
      appuMouse,
      {oX}
      uOX, oxuTypes, oxuRunRoutines,
      oxuWindows, oxuFont, oxuPaths, oxuWindow,
      oxuTexture, oxuTextureGenerate, oxuResourcePool,
      {ui}
      uiuControl, uiuWindowTypes, uiuWindow, uiuTypes, uiuSkinTypes, uiuSkinLoader,
      uiuWidget, uiWidgets, oxuUI, uiuBase,
      oxuwndBase,
      wdguBlock, wdguLabel, wdguDivisor;

CONST
   oxcTOAST_DURATION_INDEFINITE        = 0;
   oxcTOAST_DURATION_SHORT             = 1;
   oxcTOAST_DURATION_NORMAL            = 2;
   oxcTOAST_DURATION_LONG              = 3;
   oxcTOAST_DURATION_MAX               = 3;

TYPE

   { oxuiTToastWindow }

   oxuiTToastWindow = class(oxuiTWindowBase)
      StartTime,
      Duration: longword;

      procedure Point(var e: appTMouseEvent; x, y: longint); override;

      procedure OnDeactivate(); override;

      procedure Update(); override;
   end;

   { oxTToastWindow }

   oxTToastWindow = object(oxTWindowBase)
      EdgeDistance,
      TitleSeparation: longint;

      Durations: array[0..3] of longword;

      TitleFont,
      Font: oxTFont;

      BackgroundTexture: oxTTexture;
      Color: TColor4ub;

      Status: string;

      constructor Create();
      procedure CreateWindow(); virtual;
      procedure AddWidgets(); virtual;

      {opens a toast message box window}
      procedure Show(const setTitle, setStatus: string; duration: longint);
      procedure Show(const setTitle, setStatus: string);
   end;

VAR
   oxToast: oxTToastWindow;

IMPLEMENTATION

VAR
   wdgidTITLE,
   wdgidLABEL: uiTControlID;

{ oxuiTToastWindow }

procedure oxuiTToastWindow.Point(var e: appTMouseEvent; x, y: longint);
begin
   if(e.IsReleased()) then begin
      CloseQueue();
      exit;
   end;

   inherited Point(e, x, y);
end;

procedure oxuiTToastWindow.OnDeactivate();
begin
   inherited OnDeactivate();

   CloseQueue();
end;

procedure oxuiTToastWindow.Update();
begin
   inherited Update();

   if(Duration > 0) and (timer.Cur() - StartTime > Duration) then
      CloseQueue();
end;

constructor oxTToastWindow.Create();
begin
   Width := 320;
   Height := 70;
   ID  := uiControl.GetID('toast');

   Instance := oxuiTToastWindow;

   EdgeDistance := 10;
   TitleSeparation := 10;

   Durations[0] := 0;
   Durations[1] := 2500;
   Durations[2] := 6000;
   Durations[3] := 10000;

   Color.Assign(8, 8, 8, 212);

   inherited Create;
end;

procedure oxTToastWindow.CreateWindow();
var
   x,
   y: loopint;
   parent: uiTWindow;

begin
   parent := oxWindow.Current;

   {create the window}

   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;
   Include(uiWindow.Create.Properties, uiwndpNO_ESCAPE_KEY);
   uiWindow.Create.Properties := uiWindow.Create.Properties - [uiwndpSELECTABLE, uiwndpMOVE_BY_SURFACE, uiwndpMOVABLE];

   Width := parent.Dimensions.w - 8;
   Height := 92;

   {position the window}
   x := (parent.Dimensions.w - Width) div 2;
   y := Height - 1;

   inherited CreateWindow;

   {set background, if loaded}
   if(Window <> nil) then begin
      Window.SetBackgroundColor(Color);
      Window.SetBackgroundTexture(BackgroundTexture, uiwBACKGROUND_TEX_STRETCH);

      Window.Move(oxPoint(x, y));
   end;
end;

procedure oxTToastWindow.AddWidgets();
var
   f: oxTFont = nil;
   y: loopint;
   wdg: uiTWidget;

begin
   {setup fonts}
   if(TitleFont = nil) then
      TitleFont := oxui.GetDefaultFont();

   if(Font = nil) then
      Font := oxui.GetDefaultFont();

   wdg := wdgBlock.Add(oxPoint(0, Window.Dimensions.h - 1), oxDimensions(Window.Dimensions.w, 4));
   wdgTBlock(wdg).Color := uiTSkin(Window.Skin).Window.Colors.cTitle;

   {add title if any}
   if(Title <> '') then begin
      f := titleFont;

      if(f <> nil) then begin
         wdg := wdgLabel.Add(Title, oxPoint(edgeDistance, Height - EdgeDistance),
            oxDimensions(Width - edgeDistance * 2, f.GetHeight()), true).
            SetID(wdgidTITLE).
            SetFont(TitleFont);

         wdgTLabel(wdg).IsCentered := true;
         Exclude(wdg.Properties, wdgpSELECTABLE);
      end;
   end;

   wdg := wdgDivisor.Add('', uiWidget.LastRect.BelowOf());
   wdgTDivisor(wdg).SetOverrideColor(TColor4ub.Create(32, 32, 32, 255));

   {calculate status label position}
   y := Height - EdgeDistance;

   if(Title <> '') and (f <> nil) then
      y := y - round(f.GetHeight() * 1.5) - TitleSeparation;

   {add status label}
   if(font <> nil) then begin
      wdg := wdgLabel.Add(Status,
         oxPoint(EdgeDistance, uiWidget.LastRect.BelowOf().y),
         oxDimensions(Width - EdgeDistance * 2, y), true).
         SetId(wdgidLABEL).
         SetFont(Font);

      Exclude(wdg.Properties, wdgpSELECTABLE);
   end;
end;

procedure oxTToastWindow.Show(const setTitle, setStatus: string; duration: longint);
begin
   Title := setTitle;
   Status := setStatus;

   CreateWindow();

   if(Window <> nil) then begin
      {start toast timer}
      if(duration < 0) or (duration > oxcTOAST_DURATION_MAX) then
         duration    := oxcTOAST_DURATION_NORMAL;

      oxuiTToastWindow(Window).Duration := Durations[duration];
      oxuiTToastWindow(Window).StartTime := timer.Cur();
   end;
end;

procedure oxTToastWindow.Show(const setTitle, setStatus: string);
begin
   Show(setTitle, setStatus, oxcTOAST_DURATION_NORMAL);
end;

{load toast window resources}
procedure initToast();
begin
   oxToast.Create();
end;

procedure deInitToast();
begin
   oxResource.Free(oxToast.BackgroundTexture);
   oxToast.Destroy();
end;

procedure initTexture();
begin
   uiTSkinLoader.LoadTexture(oxPaths.UI + 'textures' + DirectorySeparator + 'toast.png', oxToast.BackgroundTexture);
end;

INITIALIZATION
   wdgidLABEL := uiControl.GetID('toast.label');
   wdgidTITLE := uiControl.GetID('toast.title');

   ui.InitializationProcs.Add('toast.texture', @initTexture);
   ox.Init.Add('toast', @initToast, @deInitToast);

END.
