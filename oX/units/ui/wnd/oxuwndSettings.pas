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
   oxuRenderers,
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
      {adds widgets to the video tab}

      procedure AddVideoWidgets();
      {add audio widgets to the audio tab}
      procedure AddAudioWidgets();
      {adds other widgets to the other tab}
      procedure AddOtherWidgets();
   end;

VAR
   oxwndSettings: oxTSettingsWindow;

IMPLEMENTATION

procedure revertCallback();
begin

end;

procedure oxTSettingsWindow.AddVideoWidgets();
var
   list: wdgTDropDownList;
   i, index: loopint;

begin
   wdgLabel.Add('Renderer', uiWidget.LastRect.BelowOf(0, -4), oxNullDimensions);
   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(0, 4), oxDimensions(90, 20));
   index := oxRenderers.CurrentIndex();

   {add renderers except the dummy renderer}
   list.Add('Default');

   for i := 1 to (oxRenderers.n - 1) do
      list.Add(oxRenderers.list[i].Name);

   {dont't allow to choose if there is not a choice}
   if(oxRenderers.n <= 2) then
      list.Enable(false);

   list.SelectItem(index);

   uiWidget.LastRect.GoLeft();

   wdgDivisor.Add('');

   uiWidget.LastRect.GoLeft();

   wdgLabel.Add('Resolution / Refresh rate / Color depth (bits)');
   list := wdgDropDownList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(120, 20));

   list.Add('Custom (!)');
   list.Add('320x240');
   list.Add('640x480');
   list.Add('800x600');
   list.Add('1024x768');
   list.Add('1366x768');
   list.Add('1280x720');
   list.Add('1920x1080');

   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(60, 20));

   list.Add('50');
   list.Add('59');
   list.Add('60');
   list.Add('75');
   list.Add('85');
   list.Add('120');
   list.Add('144');

   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(60, 20));

   list.Add('16');
   list.Add('32');
end;

procedure oxTSettingsWindow.AddAudioWidgets;
var
   list: wdgTDropDownList;

begin
   wdgCheckbox.Add('Enabled').Check(oxAudio.Enabled);

   wdgLabel.Add('Backend', uiWidget.LastRect.BelowOf(0, -4), oxNullDimensions);
   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(0, 4), oxDimensions(90, 20));

   list.Add('Default');

   wdgDivisor.Add('');
end;

procedure openDVarEditor();
begin
   oxwndDVarEditor.Open();
end;

procedure oxTSettingsWindow.AddOtherWidgets;
begin
   wdgButton.Add('Edit dvar variables', oxPoint(5, tabs.GetHeight() - 14), oxNullDimensions, @openDvarEditor);
end;

procedure oxTSettingsWindow.AddWidgets();
begin
   inherited;

   {add the label}
   CreateTabsWidget();

   tabs.AddTab('Video', 'video');
   AddVideoWidgets();

   tabs.AddTab('Audio', 'audio');

   AddAudioWidgets();

   tabs.AddTab('Other', 'other');

   AddOtherWidgets();

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
