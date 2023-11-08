{
   oxeduwndRunSettings, project settings
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduwndRunSettings;

INTERFACE

   USES
      uStd,
      appuKeys,
      {oX}
      oxuTypes, oxuConsoleBackend,
      {wnd}
      oxuwndBase, oxuwndSettingsBase,
      {ui}
      uiuControl, uiuWidget, uiWidgets, uiuMessageBox, uiuTypes, uiuKeyMappings,
      {wdg}
      wdguList, wdguButton, wdguDivisor, wdguLabel,
      {oxed}
      uOXED, oxeduProject;

TYPE

   { oxeduiTRunSettingsWindow }

   oxeduiTRunSettingsWindow = class(oxuiTWindowBase)
   end;

   { oxedTRunSettingsWindow }

   oxedTRunSettingsWindow = object(oxTSettingsWindowBase)
      widgets: record
         RunParameters: wdgTStringList;
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
   oxedwndRunSettings: oxedTRunSettingsWindow;

IMPLEMENTATION

procedure closeSettingsWindow();
begin
   oxedwndRunSettings.Close();
end;

{ oxedTRunSettingsWindow }

procedure oxedTRunSettingsWindow.AddWidgets();
begin
   inherited;

   AddCancelSaveButtons();
   wdg.Save.Callback.Use(@Save);
   AddRevertButton();
   wdg.Revert.Callback.Use(@Revert);
   widgets.Separator := wdgDivisor.Add('', uiWidget.LastRect.AboveOf());

   uiWidget.LastRect.Assign(Window);
   wdgLabel.Add('Run Parameters:');
   widgets.RunParameters := wdgStringList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(Window.Dimensions.w - wdgDEFAULT_SPACING*2, 120));
   widgets.RunParameters.Selectable := true;
   widgets.RunParameters.OddColored := true;

   widgets.AddParameter := wdgButton.Add('Add', uiWidget.LastRect.BelowOf(), oxNullDimensions, @AddParameter);
   widgets.AddParameter.SetButtonPosition([uiCONTROL_GRID_LEFT]);
   widgets.RemoveParameter := wdgButton.Add('Remove', uiWidget.LastRect.RightOf(0, 0, false), oxNullDimensions, @RemoveParameter);
   widgets.RemoveParameter.SetButtonPosition([uiCONTROL_GRID_RIGHT]);
end;

procedure notify(var mb: uiTMessageBoxData);
begin
   if(mb.Input <> '') and (mb.What = uimbcWHAT_BUTTON) and (mb.Button = uimbcOK) then begin
      oxedwndRunSettings.widgets.RunParameters.Add(mb.Input);
   end;
end;

procedure oxedTRunSettingsWindow.AddParameter();
begin
   uiMessageBox.Show('Add Parameter', 'Add a new parameter to the list', uimbsQUESTION, uimbcOK_CANCEL, uimbpDEFAULT or uimbpINPUT, @notify);
end;

procedure oxedTRunSettingsWindow.RemoveParameter();
begin
   oxedwndRunSettings.widgets.RunParameters.Remove(oxedwndRunSettings.widgets.RunParameters.SelectedItem);
end;

procedure oxedTRunSettingsWindow.Revert();
var
   i: loopint;

begin
   inherited;

   widgets.RunParameters.RemoveAll();

   for i := 0 to oxedProject.RunParameters.n - 1 do begin
       widgets.RunParameters.Add(oxedProject.RunParameters[i]);
   end;
end;

procedure oxedTRunSettingsWindow.Save();
var
   i: loopint;

begin
   oxedProject.RunParameters.Allocate(oxedwndRunSettings.widgets.RunParameters.Items.n);

   for i := 0 to oxedwndRunSettings.widgets.RunParameters.Items.n - 1 do begin
       oxedProject.RunParameters[i] := oxedwndRunSettings.widgets.RunParameters.Items[i];
       oxedProject.RunParameters.n := oxedwndRunSettings.widgets.RunParameters.Items.n;
   end;

   inherited;
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxedwndRunSettings.Open();
end;
{$ENDIF}

constructor oxedTRunSettingsWindow.Create();
begin
   Name := 'run_settings';
   Title := 'Run Settings';

   Instance := oxeduiTRunSettingsWindow;

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:run_settings', @consoleCallback);
   {$ENDIF}

   inherited Create;

   uiKeyMappings.AddKey('ox.open_run_settings', 'Open settings', kcR, kmALT)^.
      Action := OpenWindowAction;
end;

procedure oxedTRunSettingsWindow.Open();
begin
   inherited Open;
end;

procedure init();
begin
   oxedwndRunSettings.Create();
end;

procedure deinit();
begin
   oxedwndRunSettings.Destroy();
end;

INITIALIZATION
   oxed.Init.Add('oxed.run_settings', @init, @deinit);

END.
