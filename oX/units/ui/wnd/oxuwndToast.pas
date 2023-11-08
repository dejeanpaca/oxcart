{
   oxuwndToast, toast message box
   Copyright (C) 2011. Dejan Boras

   Started On:    21.04.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndToast;

INTERFACE

   USES
      uStd, uImage, uColors, uTiming,
      {oX}
      uOX, oxuTypes, oxuWindows, oxuProjection, oxuFont, oxuPaths, oxuWindow,
      oxuTexture, oxuTextureGenerate,
      {ui}
      uiuControl, uiuWindowTypes, uiuWindow, uiuTypes, uiuWidget, uiWidgets, wdguLabel, oxuwndBase;

CONST
   oxcTOAST_DURATION_INDEFINITE        = 0;
   oxcTOAST_DURATION_SHORT             = 1;
   oxcTOAST_DURATION_NORMAL            = 2;
   oxcTOAST_DURATION_LONG              = 3;
   oxcTOAST_DURATION_MAX               = 3;

TYPE

   { oxTToastWindow }

   oxTToastWindow = class(oxTWindowBase)
      EdgeDistance,
      TitleSeparation: longint;

      Durations: array[0..3] of longword;

      TitleFont,
      Font: oxTFont;

      BackgroundTexture: oxTTexture;
      Color: TColor4ub;

      Status: string;

      constructor Create; override;
      procedure CreateWindow; override;
      procedure AddWidgets; override;

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

   toastStartTime,
   toastDuration: longword;

constructor oxTToastWindow.Create;
begin
   Width := 320;
   Height := 70;
   ID  := uiControl.GetID('toast');

   EdgeDistance := 10;
   TitleSeparation := 10;

   Durations[0] := 0;
   Durations[1] := 2500;
   Durations[2] := 6000;
   Durations[3] := 10000;

   Color.Assign(0, 0, 0, 255);

   inherited Create;
end;

procedure oxTToastWindow.CreateWindow;
var
   x,
   y: loopint;

begin
   {create the window}
   uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;
   Include(uiWindow.Create.Properties, uiwndpNO_ESCAPE_KEY);
   uiWindow.Create.Properties := uiWindow.Create.Properties - [uiwndpSELECTABLE, uiwndpMOVE_BY_SURFACE, uiwndpMOVABLE];

   {position the window}
   x := (oxProjection.Dimensions.w - Width) div 2;
   y := round(Height * 1.5);

   inherited CreateWindow;

   {set background, if loaded}
   if(Window <> nil) then begin
      Window.SetBackgroundColor(Color);
      Window.SetBackgroundTexture(BackgroundTexture, uiwBACKGROUND_TEX_STRETCH);

      Window.Move(oxPoint(x, y));
   end;
end;

procedure oxTToastWindow.AddWidgets;
var
   hasTitle: boolean = false;
   f: oxTFont = nil;
   y: loopint;
   labelWidget: wdgTLabel;
   wdg: uiTWidget;

begin
   {setup fonts}
   oxf.GetNilDefault(TitleFont);
   oxf.GetNilDefault(Font);

   if(title <> '') then
      hasTitle := true;

   {add title if any}
   if(hasTitle) then begin
      f := titleFont;

      if(f <> nil) then begin
         labelWidget := wdgTLabel(wdgLabel.Add(title, oxPoint(edgeDistance, Height - EdgeDistance),
            oxDimensions(Width - edgeDistance * 2, f.GetHeight()), true).
            SetID(wdgidTITLE).
            SetFont(f));

         labelWidget.IsCentered := true;
      end;
   end;

   {calculate status label position}
   y := Height - EdgeDistance;

   if(hasTitle) and (f <> nil) then
      y := y - round(f.GetHeight() * 1.5) - TitleSeparation;

   {add status label}
   if(font <> nil) then begin
      wdg := wdgLabel.Add(Status,
         oxPoint(EdgeDistance, y), oxDimensions(Width - EdgeDistance * 2, y), true).
         SetId(wdgidLABEL).
         SetFont(font);

      Exclude(wdg.Properties, wdgpSELECTABLE);
   end;

   uiWidget.ClearTarget();
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

      toastDuration  := Durations[duration];
      toastStartTime := timer.Cur();
   end;
end;

procedure oxTToastWindow.Show(const setTitle, setStatus: string);
begin
   Show(setTitle, setStatus, oxcTOAST_DURATION_NORMAL);
end;

{load toast window resources}
procedure initToast();
begin
   oxToast := oxTToastWindow.Create();

   oxTextureGenerate.Generate(oxPaths.UITextures + 'toast.png', oxToast.BackgroundTexture);
end;

procedure deInitToast();
begin
   FreeObject(oxToast.BackgroundTexture);
   FreeObject(oxToast);
end;

{controls the toast window}
procedure toastControl();
begin
   if(toastDuration > 0) and (timer.Cur() - toastStartTime > toastDuration) then
      oxToast.Close();
end;

INITIALIZATION
   wdgidLABEL     := uiControl.GetID('toast.label');
   wdgidTITLE     := uiControl.GetID('toast.label');

   ox.OnRun.Add(@toastControl);
   ox.Init.Add('toast', @initToast, @deInitToast);
END.
