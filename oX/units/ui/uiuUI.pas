{
   uiuUI, basis for UI interfaces
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuUI;

INTERFACE

   USES
      uStd, uTiming, udvars,
      {app}
      appuMouse,
      {oX}
      uOX, oxuWindow, oxuTypes, oxuResourcePool, oxuMaterial, oxuFont,
      {ui}
      uiuTypes, uiuControl, uiuWindowTypes, uiuSkinTypes, uiuWidget, uiuSkin;

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

   { uiTUI }

   uiTUI = class
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

      {default skin}
      DefaultSkin: uiTSkin;

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

      procedure Start();
      procedure Done();

      function GetUseWindow(): uiTWindow;
      procedure SetUseWindow(wnd: uiTWindow);

      procedure SetDefaultFont(f: oxTFont);
      function GetDefaultFont(): oxTFont;
      procedure GetNilDefault(var f: oxTFont);

      function GetDefaultSkin(): uiTSkin;
   end;

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

procedure uiTPointerCapture.LockWindow();
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

constructor uiTUI.Create();
begin
   inherited;

   PointerCapture.Typ := uiPOINTER_CAPTURE_NONE;

   {make sure that no window is selected}
   mSelect.l             := -1;
   Select.l              := -1;

   mSelectHoverTime := timer.Cur();
   mLastEventTime := timer.Cur();
end;

procedure uiTUI.Start();
begin
   oxResource.Free(Material);

   Material := oxMaterial.Make();
   Material.Name := 'ui';
   Material.MarkPermanent();
end;

procedure uiTUI.Done();
begin
   oxResource.Free(Material);
end;

function uiTUI.GetUseWindow(): uiTWindow;
begin
   if(UseWindow = nil) then
      Result := oxWindow.Current
   else
      Result := UseWindow;
end;

procedure uiTUI.SetUseWindow(wnd: uiTWindow);
begin
   UseWindow := wnd;
end;

procedure uiTUI.SetDefaultFont(f: oxTFont);
begin
   Font := f;
end;

function uiTUI.GetDefaultFont(): oxTFont;
begin
   if(Font <> nil) then
      Result := Font
   else
      Result := oxf.GetDefault();
end;

procedure uiTUI.GetNilDefault(var f: oxTFont);
begin
   if(f = nil) then
      f := GetDefaultFont();
end;

function uiTUI.GetDefaultSkin(): uiTSkin;
begin
   Result := DefaultSkin;

   if(Result = nil) then
      Result := uiSkin.StandardSkin;
end;

INITIALIZATION
   ox.dvar.Add('ui', uiTUI.dvg);

END.
