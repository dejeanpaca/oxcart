{
   oxuwndSettingsOther, other settings tab
   Copyright (C) 2019. Dejan Boras

   Started On:    10.11.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettingsOther;

INTERFACE

   USES
      uStd,
      {oX}
      uOX,  oxuTypes,
      oxuwndSettings, oxuwndDVarEditor,
      {ui}
      uiWidgets, wdguButton;

IMPLEMENTATION

procedure revertSettings();
begin

end;

procedure openDVarEditor();
begin
   oxwndDVarEditor.Open();
end;

procedure addOtherTab();
begin
   oxwndSettings.Tabs.AddTab('Other', 'other');

   wdgButton.Add('Edit dvar variables', uiWidget.LastRect.BelowOf(), oxNullDimensions, @openDvarEditor);
end;

procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.OnAddTabs.Add(@addOtherTab);
end;

INITIALIZATION
   ox.Init.Add('ox.wnd:settings.other', @init);

END.
