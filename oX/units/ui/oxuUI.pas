{
   oxuUI, basis for ox UI
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxuUI;

INTERFACE

   USES
      uStd, uInit, uLog, uTiming, udvars,
      {app}
      appuRun, appuMouse,
      {oX}
      uOX, oxuWindow, oxuWindows, oxuRenderer, oxuRenderers, oxuTypes, oxuResourcePool,
      oxuShader, oxuMaterial,
      {ui}
      uiuTypes, uiuControl, uiuWindowTypes, uiuWidget;

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

   uiTWindowBaseReference = record
      uid: qword;
      wnd: uiTWindow;
   end;

   uiTWindowBaseReferencesList = array of uiTWindowBaseReference;

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
      {ui is initialized and ready}
      Initialized,
      {ui started initialization (if false it means it never attempted to initialize)}
      StartedInitialization,
      PointerHover: boolean;

      {total number of widget types}
      nWidgetTypes: longint;
      {widget classes}
      WidgetClasses: uiTWidgetClasses;

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

      {initialization procedures}
      InitializationProcs,
      PostInitializationProcs: TInitializationProcs;

      WindowMove: oxTPoint;

      {material used for the UI}
      Material: oxTMaterial;

      {group for ui settings}
      dvg: TDVarGroup; static;

      constructor Create();

      procedure Initialize();
      procedure DeInitialize();

      function GetUseWindow(): uiTWindow;
      procedure SetUseWindow(wnd: uiTWindow);
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

constructor oxTUI.Create;
begin
   inherited;

   PointerHover := true;

   PointerCapture.Typ := uiPOINTER_CAPTURE_NONE;

   {make sure that no window is selected}
   mSelect.l             := -1;
   select.l              := -1;

   mSelectHoverTime := timer.Cur();
   mLastEventTime := timer.Cur();

   InitializationProcs.Init('ui.initialization');
   InitializationProcs.DontDetermineState();

   PostInitializationProcs.Init('ui.postinitialization');
   PostInitializationProcs.DontDetermineState();
end;

procedure oxTUI.Initialize();
begin
   oxui.StartedInitialization := true;
   oxui.InitializationProcs.iCall();
   oxui.PostInitializationProcs.iCall();

   log.i('Initialized UI');
end;

procedure oxTUI.DeInitialize;
begin
   if(StartedInitialization) then begin
      StartedInitialization := false;

      {de-initialize UI}
      oxui.InitializationProcs.dCall();
      oxui.PostInitializationProcs.dCall();

      oxResource.Free(Material);

      log.i('Deinitialized UI');
   end;
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

procedure updateControlWdg(wdg: uiTWidget);
var
   i: longint;

begin
   wdg.Update();

   if(wdg.Widgets <> nil) then
      for i := 0 to (wdg.Widgets.w.n - 1) do
         updateControlWdg(uiTWidget(wdg.Widgets.w[i]));
end;

procedure updateControlsWnd(wnd: uiTWindow);
var
   i: longint;

begin
   wnd.Update();

   if(wnd.Widgets <> nil) then begin
      for i := 0 to (uiTWidgets(wnd.Widgets).w.n - 1) do
         updateControlWdg(uiTWidget(uiTWidgets(wnd.Widgets).w.List[i]));
   end;

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
   FreeObject(oxui.Material);

   oxui.Material := oxMaterial.Instance();
   oxui.Material.AssignShader(oxShader.Default);
   oxui.Material.Name := 'ui';
   oxui.Material.MarkPermanent();
   oxui.Material.FromShader();
end;

VAR
   updateControlsRoutine: appTRunRoutine;

INITIALIZATION
   oxui := oxTUI.Create();
   oxRenderers.PostUseRoutines.Add(@onUse);

   appRun.AddRoutine(updateControlsRoutine, 'ui.update', @updateControls);

   ox.dvar.Add('ui', oxTUI.dvg);

FINALIZATION
   FreeObject(oxui);

END.
