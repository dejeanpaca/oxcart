{
   oxuwndSettingsVideo, video settings tab
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettingsVideo;

INTERFACE

   USES
      uStd,
      {oX}
      uOX,  oxuTypes, oxuwndSettings,
      oxuRenderers,
      {ui}
      uiWidgets, wdguLabel, wdguDropDownList, wdguDivisor;

IMPLEMENTATION

procedure revertSettings();
begin

end;

procedure addVideoTab();
var
   list: wdgTDropDownList;
   i, index: loopint;

begin
   oxwndSettings.Tabs.AddTab('Video', 'video');

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

   { resolution }

   wdgDivisor.Add('Video settings');

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


procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.OnAddTabs.Add(@addVideoTab);
end;

INITIALIZATION
   ox.Init.Add('wnd:settings.video', @init);

END.
