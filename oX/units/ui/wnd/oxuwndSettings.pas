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
   oxuRenderers, {$IFNDEF NO_OXCONSOLE}oxuConsoleBackend,{$ENDIF}
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

   for i := 0 to (oxRenderers.n - 1) do
      list.Add(oxRenderers.list[i].Name);

   list.SelectItem(index);

   uiWidget.LastRect.GoLeft();

   wdgDivisor.Add('', uiWidget.LastRect.BelowOf());

   uiWidget.LastRect.GoLeft();

   wdgLabel.Add('Resolution / Refresh rate / Color depth (bits)', uiWidget.LastRect.BelowOf(), oxNullDimensions);
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
   wdgCheckbox.Add('Enabled', uiWidget.LastRect.BelowOf(), oxAudio.Enabled);

   wdgLabel.Add('Backend', uiWidget.LastRect.BelowOf(0, -4), oxNullDimensions);
   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(0, 4), oxDimensions(90, 20));

   list.Add('Default');
   list.Add('nil');

   wdgDivisor.Add('', uiWidget.LastRect.BelowOf());
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

procedure consoleCallback({%H-}con: conPConsole);
begin
   if(oxwndSettings <> nil) then
      oxwndSettings.Open();
end;


constructor oxTSettingsWindow.Create;
begin
   Name := 'settings';
   Title := 'Settings';

   UseSurface := true;

   console.Selected^.AddCommand('settings', @consoleCallback);

   inherited Create;

   {open settings window}
   oxKeyMappings.AddKey('ox.open_settings', 'Open settings', kcS, kmALT)^.
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

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'ox.settings', @init, @deinit);

END.
