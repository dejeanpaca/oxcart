{
   oxuwndSettingsVideo, video settings tab
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
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

VAR
   wdg: record
      Renderers,
      Modes,
      Aspect,
      Resolutions,
      RefreshRate,
      ColorDepth: wdgTDropDownList;
   end;

procedure revertSettings();
begin
   {dont't allow to choose if there is not a choice}
   if(oxRenderers.n <= 2) then
      wdg.Renderers.Enable(false);

   wdg.Renderers.SelectItem(oxRenderers.CurrentIndex());
end;

procedure addVideoTab();
var
   list: wdgTDropDownList;
   i: loopint;

begin
   oxwndSettings.Tabs.AddTab('Video', 'video');

   wdgLabel.Add('Renderer', uiWidget.LastRect.BelowOf(0, -4), oxNullDimensions);
   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(0, 4), oxDimensions(90, 20));
   wdg.Renderers := list;

   {add renderers except the dummy renderer}
   list.Add('Default');

   for i := 1 to (oxRenderers.n - 1) do
      list.Add(oxRenderers.list[i].Name);

   uiWidget.LastRect.GoLeft();

   wdgDivisor.Add('Video settings');

   uiWidget.LastRect.GoLeft();

   { video mode }

   wdgLabel.Add('Mode');

   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(160, 20));
   wdg.Modes := list;

   list.Add('Window');
   list.Add('Fullscreen');
   list.Add('Windowed Fullscreen');

   uiWidget.LastRect.GoLeft();

   { settings }

   wdgLabel.Add('Aspect /  Resolution / Refresh rate / Color depth (bits)');

   { aspect }

   list := wdgDropDownList.Add(uiWidget.LastRect.BelowOf(), oxDimensions(65, 20));
   wdg.Aspect := list;

   list.Add('4:3');
   list.Add('16:9');
   list.Add('16:10');
   list.Add('18:9');

   { resolution }

   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(160, 20));
   wdg.Resolutions := list;

   list.Add('Custom');
   list.Add('320x240');
   list.Add('640x480');
   list.Add('800x600');
   list.Add('1024x768');
   list.Add('1366x768');
   list.Add('1280x720');
   list.Add('1920x1080');
   list.Add('2560x1440');
   list.Add('3840x2160');

   { refresh rate }

   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(60, 20));
   wdg.RefreshRate := list;

   list.Add('50');
   list.Add('59');
   list.Add('60');
   list.Add('75');
   list.Add('85');
   list.Add('120');
   list.Add('144');
   list.Add('240');

   { color depth }

   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(), oxDimensions(60, 20));
   wdg.ColorDepth := list;

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
