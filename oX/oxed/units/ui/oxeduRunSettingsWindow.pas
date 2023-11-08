{
   oxeduRunSettingsWindow, project settings
   Copyright (C) 2017. Dejan Boras

   Started On:    03.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduRunSettingsWindow;

INTERFACE

   USES
      uLog,
      {app}
      uStd, uAppInfo, appuEvents, appuActionEvents, appuKeys, appuKeyMappings,
      {oX}
      uOX, oxuTypes, oxuRunRoutines,
      {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF}
      {ui}
      oxuUI, uiuControl, uiuWindow, uiWidgets, uiuTypes, uiuMessageBox, uiuWidget, uiuKeyMappings,
      {wnd}
      oxuwndSettingsBase, oxuwndBase,
      {widgets}
      wdguLabel, wdguInputBox, wdguButton, wdguTabs, wdguDropDownList, wdguDivisor, wdguCheckbox, wdguList,
      {oxed}
      uOXED, oxeduProject;

TYPE

   { oxeduiTRunSettingsWindow }

   oxeduiTRunSettingsWindow = class(oxuiTWindowBase)
   end;

   { oxedTSettingsWindow }

   oxedTSettingsWindow = class(oxTSettingsWindowBase)
      widgets: record
         RunParameters: wdgTStringList;
         AddParameter,
         RemoveParameter: wdgTButton;
         Separator: wdgTDivisor;
      end;

      constructor Create(); override;
      procedure Open; override;

      protected
      procedure AddWidgets(); override;

      procedure AddParameter();
      procedure RemoveParameter();

      procedure Revert(); override;
      procedure Save(); override;
   end;

VAR
   oxedwndRunSettings: oxedTSettingsWindow;

IMPLEMENTATION

procedure closeSettingsWindow();
begin
   oxedwndRunSettings.Close();
end;

{ oxedTSettingsWindow }

procedure oxedTSettingsWindow.AddWidgets();
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

   Revert();
end;

procedure notify(var mb: uiTMessageBoxData);
begin
   if(mb.Input <> '') and (mb.What = uimbcWHAT_BUTTON) and (mb.Button = uimbcOK) then begin
      oxedwndRunSettings.widgets.RunParameters.Add(mb.Input);
   end;
end;

procedure oxedTSettingsWindow.AddParameter();
begin
   uiMessageBox.Show('Add Parameter', 'Add a new parameter to the list', uimbsQUESTION, uimbcOK_CANCEL, uimbpDEFAULT or uimbpINPUT, @notify);
end;

procedure oxedTSettingsWindow.RemoveParameter();
begin
   oxedwndRunSettings.widgets.RunParameters.Remove(oxedwndRunSettings.widgets.RunParameters.SelectedItem);
end;

procedure oxedTSettingsWindow.Revert();
var
   i: loopint;

begin
   inherited;

   widgets.RunParameters.RemoveAll();

   for i := 0 to oxedProject.RunParameters.n - 1 do begin
       widgets.RunParameters.Add(oxedProject.RunParameters[i]);
   end;
end;

procedure oxedTSettingsWindow.Save();
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

procedure consoleCallback({%H-}con: conPConsole);
begin
   if(oxedwndRunSettings <> nil) then
      oxedwndRunSettings.Open();
end;

constructor oxedTSettingsWindow.Create();
begin
   Name := 'run_settings';
   Title := 'Run Settings';

   Instance := oxeduiTRunSettingsWindow;

   console.Selected^.AddCommand('wnd:run_settings', @consoleCallback);

   inherited Create;

   oxKeyMappings.AddKey('ox.open_run_settings', 'Open settings', kcR, kmALT)^.
      Action := OpenWindowAction;
end;

procedure oxedTSettingsWindow.Open;
begin
   inherited Open;
end;

procedure init();
begin
   oxedwndRunSettings := oxedTSettingsWindow.Create();
end;

procedure deinit();
begin
   FreeObject(oxedwndRunSettings);
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'oxed.run_settings', @init, @deinit);

END.
