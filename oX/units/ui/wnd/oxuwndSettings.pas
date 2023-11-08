{
   oxuwndSettings, oX Settings Window
   Copyright (C) 2014. Dejan Boras

   Started On:    16.06.2014.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettings;

INTERFACE

USES
   {app}
   uStd, appuKeys,
   {oX}
   uOX, oxuTypes, oxuRunRoutines,
   {$IFDEF OX_FEATURE_CONSOLE}
   oxuConsoleBackend,
   {$ENDIF}
   oxuAudioBase,
   {ui}
   uiuWindow, uiWidgets, uiuKeyMappings,
   {wnd}
   oxuwndSettingsBase, oxuwndDVarEditor,
   {widgets}
   wdguLabel, wdguButton, wdguDropDownList, wdguDivisor, wdguCheckbox;

TYPE
   { oxTSettingsWindow }

   oxTSettingsWindow = class(oxTSettingsWindowBase)
      constructor Create(); override;

      protected
      {adds widgets to the connect window}
      procedure AddWidgets(); override;
   end;

VAR
   oxwndSettings: oxTSettingsWindow;

IMPLEMENTATION

procedure revertCallback();
begin

end;

procedure openDVarEditor();
begin
   oxwndDVarEditor.Open();
end;

procedure oxTSettingsWindow.AddWidgets();
begin
   inherited;

   {add the label}
   CreateTabsWidget();

   DoneTabs();

   AddCancelSaveButtons();
   AddRevertButton();

   uiWidget.ClearTarget();
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   if(oxwndSettings <> nil) then
      oxwndSettings.Open();
end;
{$ENDIF}

constructor oxTSettingsWindow.Create;
begin
   Name := 'settings';
   Title := 'Settings';

   UseSurface := true;

   {$IFDEF OX_FEATURE_CONSOLE}
   if(console.Selected <> nil) then
      console.Selected^.AddCommand('wnd:settings', @consoleCallback);
   {$ENDIF}

   inherited Create;

   {open settings window}
   uiKeyMappings.AddKey('ox.open_settings', 'Open settings', kcS, kmALT)^.
      Action := OpenWindowAction;

   OnRevert.Add(@revertCallback);
end;

procedure init();
begin
   oxwndSettings := oxTSettingsWindow.Create();
end;

procedure deinit();
begin
   FreeObject(oxwndSettings);
end;

INITIALIZATION
   ox.Init.Add('ox.settings', @init, @deinit);

END.
