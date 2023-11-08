{
   oxeduProjectSettingsWindow, project settings
   Copyright (C) 2017. Dejan Boras

   Started On:    03.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectSettingsWindow;

INTERFACE

   USES
      {app}
      uStd, appuKeys,
      {oX}
      uOX, oxuTypes, {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF}
      {ui}
      uiuWindow, uiWidgets,
      oxuwndSettingsBase, oxuwndBase,
      {widgets}
      wdguLabel, wdguInputBox, wdguButton, wdguDropDownList, wdguDivisor, wdguCheckbox, wdguList,
      {oxed}
      uOXED, oxeduProject;

TYPE

   { oxeduiTProjectSettingsWindow }

   oxeduiTProjectSettingsWindow = class(oxuiTWindowBase)
   end;

   { oxedTSettingsWindow }

   oxedTSettingsWindow = class(oxTSettingsWindowBase)
      constructor Create(); override;
      procedure Open; override;

      protected
      procedure AddWidgets(); override;

      procedure UpdateBuildModesWidget();
      procedure LoadBuildModeSettings();
      procedure StoreBuildModeSettings();

      procedure AddProjectWidgets();
      procedure AddBuildWidgets();
   end;

VAR
   oxedwndProjectSettings: oxedTSettingsWindow;

IMPLEMENTATION

VAR
   widgets: record
      Project: record
         Name,
         ShortName,
         Identifier,
         Organization,
         OrganizationShort: wdgTInputBox;
         UnixLineEndings,
         EnableConsole: wdgTCheckbox;
      end;

      Build: record
         MainUnit: wdgTInputBox;
         Symbols: wdgTStringList;
         Modes: wdgTDropDownList;
         DebugResources: wdgTCheckbox;

         Mode: record
            Symbols: wdgTStringList;
         end;
      end;
   end;

   {copy of build modes settings}
   BuildModes: oxedTProjectBuildModes;

function validateCallback(): TAppendableString;
var
   s: string;

begin
   Result := '';

   { project name }
   s := widgets.Project.Name.GetText();

   if(s = '') then
      Result.Add('Invalid project name (must not be empty)');

   { project identifier }
   s := widgets.Project.Identifier.GetText();
   if(s = '') or (oxedProject.NormalizedIdentifier(s) <> s) then
      Result.Add('Invalid project identifier (must be a pascal compatible identifier)');
end;

function validateBuildCallback(): TAppendableString;
begin
   Result := '';
end;

procedure revertCallback();
begin
   widgets.Project.Name.SetText(oxedProject.Name);
   widgets.Project.Identifier.SetText(oxedProject.Identifier);
   widgets.Project.ShortName.SetText(oxedProject.ShortName);
   widgets.Project.Organization.SetText(oxedProject.Organization);
   widgets.Project.OrganizationShort.SetText(oxedProject.OrganizationShort);
   widgets.Project.UnixLineEndings.Check(oxedProject.LineEndings = 'lf');
   widgets.Project.EnableConsole.Check(oxedProject.Session.EnableConsole);

   widgets.Build.MainUnit.SetText(oxedProject.MainUnit);
   widgets.Build.DebugResources.Check(oxedProject.Session.DebugResources);
end;

procedure saveCallback();
begin
   { project name }
   oxedProject.Name := widgets.Project.Name.GetText();

   { project short name }
   oxedProject.ShortName := widgets.Project.ShortName.GetText();

   { project identifier }
   oxedProject.Identifier := widgets.Project.Identifier.GetText();

   { project organization }
   oxedProject.Organization := widgets.Project.Organization.GetText();

   { project organization short }
   oxedProject.OrganizationShort := widgets.Project.OrganizationShort.GetText();

   { line endings }
   if(widgets.Project.UnixLineEndings.Checked()) then
      oxedProject.LineEndings := 'lf'
   else
      oxedProject.LineEndings := 'crlf';

   { enable console }
   oxedProject.Session.EnableConsole := widgets.Project.EnableConsole.Checked();

   { other }
   oxedwndProjectSettings.StoreBuildModeSettings();

   {done}
   oxedProject.MarkModified();
end;

{ oxedTSettingsWindow }

procedure oxedTSettingsWindow.AddWidgets();
begin
   inherited;

   CreateTabsWidget();

   tabs.AddTab('Project', 'project');
   AddProjectWidgets();

   tabs.AddTab('Build', 'build');
   AddBuildWidgets();

   DoneTabs();

   AddCancelSaveButtons();
   AddRevertButton();

   wdg.Save.Callback.Use(@Save);
   wdg.Revert.Callback.Use(@Revert);

   uiWidget.ClearTarget();

   Revert();
end;

procedure oxedTSettingsWindow.AddProjectWidgets();
begin
   wdgLabel.Add('Project path: ' + oxedProject.Path);
   uiWidget.LastRect.VerticalSpacing();

   wdgDivisor.Add('Project basics', uiWidget.LastRect.BelowOf());

   wdgLabel.Add('Project name');
   widgets.Project.Name := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);
   wdgLabel.Add('Project short name (used for config directory), if empty set to default automatically');
   widgets.Project.ShortName := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);
   wdgLabel.Add('Project identifier (pascal compatible identifier)');
   widgets.Project.Identifier := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);
   wdgLabel.Add('Project organization (not required)');
   widgets.Project.Organization := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);
   wdgLabel.Add('Project organization short name (used or config directory), if empty set to default automatically');
   widgets.Project.OrganizationShort := wdgInputBox.Add('', uiWidget.LastRect.BelowOf(), oxNullDimensions);
   wdgDivisor.Add('', uiWidget.LastRect.BelowOf());
   widgets.Project.UnixLineEndings := wdgCheckbox.Add('Unix line endings', uiWidget.LastRect.BelowOf());
   widgets.Project.EnableConsole := wdgCheckbox.Add('Enable engine console in project', uiWidget.LastRect.BelowOf());
end;

procedure addGlobalSymbol();
begin

end;

procedure removeGlobalSymbol();
begin

end;

procedure moveGlobalSymbolUp();
begin

end;

procedure moveGlobalSymbolDown();
begin

end;

procedure oxedTSettingsWindow.UpdateBuildModesWidget();
var
   i: loopint;

begin
   widgets.Build.Modes.Clear();

   for i := 0 to oxedProject.BuildModes.n - 1 do begin
      widgets.Build.Modes.Add(oxedProject.BuildModes.List[i].Name);
   end;
end;

procedure oxedTSettingsWindow.LoadBuildModeSettings();
var
   i, j: loopint;
   mode, source: oxedPProjectBuildMode;

begin
   {copy over build mode settings}
   BuildModes.Dispose();
   if(oxedProject.BuildModes.n > 0) then begin
      BuildModes.Allocate(oxedProject.BuildModes.n);

      for i := 0 to oxedProject.BuildModes.n - 1 do begin
         mode := @BuildModes.List[i];
         source := @oxedProject.BuildModes.List[i];
         mode^.Name := source^.Name;
         mode^.Symbols.Dispose();
         mode^.Symbols.Allocate(source^.Symbols.n);

         for j := 0 to source^.Symbols.n - 1 do begin
            mode^.Symbols.List[j] := source^.Symbols.List[j];
         end;
      end;
   end;
end;

procedure oxedTSettingsWindow.StoreBuildModeSettings();
var
   i, j: loopint;
   mode, source: oxedPProjectBuildMode;

begin
   {copy over build mode settings}
   oxedProject.BuildModes.Dispose();

   if(BuildModes.n > 0) then begin
      oxedProject.BuildModes.Allocate(BuildModes.n);

      for i := 0 to BuildModes.n - 1 do begin
         mode := @oxedProject.BuildModes.List[i];
         source := @BuildModes.List[i];

         mode^.Name := source^.Name;
         mode^.Symbols.Dispose();
         mode^.Symbols.Allocate(source^.Symbols.n);

         for j := 0 to source^.Symbols.n - 1 do begin
            mode^.Symbols.List[j] := source^.Symbols.List[j];
         end;
      end;
   end;

   oxedProject.MainUnit := widgets.Build.MainUnit.GetText();
   oxedProject.Session.DebugResources := widgets.Build.DebugResources.Checked();
end;

procedure oxedTSettingsWindow.AddBuildWidgets();
var
   lastRect: uiTWidgetLastRect;
   dimensions: oxTDimensions;

begin
   dimensions.Assign(100, 20);

   wdgDivisor.Add('Basics', uiWidget.LastRect.BelowOf());
   wdgLabel.Add('Main unit (if specified, will be the only unit listed in soruce), when you want to manage the order of things yourself');
   widgets.Build.MainUnit := wdgInputBox.Add(oxedProject.MainUnit, uiWidget.LastRect.BelowOf(), oxNullDimensions);
   uiWidget.LastRect.VerticalSpacing();

   widgets.Build.DebugResources := wdgCheckbox.Add('Debug Resources', uiWidget.LastRect.BelowOf(), oxedProject.Session.DebugResources);

   wdgDivisor.Add('Global symbols', uiWidget.LastRect.BelowOf());
   uiWidget.LastRect.VerticalSpacing();

   wdgList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(240, 160));
   lastRect := uiWidget.LastRect;

   wdgButton.Add('Add', uiWidget.LastRect.RightOf(), dimensions, @addGlobalSymbol);
   wdgButton.Add('Remove', uiWidget.LastRect.BelowOf(), dimensions, @removeGlobalSymbol);
   wdgButton.Add('Move Up', uiWidget.LastRect.BelowOf(), dimensions, @moveGlobalSymbolUp);
   wdgButton.Add('Move Down', uiWidget.LastRect.BelowOf(), dimensions, @moveGlobalSymbolDown);

   uiWidget.LastRect := lastRect;
   uiWidget.LastRect.GoLeft();

   wdgDivisor.Add('Build modes', uiWidget.LastRect.BelowOf());

   wdgList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(240, 160));
   lastRect := uiWidget.LastRect;

   wdgButton.Add('Add', uiWidget.LastRect.RightOf(), dimensions, @addGlobalSymbol);
   wdgButton.Add('Remove', uiWidget.LastRect.BelowOf(), dimensions, @removeGlobalSymbol);
   wdgButton.Add('Move Up', uiWidget.LastRect.BelowOf(), dimensions, @moveGlobalSymbolUp);
   wdgButton.Add('Move Down', uiWidget.LastRect.BelowOf(), dimensions, @moveGlobalSymbolDown);

   uiWidget.LastRect := lastRect;
   uiWidget.LastRect.GoLeft();

   uiWidget.LastRect.VerticalSpacing();

   wdgDivisor.Add('Build mode settings', uiWidget.LastRect.BelowOf());
   wdgLabel.Add('Build mode: ');
   widgets.Build.Modes := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(160, 20));
   UpdateBuildModesWidget();
end;

procedure consoleCallback({%H-}con: conPConsole);
begin
   if(oxedwndProjectSettings <> nil) then
      oxedwndProjectSettings.Open();
end;

constructor oxedTSettingsWindow.Create();
begin
   Name := 'settings';
   Title := 'Settings';

   UseSurface := true;

   Instance := oxeduiTProjectSettingsWindow;

   console.Selected^.AddCommand('settings', @consoleCallback);

   inherited Create;

   ox.KeyMappings.AddKey('ox.open_project_settings', 'Open project settings', kcS, kmSHIFT or kmALT)^.
      Action := OpenWindowAction;

   OnValidate.Add(@validateCallback);
   OnValidate.Add(@validateBuildCallback);
   OnRevert.Add(@revertCallback);
   OnSave.Add(@saveCallback);
end;

procedure oxedTSettingsWindow.Open;
begin
   LoadBuildModeSettings();

   inherited Open;
end;

procedure init();
begin
   oxedwndProjectSettings := oxedTSettingsWindow.Create();
end;

procedure deinit();
begin
   FreeObject(oxedwndProjectSettings);
end;

INITIALIZATION
   oxed.Init.Add('oxed.project_settings', @init, @deinit);

END.