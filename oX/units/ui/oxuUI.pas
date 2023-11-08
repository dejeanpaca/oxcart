{
   oxuUI, basis for ox UI
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxuUI;

INTERFACE

   USES
      uStd, uLog, uTiming, udvars,
      {app}
      appuMouse,
      {oX}
      uOX, oxuWindow, oxuWindows, oxuRenderer, oxuRenderers, oxuTypes, oxuResourcePool, oxuRunRoutines,
      oxuShader, oxuMaterial, oxuFont,
      {ui}
      uiuTypes, uiuControl, uiuWindowTypes, uiuSkinTypes, uiuWidget;

TYPE
   uiTSelectArray = array[0..uiMAXIMUM_LEVELS - 1] of uiTControl;

   { uiTSelectInfo }

   uiTSelectInfo = record
      {selection information}
      l: longint;
      s: uiTSelectArray;

      {position of the point within the selected control}
      x, y: longint;
      {starting point}
      startPoint: oxTPoint;

      {the found control}
      Selected: uiTControl;
      {exclude a control from the search}
      Exclude: uiTControl;
      {search only through windows}
      OnlyWindows: boolean;

      procedure Init();

      {Checks if the given control is in the selection. Returns its level, otherwise -1}
      function IsIn(t: uiTControl): longint;
      {deselects the given control, if in selection}
      function Deselect(t: uiTControl): boolean;
      procedure Deselect();
      {set selection}
      procedure Assign(t: uiTControl);

      function GetSelectedWnd(): uiTWindow;
      function GetSelectedWdg(): uiTWidget;
   end;

   { uiTPointerCapture }

   uiTPointerCapture = record
      Typ: uiTPointerCaptureType;
      WindowOperation: uiTPointerWindowOperation;
      Wnd: uiTWindow;
      Wdg: uiTWidget;
      Point: oxTPointf;
      Moved: boolean;

      procedure Clear();
      {lock capture to the specified window}
      procedure LockWindow();
   end;

   { oxTUI }

   oxTUI = class
      {currently selected window}
      Select: uiTSelectInfo;
      {which window to use for further actions}
      UseWindow: uiTWindow;

      {control which the mouse is currently over}
      mSelect: uiTSelectInfo;
      {time that the selected item is hovered over}
      mSelectHoverTime,
      {time when the pointer last performed an event on a mouse selected item}
      mLastEventTime: LongWord;

      {standard internal skin}
      StandardSkin: uiTSkin;
      {default skin}
      DefaultSkin: uiTSkin;

      { skins }
      nSkins: longint;
      Skins: array of uiTSkin;

      {pointer capture data}
      PointerCapture: uiTPointerCapture;

      WindowMove: oxTPoint;

      {Material used for the UI}
      Material: oxTMaterial;
      {default font, if nil then oxf.Default is used}
      Font: oxTFont;

      {group for ui settings}
      dvg: TDVarGroup; static;

      constructor Create();

      function GetUseWindow(): uiTWindow;
      procedure SetUseWindow(wnd: uiTWindow);

      procedure SetDefaultFont(f: oxTFont);
      function GetDefaultFont(): oxTFont;
      procedure GetNilDefault(var f: oxTFont);
   end;

VAR
   oxui: oxTUI;

IMPLEMENTATION

{ uiTPointerCapture }

procedure uiTPointerCapture.Clear();
begin
   if(wnd <> nil) then
      appm.Release(wnd.oxwParent);

   Moved := false;
   Typ := uiPOINTER_CAPTURE_NONE;
   Wdg := nil;
   Wnd := nil;
end;

procedure uiTPointerCapture.LockWindow;
begin
   if(wnd <> nil) then begin
      appm.Grab(wnd.oxwParent);
   end;
end;

{ uiTSelectInfo }

procedure uiTSelectInfo.Init();
begin
   ZeroOut(Self, SizeOf(Self));
end;

function uiTSelectInfo.IsIn(t: uiTControl): longint;
begin
   if(l > -1) and (t.Level <= l) then begin
      if(t = s[t.Level]) then
         exit(t.Level)
   end;

   Result := -1;
end;

function uiTSelectInfo.Deselect(t: uiTControl): boolean;
var
   nl: longint;

begin
   nl := IsIn(t);

   if(nl > -1) then begin
      l := nl - 1;
      Result := true;

      if(l > -1) then
         Selected := s[l]
      else
         Selected := nil;
   end else
      Result := false;
end;

procedure uiTSelectInfo.Deselect();
begin
   l := -1;
   Selected := nil;
end;

procedure uiTSelectInfo.Assign(t: uiTControl);
var
   cur: uiTControl;

begin
   l := t.Level;
   Selected := t;

   cur := t;

   if(cur <> nil) then repeat
      s[cur.Level] := cur;
      cur := cur.Parent;
   until (cur = nil);
end;

function uiTSelectInfo.GetSelectedWnd(): uiTWindow;
begin
   if(Selected <> nil) and (Selected.wnd <> nil) then
      Result := uiTWindow(Selected.wnd)
   else
      Result := nil;
end;

function uiTSelectInfo.GetSelectedWdg(): uiTWidget;
begin
   if(Selected <> nil) and (Selected.ControlType = uiCONTROL_WIDGET) then
      Result := uiTWidget(Selected)
   else
      Result := nil;
end;

constructor oxTUI.Create();
begin
   inherited;

   PointerCapture.Typ := uiPOINTER_CAPTURE_NONE;

   {make sure that no window is selected}
   mSelect.l             := -1;
   Select.l              := -1;

   mSelectHoverTime := timer.Cur();
   mLastEventTime := timer.Cur();
end;

function oxTUI.GetUseWindow(): uiTWindow;
begin
   if(oxui.UseWindow = nil) then
      Result := oxWindow.Current
   else
      Result := oxui.UseWindow;
end;

procedure oxTUI.SetUseWindow(wnd: uiTWindow);
begin
   UseWindow := wnd;
end;

procedure oxTUI.SetDefaultFont(f: oxTFont);
begin
   Font := f;
end;

function oxTUI.GetDefaultFont(): oxTFont;
begin
   if(Font <> nil) then
      Result := Font
   else
      Result := oxf.GetDefault();
end;

procedure oxTUI.GetNilDefault(var f: oxTFont);
begin
   if(f = nil) then
      f := GetDefaultFont();
end;

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
   oxResource.Free(oxui.Material);

   oxui.Material := oxMaterial.Make();
   oxui.Material.Name := 'ui';
   oxui.Material.MarkPermanent();
end;

VAR
   routine: oxTRunRoutine;

INITIALIZATION
   oxui := oxTUI.Create();
   oxRenderers.PostUseRoutines.Add(@onUse);

   ox.OnRun.Add(routine, 'ui.update_controls', @updateControls);

   ox.dvar.Add('ui', oxTUI.dvg);

FINALIZATION
   FreeObject(oxui);

END.
