{
   oxuUI, basis for ox UI
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuUI;

INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuWindows, oxuRenderers,
      {ui}
      uiuWindowTypes, uiuWidget, uiuBase, uiuUI;

VAR
   oxui: uiTUI;

IMPLEMENTATION

procedure updateControlWdg(wdg: uiTWidget);
var
   i: longint;

begin
   wdg.Update();

   for i := 0 to (wdg.Widgets.w.n - 1) do
      updateControlWdg(uiTWidget(wdg.Widgets.w[i]));
end;

procedure updateControlsWnd(wnd: uiTWindow);
var
   i: longint;

begin
   wnd.Update();

   for i := 0 to (uiTWidgets(wnd.Widgets).w.n - 1) do
      updateControlWdg(uiTWidget(uiTWidgets(wnd.Widgets).w.List[i]));

   for i := 0 to (wnd.w.w.n - 1) do
      updateControlsWnd(uiTWindow(wnd.w.w.List[i]));
end;

procedure updateControls();
var
   i: longint;

begin
   for i := 0 to (oxWindows.n - 1) do
      if(oxWindows.w[i] <> nil) then
         updateControlsWnd(uiTWindow(oxWindows.w[i]));
end;

procedure onUse();
begin
   oxui.Start();
end;

procedure init();
begin
   oxui := uiTUI.Create();
   oxRenderers.PostUseRoutines.Add(@onUse);
end;

procedure deinit();
begin
   oxui.Done();
   oxRenderers.PostUseRoutines.Add(@onUse);
   FreeObject(oxui);
end;

INITIALIZATION
   ox.OnRun.Add('ui.update_controls', @updateControls);
   ui.BaseInitializationProcs.Add('ui.oxui', @init, @deinit);

END.
