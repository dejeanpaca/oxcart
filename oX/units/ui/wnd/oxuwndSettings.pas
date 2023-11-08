{
   oxuwndSettings, oX Settings Window
   Copyright (C) 2014. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettings;

INTERFACE

USES
   {app}
   uStd, appuKeys,
   {oX}
   uOX, oxuRunRoutines,
   {$IFDEF OX_FEATURE_CONSOLE}
   oxuConsoleBackend,
   {$ENDIF}
   oxuAudioBase,
   {ui}
   uiuWindow, uiWidgets, uiuKeyMappings,
   {wnd}
   oxuwndSettingsBase,
   {widgets}
   wdguLabel, wdguButton, wdguDropDownList, wdguDivisor, wdguCheckbox;

TYPE
   { oxTSettingsWindow }

   oxTSettingsWindow = object(oxTSettingsWindowBase)
      constructor Create();

      protected
      {adds widgets to the connect window}
      procedure AddWidgets(); virtual;
   end;

VAR
   oxwndSettings: oxTSettingsWindow;

IMPLEMENTATION

procedure revertCallback();
begin

end;

procedure oxTSettingsWindow.AddWidgets();
begin
   inherited;

   {add the label}
   CreateTabsWidget();

   DoneTabs();

   AddCancelSaveButtons();
   AddRevertButton();

   AddDivisor();
end;

{$IFDEF OX_FEATURE_CONSOLE}
procedure consoleCallback({%H-}con: conPConsole);
begin
   oxwndSettings.Open();
end;
{$ENDIF}

constructor oxTSettingsWindow.Create();
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
   oxwndSettings.Create();
end;

procedure deinit();
begin
   oxwndSettings.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.wnd:settings', @init, @deinit);

END.
