{
   oxuwndColorPicker, color picker window
   Copyright (C) 2018. Dejan Boras

   Started On:    07.02.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndColorPicker;

INTERFACE

   USES
      sysutils, uStd, uColors, StringUtils,
      {oX}
      uOX, oxuTypes, oxuRunRoutines, oxuWindows,
      {ui}
      uiuControl, uiuWindow, uiWidgets, uiuWidget,
      {widgets}
      wdguLabel, wdguInputBox, wdguButton, wdguDivisor, wdguBlock, oxuwndBase;

CONST
   {default dimensions}
   oxwndCOLOR_PICKER_WIDTH              = 480;
   oxwndCOLOR_PICKER_HEIGHT             = 240;

TYPE
   { oxuiTColorPickerWindow }

   oxuiTColorPickerWindow = class(oxuiTWindowBase)
      Dialog: TObject;
   end;

   { oxwndTColorPickerDialog }

   oxwndTColorPickerDialog = class(oxTWindowBase)
      HasAlpha: boolean;
      SelectedColor: TColor4ub;
      DefaultButtonWidth: loopint;

      {has the dialog canceled}
      Canceled,
      {have we called done yet}
      DoneCalled,
      {can be set by the callback to prevent closing after call}
      PreventClose: boolean;

      Callback: procedure(dialog: oxwndTColorPickerDialog);
      ObjectCallback: procedure(dialog: oxwndTColorPickerDialog) of object;

      wdg: record
         Ok,
         Cancel,
         Pick: wdgTButton;
         Color: wdgTBlock;
         ibHexColor,
         ibR,
         ibG,
         ibB,
         ibA: wdgTInputBox;
         Preset: array[0..1, 0..9] of wdgTBlock;
      end;

      constructor Create(); override;

      procedure Open(); override;

      procedure AddWidgets(); override;

      {called when the dialog is finished}
      procedure Done(isCanceled: boolean);
      {called when ok is clicked}
      procedure CallOk();
      {pick a color}
      procedure Pick();

      {get the selected color as 3 component}
      function GetSelectedColor3(): TColor3ub;

      procedure SetupHexColor();
      procedure UpdateColor();
   end;

VAR
   oxwndColorPicker: oxwndTColorPickerDialog;

IMPLEMENTATION

VAR
   wdgidR,
   wdgidG,
   wdgidB,
   wdgidA: uiTControlID;

function colorValueControl(wdg: uiTWidget; what: longword): longint;
begin
   result := -1;

   if((wdg = wdgidR) or (wdg = wdgidG) or (wdg = wdgidB) or (wdg = wdgidA)) and (what = wdghINPUTBOX_CHANGED) then begin
      oxwndTColorPickerDialog(oxuiTColorPickerWindow(wdg.wnd).BaseHandler).UpdateColor();
   end;
end;

{ CLASS }

procedure oxwndTColorPickerDialog.Done(isCanceled: boolean);
begin
   if(not DoneCalled) then begin
      DoneCalled := true;
      Canceled := isCanceled;

      if(Callback <> nil) then
         Callback(Self);

      if(ObjectCallback <> nil) then
         ObjectCallback(Self);

      if(not PreventClose) then
         Close()
      else
         DoneCalled := false;

      PreventClose := false;
   end;

   Callback := nil;
   ObjectCallback := nil;
end;

procedure oxwndTColorPickerDialog.CallOk();
begin
   Done(false);
end;

procedure oxwndTColorPickerDialog.Pick();
begin

end;

function oxwndTColorPickerDialog.GetSelectedColor3(): TColor3ub;
begin
   Result := TColor3ub((@SelectedColor)^);
end;

procedure oxwndTColorPickerDialog.SetupHexColor();
begin
   if(wdg.ibHexColor <> nil) then begin
      if(HasAlpha) then
         wdg.ibHexColor.SetText(SelectedColor.ToHex())
      else
         wdg.ibHexColor.SetText(SelectedColor.ToHex3());
   end;
end;

procedure oxwndTColorPickerDialog.UpdateColor();
begin
   byte.TryParse(wdg.ibR.GetText(), SelectedColor[0]);
   byte.TryParse(wdg.ibG.GetText(), SelectedColor[1]);
   byte.TryParse(wdg.ibB.GetText(), SelectedColor[2]);

   if(HasAlpha) then
      byte.TryParse(wdg.ibA.GetText(), SelectedColor[3])
   else
      SelectedColor[3] := 255;

   wdg.Color.Color := SelectedColor;

   SetupHexColor();
end;

constructor oxwndTColorPickerDialog.Create();
begin
   Width := wdgDEFAULT_SPACING;
   Height := wdgDEFAULT_SPACING;
   HasAlpha := true;
   SelectedColor := cWhite4ub;

   Title := 'Color picker';
   Instance := oxuiTColorPickerWindow;
   DefaultButtonWidth := 80;
   inherited Create();
end;

procedure oxwndTColorPickerDialog.Open();
begin
   Canceled := false;
   DoneCalled := false;

   inherited Open();
end;

procedure oxwndTColorPickerDialog.AddWidgets();
var
   i,
   j: loopint;
   w: uiTWidget;

begin
   if(HasAlpha) then
      uiWidget.LastRect.SetDefault(250)
   else
      uiWidget.LastRect.SetDefault(220);

   wdgLabel.Add('R: ');
   wdg.ibR := wdgInputBox.Add(sf(SelectedColor[0]), uiWidget.LastRect.RightOf(), oxDimensions(60, 20));
   wdg.ibR.SetControlMethod(@colorValueControl);
   wdg.ibR.SetID(wdgidR);

   uiWidget.LastRect.GoLeft();
   wdgLabel.Add('G: ');
   wdg.ibG := wdgInputBox.Add(sf(SelectedColor[1]), uiWidget.LastRect.RightOf(), oxDimensions(60, 20));
   wdg.ibG.SetControlMethod(@colorValueControl);
   wdg.ibG.SetID(wdgidG);

   uiWidget.LastRect.GoLeft();
   wdgLabel.Add('B: ');
   wdg.ibB := wdgInputBox.Add(sf(SelectedColor[2]), uiWidget.LastRect.RightOf(), oxDimensions(60, 20));
   wdg.ibB.SetControlMethod(@colorValueControl);
   wdg.ibB.SetID(wdgidB);

   if(HasAlpha) then begin
      uiWidget.LastRect.GoLeft();
      wdgLabel.Add('A: ');
      wdg.ibA := wdgInputBox.Add(sf(SelectedColor[3]), uiWidget.LastRect.RightOf(), oxDimensions(60, 20));
      wdg.ibA.SetControlMethod(@colorValueControl);
      wdg.ibA.SetID(wdgidA);
   end;

   if(HasAlpha) then
      w := wdg.ibA
   else
      w := wdg.ibB;

   wdg.Color := wdgBlock.Add(oxPoint(wdg.ibR.RightOf(), wdg.ibR.Position.y),
      oxDimensions(30, wdg.ibR.Position.y - w.Position.y + w.Dimensions.h));

   wdg.Color.Color := SelectedColor;

   wdgDivisor.Add('');

   uiWidget.LastRect.GoLeft();
   uiWidget.LastRect.GoBelow();

   for i := 0 to 1 do begin
      for j := 0 to 9 do
         wdg.Preset[i][j] := wdgBlock.Add(uiWidget.LastRect.RightOf(), oxDimensions(30, 20));

      uiWidget.LastRect.GoLeft();
      uiWidget.LastRect.GoBelow();
   end;

   wdgDivisor.Add('');

   uiWidget.LastRect.GoLeft();
   wdgLabel.Add('Hex Color: ');
   wdg.ibHexColor := wdgInputBox.Add('', uiWidget.LastRect.RightOf(), oxDimensions(100, 20));
   wdg.ibHexColor.ReadOnly := true;

   wdgDivisor.Add('');

   wdg.Ok := wdgButton.Add('Ok', uiWidget.LastRect.BelowOf(), oxDimensions(DefaultButtonWidth, 0), 0);
   wdg.Ok.ResizeHeight(wdg.Ok.GetComputedHeight());
   wdg.Ok.Callback.Use(@CallOk);

   wdg.Cancel := wdgButton.Add('Cancel', oxNullPoint, oxDimensions(DefaultButtonWidth, wdg.Ok.Dimensions.h), 0);
   wdg.Cancel.Callback.Use(@Close);
   wdg.Cancel.Move(wdg.Ok.RightOf(), wdg.Ok.Position.y);

   wdg.Pick := wdgButton.Add('Pick', oxNullPoint, oxDimensions(DefaultButtonWidth, wdg.Ok.Dimensions.h), 0);
   wdg.Pick.Callback.Use(@Pick);
   wdg.Pick.Move(wdg.Ok.LeftOf() - wdg.Pick.Dimensions.w, wdg.Ok.Position.y);

   Window.ContentAutoSize();
   SetupHexColor();
end;

procedure initialize();
begin
   oxwndColorPicker := oxwndTColorPickerDialog.Create();
end;

procedure deinitialize();
begin
   FreeObject(oxwndColorPicker);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'ox.about', @initialize, @deinitialize);

   wdgidR := uiControl.GetID('r');
   wdgidG := uiControl.GetID('g');
   wdgidB := uiControl.GetID('b');
   wdgidA := uiControl.GetID('a');

END.
