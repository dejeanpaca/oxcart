{
   oxeduProjectFeaturesWindow, project features configuration window
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectFeaturesWindow;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes, oxuConsoleBackend,
      {wnd}
      oxuwndBase, oxuwndSettingsBase,
      {ui}
      uiuControl, uiuWidget, uiWidgets, uiuMessageBox, uiuTypes,
      {wdg}
      wdguList, wdguButton, wdguDivisor, wdguLabel,
      {oxed}
      uOXED, oxeduProject;

TYPE
   { oxeduiTProjectFeaturesWindow }

   oxeduiTProjectFeaturesWindow = class(oxuiTWindowBase)
   end;

   { oxedTProjectFeaturesWindow }

   oxedTProjectFeaturesWindow = object(oxTSettingsWindowBase)
      widgets: record
         Features: wdgTStringList;
         AddParameter,
         RemoveParameter: wdgTButton;
         Separator: wdgTDivisor;
      end;

      constructor Create();
      procedure Open(); virtual;

      protected
      procedure AddWidgets(); virtual;

      procedure AddParameter();
      procedure RemoveParameter();

      procedure Revert(); virtual;
      procedure Save(); virtual;
   end;

VAR
   oxedwndProjectFeatures: oxedTProjectFeaturesWindow;

IMPLEMENTATION

procedure closeSettingsWindow();
begin
   oxedwndProjectFeatures.Close();
end;

{ oxedTProjectFeaturesWindow }

procedure oxedTProjectFeaturesWindow.AddWidgets();
begin
   inherited;

   AddCancelSaveButtons();
   wdg.Save.Callback.Use(@Save);
   AddRevertButton();
   wdg.Revert.Callback.Use(@Revert);
   widgets.Separator := wdgDivisor.Add('', uiWidget.LastRect.AboveOf());

   uiWidget.LastRect.Assign(Window);
   wdgLabel.Add('Features:');
   widgets.Features := wdgStringList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(Window.Dimensions.w - wdgDEFAULT_SPACING*2, 120));
   widgets.Features.Selectable := true;
   widgets.Features.OddColored := true;

   widgets.AddParameter := wdgButton.Add('Add', uiWidget.LastRect.BelowOf(), oxNullDimensions, @AddParameter);
   widgets.AddParameter.SetButtonPosition([uiCONTROL_GRID_LEFT]);
   widgets.RemoveParameter := wdgButton.Add('Remove', uiWidget.LastRect.RightOf(0, 0, false), oxNullDimensions, @RemoveParameter);
   widgets.RemoveParameter.SetButtonPosition([uiCONTROL_GRID_RIGHT]);

   Revert();
end;

procedure notify(var mb: uiTMessageBoxData);
begin
   if(mb.Input <> '') and (mb.What = uimbcWHAT_BUTTON) and (mb.Button = uimbcOK) then begin
      oxedwndProjectFeatures.widgets.Features.Add(mb.Input);
   end;
end;

procedure oxedTProjectFeaturesWindow.AddParameter();
begin
   uiMessageBox.Show('Add Parameter', 'Add a new parameter to the list', uimbsQUESTION, uimbcOK_CANCEL, uimbpDEFAULT or uimbpINPUT, @notify);
end;

procedure oxedTProjectFeaturesWindow.RemoveParameter();
begin
   oxedwndProjectFeatures.widgets.Features.Remove(oxedwndProjectFeatures.widgets.Features.SelectedItem);
end;

procedure oxedTProjectFeaturesWindow.Revert();
var
   i: loopint;

begin
   inherited;

   widgets.Features.RemoveAll();

   for i := 0 to oxedProject.Features.n - 1 do begin
       widgets.Features.Add(oxedProject.Features[i]);
   end;
end;

procedure oxedTProjectFeaturesWindow.Save();
var
   i: loopint;

begin
   oxedProject.Features.Allocate(oxedwndProjectFeatures.widgets.Features.Items.n);

   for i := 0 to oxedwndProjectFeatures.widgets.Features.Items.n - 1 do begin
       oxedProject.Features[i] := oxedwndProjectFeatures.widgets.Features.Items[i];
       oxedProject.Features.n := oxedwndProjectFeatures.widgets.Features.Items.n;
   end;

   inherited;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxedwndProjectFeatures.Open();
end;
{$ENDIF}

constructor oxedTProjectFeaturesWindow.Create();
begin
   Name := 'project_features';
   Title := 'Project Features';

   Instance := oxeduiTProjectFeaturesWindow;

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:project_features', @consoleCallback);
   {$ENDIF}

   inherited Create;
end;

procedure oxedTProjectFeaturesWindow.Open();
begin
   inherited Open;
end;

procedure init();
begin
   oxedwndProjectFeatures.Create();
end;

procedure deinit();
begin
   oxedwndProjectFeatures.Destroy();
end;

INITIALIZATION
   oxed.Init.Add('oxed.features_window', @init, @deinit);

END.
