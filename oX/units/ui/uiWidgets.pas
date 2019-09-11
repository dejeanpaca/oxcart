{
   uiWidgets, UI widget management
   Copyright (C) 2011. Dejan Boras

   Started On:    01.06.2007.
}

{$INCLUDE oxdefines.inc}
UNIT uiWidgets;

INTERFACE

   USES
      uStd, StringUtils, uColors, appuEvents,
      {oX}
      oxuRunRoutines, oxuTypes, oxuUI, oxuWindows, oxuWindow,
      {ui}
      uiuTypes, oxuFont, uiuWindowTypes, uiuWidget, uiuControl, uiuSkin, uiuSkinTypes, uiuDraw;

CONST
   wdgevDISPOSE = 1;
   wdgevSELECT  = 2;

TYPE
   {same as uiTWidgetControlProc, except we use the actual type here}
   uiTWidgetControlMethod = function(wdg: uiTWidget; what: longword): longint;

   { uiTWidgetHelper }

   uiTWidgetHelper = class helper for uiTWidget
      procedure SetControlMethod(controlProc: uiTWidgetControlMethod);

      procedure RenderAll();

      { selection }
      {selects a widget}
      procedure Select();
      {selects a widget}
      procedure SelectQueue();
      {deselect a widget}
      procedure Deselected();
      {check if the widget is selected}
      function IsSelected(): boolean;
      {check if we're currently hovered over}
      function Hovering(): boolean; inline;

      {set the position of a widget}
      function SetPosition(Properties: TBitSet; Separation: boolean = true): uiTWidget;
      {center widget vertically}
      function CenterVertically(): uiTWidget;
      {center widget horizontally}
      function CenterHorizontally(): uiTWidget;

      {set the size of a widget}
      function SetSize(Properties: TBitSet): uiTWidget;
      {set both size and position properties of a widget}
      function SetSizePosition(sizeProperties, positionProperties: TBitSet): uiTWidget;

      {automatically resize widget}
      procedure AutoSize();

      {dispose of the widgets contents}
      procedure Dispose();
      {dispose of the child widgets}
      procedure DisposeSubWidgets();

      {visible property}
      procedure Show();
      procedure Hide();

      { target }
      procedure SetTarget(cp: uiTWidgetControlProc = nil);

      {gets a skin associated with the widget, if none available returns default}
      function GetSkin(): uiPWidgetSkin;
      {gets a skin associated with the widget, if none available returns default}
      function GetSkinObject(): uiTSkin;
      {gets a color with the specified index from the skin}
      function GetColor(clrIdx: longint): TColor4ub;
      {set a color with the specified index}
      procedure SetColor(clrIdx: longint);
      {set a color with the specified index, with blending enabled}
      procedure SetColorBlended(clrIdx: longint);
      {set a color}
      procedure SetColor(color:  TColor4ub);
      {set the specified color with blending enabled}
      procedure SetColorBlended(color: TColor4ub);
      {set a color}
      procedure SetColorEnabled(color, disabledColor:  TColor4ub);
      {set the specified color with blending enabled}
      procedure SetColorBlendedEnabled(color, disabledColor: TColor4ub);

      {locking pointer}
      procedure LockPointer();
      procedure LockPointer(x, y: single);
      procedure UnlockPointer();

      {returns position of a widget if it exists, -1 if not}
      function Exists(const wdg: uiTWidget): longint;

      {move widget}
      function Move(x, y: longint): uiTWidget;
      function Move(const p: oxTPoint): uiTWidget;
      function MoveOffset(x, y: loopint): uiTWidget;

      {NOTE: -1 spacing means automatic spacing}

      {move below the specified widget}
      function MoveBelow(wdg: uiTWidget; spacing: longint = -1): uiTWidget;
      {move above the specified widget}
      function MoveAbove(wdg: uiTWidget; spacing: longint = -1): uiTWidget;
      {move to the left of the specified widget}
      function MoveLeftOf(wdg: uiTWidget; spacing: longint = -1): uiTWidget;
      {move to the right of the specified widget}
      function MoveRightOf(wdg: uiTWidget; spacing: longint = -1): uiTWidget;

      {move as far to the right as possible}
      function MoveRightmost(spacing: longint = -1): uiTWidget;
      {move as far to the right as possible}
      function MoveLeftmost(spacing: longint = -1): uiTWidget;

      {resize widget, (0, 0) is considered valid dimensions unlike when creating a widget}
      function Resize(w, h: longint): uiTWidget;
      function ResizeWidth(w: longint): uiTWidget;
      function ResizeHeight(h: longint): uiTWidget;
      {resize widget, (0, 0) is considered valid dimensions unlike when creating a widget}
      function Resize(const d: oxTDimensions): uiTWidget;
      {resize widget to the computed dimensions}
      function ResizeComputed(): uiTWidget;

      {auto set widget dimensions}
      procedure AutoSetWidgetDimensions(force: boolean = false);

      {fill the window}
      procedure FillWindow();
   end;

   uiTWidgetTarget = record
      Window: uiTWindow;
      Widget: uiTWidget;
      ControlProcedure: uiTWidgetControlProc;
      Font: oxTFont;
   end;

   uiTWidgetCreateData = record
      Instance: uiTWidgetClassType;
      ZIndex: loopint;
   end;

   { uiTWidgetLastRect }

   uiTWidgetLastRect = record
      r: oxTRect;

      procedure Assign(const anotherR: oxTRect);
      procedure Assign(const p: oxTPoint; const d: oxTDimensions);
      procedure Assign(wnd: uiTWindow);
      procedure Assign(wdg: uiTControl);
      procedure SetDefault(height: longint);

      procedure GoLeft();
      procedure GoBelow(spacing: loopint = -1);

      function AboveOf(xOffset: longint = 0; yOffset: longint = 0; spacing: boolean = true): oxTPoint;
      function BelowOf(xOffset: longint = 0; yOffset: longint = 0; spacing: boolean = true): oxTPoint;
      function RightOf(xOffset: longint = 0; yOffset: longint = 0; spacing: boolean = true): oxTPoint;
      function LeftOf(xOffset: longint = 0; yOffset: longint = 0; spacing: boolean = true): oxTPoint;

      procedure VerticalSpacing(spacing: loopint = -1);
   end;

   { uiTWidgetGlobal }

   uiTWidgetGlobal = record
      GridSize: oxTDimensions;

      DefaultProperties: uiTWidgetProperties;

      {dummy widget class}
      DummyWidgetClass: uiTWidgetClass;

      {target}
      Target: uiTWidgetTarget;
      TargetStack: record
         List: array[0..uiWIDGET_TARGET_STACK_MAX] of uiTWidgetTarget;
         Count: loopint;
      end;

      { some standard widget IDs }
      IDs: record
         TITLE_BUTTONS,
         OK,
         CANCEL,
         RETRY,
         ABORT,
         YES,
         NO,
         NEW,
         OPEN,
         SAVE,
         SAVEAS,
         HELP: uiTControlID;
      end;

      Create: uiTWidgetCreateData;
      LastRect: uiTWidgetLastRect;

      EventHandler: appTEventHandler;
      evh: appPEventHandler;

      { GENERAL }

         {initialize a uiTWidgetClass record}
      procedure Init(out wc: uiTWidgetClass);
      procedure Init(out wc: uiTWidgetClass; const name: string);

      { WIDGET REGISTERING }

      {registers a widget class}
      procedure RegisterClass(var wc: uiTWidgetClass);

      { WIDGET CREATION AND ADDING }

      {NOTE: When adding a widget, (0, 0) dimensions will assume automatic computation of dimensions,
      so can use Resize(0, 0) to force these dimensions}

      {creates a widget}
      function Make(const wc: uiTWidgetClass; const Pos: oxTPoint;
                  const Dim: oxTDimensions; cp: uiTWidgetControlProc = nil): uiTWidget;
      {adds a widget to a window}
      function Add(wnd: uiTWindow; const wc: uiTWidgetClass; const Pos: oxTPoint;
                           const Dim: oxTDimensions): uiTWidget;
      {adds a widget to another widget}
      function Add(wdg: uiTWidget; const wc: uiTWidgetClass; const Pos: oxTPoint;
               const Dim: oxTDimensions): uiTWidget;
      {adds a widget to the currently selected target}
      function Add(const wc: uiTWidgetClass; const Pos: oxTPoint;
                           const Dim: oxTDimensions): uiTWidget;

      { WIDGET RENDERING}

      {render all widgets in a window}
      procedure Render(const widgets: uiTWidgets; nonClient: boolean = false);
      procedure RenderNonClient(const widgets: uiTWidgets);

      { SELECTION }
      {deselect a widget within a window}
      procedure Deselect(wnd: uiTWindow);
      function Select(wnd: uiTWindow; ID: loopint): boolean;
      function SelectByPos(wnd: uiTWindow; Pos: longint): boolean;
      {select next widget}
      function SelectNext(wnd: uiTWindow): boolean;
      {select previous widget}
      function SelectPrevious(wnd: uiTWindow): boolean;

      { FINDING }
      {finds a widget within the following coordinates in a widget}
      function Find(wdg: uiTWidget; x, y: longint): uiTWidget;
      {finds a widget specified within the following coordinates in a window}
      function Find(wnd: uiTWindow; x, y: longint): uiTWidget;
      {find a widget in a window with the specified ID}
      function Find(wnd: uiTWindow; wdgID: loopint): uiTWidget;
      {returns the widgets position}
      function Pos(const s: uiTWidgets; wdg: uiTWidget): longint;

      { DISPOSING }
      {dispose of a widget pointer and it's allocated data}
      procedure Dispose(var wdg: uiTWidget);
      {dispose of widgets}
      procedure Dispose(var wdgs: uiTWidgets);
      {queues an event to dispose a widget}
      procedure DisposeQueue(wdg: uiTWidget);

      { TARGET }
      {clear target window/widget or control procedure}
      procedure ClearTarget();

      {set default target window}
      procedure SetTarget();
      {set target window or widget}
      procedure SetTarget(wnd: uiTWindow);
      {set target window/widget and control procedure}
      procedure SetTarget(wnd: uiTWindow; cp: uiTWidgetControlProc);

      {set or clear a target control procedure}
      procedure SetTargetCP(cp: uiTWidgetControlProc);
      procedure ClearTargetCP();

      procedure SetTargetFont(font: oxTFont);

      {sets default create data}
      procedure GetCreateData(out cd: uiTWidgetCreateData);

      {push target onto target stack}
      procedure PushTarget();
      {pop target off the target stack}
      procedure PopTarget();

      private
         procedure Created(wdg: uiTWidget);
   end;

   { uiTWidgetInternal }

   uiTWidgetInternal = record helper for uiTWidgetClass
      procedure Register(const name: string; initProc: TProcedure);
      procedure Done(widgetClass: uiTWidgetClassType);
      procedure Done();
   end;

VAR
   uiWidget: uiTWidgetGlobal;

{ WIDGET ID OPERATOR }
operator = (wdg: uiTWidget; var id: uiTControlID): boolean;

IMPLEMENTATION

USES
   uiuWindow;

VAR
   nWidgetTypes: longint;

{ uiTWidgetLastRect }

procedure uiTWidgetLastRect.Assign(const anotherR: oxTRect);
begin
   r := anotherR;
end;

procedure uiTWidgetLastRect.Assign(const p: oxTPoint; const d: oxTDimensions);
begin
   r.Assign(p, d);
end;

procedure uiTWidgetLastRect.Assign(wnd: uiTWindow);
begin
   r.x := wdgDEFAULT_SPACING;
   r.y := wnd.Dimensions.h - 1;
   r.w := 0;
   r.h := 0;
end;

procedure uiTWidgetLastRect.Assign(wdg: uiTControl);
begin
   r.x := wdgDEFAULT_SPACING;
   r.y := wdg.Dimensions.h - 1;
   r.w := 0;
   r.h := 0;
end;

procedure uiTWidgetLastRect.SetDefault(height: longint);
begin
   r.x := wdgDEFAULT_SPACING;
   r.y := height - 1;
   r.w := 0;
   r.h := 0;
end;

procedure uiTWidgetLastRect.GoLeft();
begin
   r.x := wdgDEFAULT_SPACING;
   r.w := 0;
end;

procedure uiTWidgetLastRect.GoBelow(spacing: loopint);
var
   offset: loopint = 0;

begin
   if(spacing = -1) then
      offset := wdgDEFAULT_SPACING
   else
      offset := spacing;

   r.y := r.y - r.h - offset;
   r.h := 0;
end;

function uiTWidgetLastRect.AboveOf(xOffset: longint; yOffset: longint; spacing: boolean): oxTPoint;
begin
   Result.x := r.x;
   Result.y := r.y + 1;

   if(spacing) then
      inc(Result.y, wdgDEFAULT_SPACING);

   inc(Result.x, xOffset);
   inc(Result.y, yOffset);
end;

function uiTWidgetLastRect.BelowOf(xOffset: longint; yOffset: longint; spacing: boolean): oxTPoint;
begin
   Result.x := r.x;
   Result.y := r.y - r.h;

   if(spacing) then
      dec(Result.y, wdgDEFAULT_SPACING);

   inc(Result.x, xOffset);
   inc(Result.y, yOffset);
end;

function uiTWidgetLastRect.RightOf(xOffset: longint; yOffset: longint;spacing: boolean): oxTPoint;
begin
   Result.x := r.x + r.w;
   Result.y := r.y;

   if(spacing) then
      inc(Result.x, wdgDEFAULT_SPACING);

   inc(Result.x, xOffset);
   inc(Result.y, yOffset);
end;

function uiTWidgetLastRect.LeftOf(xOffset: longint; yOffset: longint; spacing: boolean): oxTPoint;
begin
   Result.x := r.x - 1;
   Result.y := r.y;

   if(spacing) then
      dec(Result.x, wdgDEFAULT_SPACING);

   inc(Result.x, xOffset);
   inc(Result.y, yOffset);
end;

procedure uiTWidgetLastRect.VerticalSpacing(spacing: loopint);
begin
   if(spacing = -1) then
      dec(r.y, wdgDEFAULT_SPACING)
   else
      dec(r.y, spacing);
end;

{ GENERAL }
procedure uiTWidgetGlobal.Init(out wc: uiTWidgetClass);
begin
   wc := DummyWidgetClass;
end;

procedure uiTWidgetGlobal.Init(out wc: uiTWidgetClass; const name: string);
begin
   Init(wc);
   wc.sName := name;
end;

{ WIDGET REGISTERING }
procedure uiTWidgetGlobal.RegisterClass(var wc: uiTWidgetClass);
var
   n: longint;

begin
   assert(nWidgetTypes < oxui.nWidgetTypes, 'uiWidgets > More classes registered than reported(' + sf(oxui.nWidgetTypes) + '). While registering: ' + wc.sName);

   inc(nWidgetTypes);
   if(nWidgetTypes <= oxui.nWidgetTypes) then begin
      n := nWidgetTypes - 1;

      oxui.WidgetClasses[n] := @wc;
      oxui.WidgetClasses[n]^.cID := n;

      if(oxui.WidgetClasses[n]^.SkinDescriptor <> nil) then
         uiSkin.SetupWidget(oxui.DefaultSkin, oxui.DefaultSkin.wdgSkins[n], oxui.WidgetClasses[n]^.SkinDescriptor^);
   end;
end;

{ WIDGET CREATION AND ADDING }

function uiTWidgetGlobal.Make(const wc: uiTWidgetClass; const Pos: oxTPoint;
            const Dim: oxTDimensions; cp: uiTWidgetControlProc = nil): uiTWidget;
var
   wdg: uiTWidget = nil;

begin
   {allocate memory for the widget and initialize it}
   if(Create.Instance = nil) then
      wdg := wc.Instance.Create()
   else
      wdg := Create.Instance.Create();

   if(wdg <> nil) then begin
      assert(wdg.ControlType = uiCONTROL_WIDGET, 'Instanced a widget whose control type is not uiCONTROL_WIDGET');

      {fill in the data}
      wdg.ID         := uiControl.nilID;
      wdg.Position   := Pos;
      wdg.Dimensions := Dim;
      wdg.Properties := uiWidget.DefaultProperties;
      wdg.WdgClass   := @wc;
      wdg.WdgControl := cp;
      wdg.ZIndex     := Create.ZIndex;

      if(wdg.wdgClass^.NonSelectable) then
         Exclude(wdg.Properties, wdgpSELECTABLE);

      LastRect.Assign(Pos, Dim);

      wdg.SetFont(target.font);
   end;

   GetCreateData(Create);

   Result := wdg;
end;

function uiTWidgetGlobal.Add(wnd: uiTWindow; const wc: uiTWidgetClass; const Pos: oxTPoint;
                     const Dim: oxTDimensions): uiTWidget;
begin
   assert(wnd.Widgets.w.n <= Length(wnd.Widgets.w.List), 'Window widget count less than widget array size.');

   Result := Make(wc, Pos, Dim, target.ControlProcedure);
   if(Result <> nil) then begin
      wnd.Widgets.Insert(Result);

      if(wc.SelectOnAdd) and (wnd.Widgets.s < 0) then
         wnd.Widgets.s := wnd.Widgets.w.n - 1;

      {setup widget information}
      Result.wnd     := wnd;
      Result.Parent  := wnd;
      Result.oxwParent := wnd.oxwParent;

      Created(Result);
   end;
end;

function uiTWidgetGlobal.Add(wdg: uiTWidget; const wc: uiTWidgetClass; const Pos: oxTPoint;
         const Dim: oxTDimensions): uiTWidget;
begin
   Result := nil;
   assert(wdg.Widgets.w.n <= Length(wdg.Widgets.w.List), 'Widget sub-widget count less than sub-widget array size.');

   {add the widget to the pointer list}
   Result := Make(wc, Pos, Dim, target.ControlProcedure);
   if(Result <> nil) then begin
      wdg.Widgets.Insert(Result);

      if(wc.SelectOnAdd) and (wdg.Widgets.s < 0) then
         wdg.Widgets.s := wdg.Widgets.w.n - 1;

      {setup the sub-widget information}
      Result.wnd     := wdg.wnd;
      Result.Parent  := wdg;
      Result.oxwParent := wdg.oxwParent;

      Created(Result);
   end;
end;

function uiTWidgetGlobal.Add(const wc: uiTWidgetClass; const Pos: oxTPoint;
                     const Dim: oxTDimensions): uiTWidget;
begin
   assert((Target.Window <> nil) or (Target.Widget <> nil), 'Must set target window or widget when adding a widget.');

   if(Target.Widget <> nil) then
      Result := Add(Target.Widget, wc, Pos, Dim)
   else if(Target.Window <> nil) then
      Result := Add(Target.Window, wc, Pos, Dim)
   else
      Result := nil;
end;

procedure uiTWidgetGlobal.Render(const widgets: uiTWidgets; nonClient: boolean = false);
var
   i: longint;
   pwdg: uiTWidget;

begin
   if(widgets.w.n > 0) then begin
      for i := 0 to (widgets.z.Entries.n - 1) do begin
         pwdg := uiTWidget(widgets.z.Entries[i]);

         if(pwdg <> nil) and ((wdgpNON_CLIENT in pwdg.Properties) = nonClient) then
            pwdg.RenderAll();
      end;
   end;
end;

procedure uiTWidgetGlobal.RenderNonClient(const widgets: uiTWidgets);
begin
   Render(widgets, true);
end;

procedure uiTWidgetHelper.SetControlMethod(controlProc: uiTWidgetControlMethod);
begin
   inherited SetControl(uiTWidgetControlProc(controlProc));
end;

procedure uiTWidgetHelper.RenderAll();
var
   i: longint;

begin
   if(wdgpVISIBLE in Properties) and (Dimensions.w <> 0) and (Dimensions.h <> 0) then begin
     if(not (wdgpNON_CLIENT in Properties)) then begin
        if(Parent.RPosition.y - Parent.Dimensions.h >= RPosition.y) then
           exit;

        if(Parent.RPosition.y < RPosition.y - Dimensions.h) then
           exit;

        uiDraw.Scissor(RPosition.x, RPosition.y, Dimensions.w, Dimensions.h);
     end;

     Render();

     {render any sub widgets}
     for i := 0 to (widgets.z.Entries.n - 1) do
        if(widgets.z.Entries[i] <> nil) then
           uiTWidget(widgets.z.Entries[i]).RenderAll();

     if(not (wdgpNON_CLIENT in Properties)) then
        uiDraw.DoneScissor();
   end;
end;

procedure uiTWidgetHelper.Select();
begin
   oxui.Select.Assign(uiTControl(self));
   Action(uiwdgACTION_ACTIVATE);
   OnActivate();
end;

procedure uiTWidgetHelper.SelectQueue();
var
   ev: appTEvent;

begin
   appEvents.Init(ev, wdgevSELECT, uiWidget.evh);
   ev.wnd := Self.wnd;
   ev.ExternalData := Self;
   appEvents.Queue(ev);
end;

procedure uiTWidgetHelper.Deselected();
var
   pos: longint;
   w: uiPWidgets;

begin
   w := GetWidgetsContainer();

   if(w <> nil) then begin
      pos := uiWidget.Pos(w^, self);

      if(pos = w^.s) then
         w^.s := -1;
   end;

   oxui.Select.Deselect(Self);

   {perform actions if we're not disposing of the widget}
   if(not (wdgpDESTROY_IN_PROGRESS in Properties)) then begin
      {notify the widget it lost focus, if it was selected}
      Action(uiwdgACTION_DEACTIVATE);
      OnDeactivate();
   end;
end;

function uiTWidgetHelper.IsSelected(): boolean;
begin
   Result := (oxui.Select.l >= Level) and (oxui.Select.s[Level] = Self);
end;

function uiTWidgetHelper.Hovering(): boolean;
begin
   Result := wdgpHOVERING in  Properties;
end;

procedure uiTWidgetGlobal.Deselect(wnd: uiTWindow);
var
   pwdg: uiTWidget;

begin
   {set the previous widget properties to indicate not selected}
   if(wnd.Widgets.s < wnd.Widgets.w.n) and (wnd.Widgets.s > -1) then begin
      pwdg := uiTWidget(wnd.Widgets.w[wnd.Widgets.s]);

      if(pwdg <> nil) then
         pwdg.Deselected();
   end;
end;

function uiTWidgetGlobal.Select(wnd: uiTWindow; ID: loopint): boolean;
var
   i: longint;
   wdg: uiTWidget = nil;

begin
   Result := false;

   {find the widget}
   if(wnd.Widgets.w.n > 0) then
      for i := 0 to (wnd.Widgets.w.n - 1) do begin
         wdg := uiTWidget(wnd.Widgets.w[i]);

         if(wdg.ID.ID = ID) then begin
            {first deselect whatever previous widget was selected}
            oxui.Select.Deselect();

            {select the new widget}
            wdg.Select();

            {done}
            exit(true);
         end;
      end;
end;

function uiTWidgetGlobal.SelectByPos(wnd: uiTWindow; Pos: longint): boolean;
begin
   if(wnd.Widgets.w.n > Pos) and (Pos > -1) then begin
      uiTwidget(wnd.Widgets.w[Pos]).Select();
      Result := true;
   end else
      Result := false;
end;

function uiTWidgetGlobal.SelectNext(wnd: uiTWindow): boolean;
var
   s,
   i: longint;

label
   redo;

begin
   Result := false;

   if(wnd.Widgets.w.n > 0) then begin
      if(wnd.Widgets.s < 0) or (wnd.Widgets.s >= wnd.Widgets.w.n) then begin
         Result := true;
         wnd.Widgets.s := 0;
      end;

      s := wnd.Widgets.s;
      i := s;

      repeat
      redo:
         inc(i);

         if(i > wnd.Widgets.w.n - 1) then
            i := 0;

         if(not (wdgpSELECTABLE in uiTWidget(wnd.Widgets.w[i]).Properties)) then begin
            if(i = s) then
               break;

            goto redo;
         end;
      until (i = s) or (i <> s);

      if(i <> s) then begin
         SelectByPos(wnd, i);
         Result := true;
      end;
   end;
end;

function uiTWidgetGlobal.SelectPrevious(wnd: uiTWindow): boolean;
var
   i,
   s: longint;

label
   redo;

begin
   Result := false;

   if(wnd.Widgets.w.n > 0) then begin
      if(wnd.Widgets.s < 0) or (wnd.Widgets.s >= wnd.Widgets.w.n) then begin
         Result := true;
         wnd.Widgets.s  := 0;
      end;

      s := wnd.Widgets.s;
      i := s;

      repeat
      redo:
         dec(i);

         if(i < 0) then
            i := (wnd.Widgets.w.n - 1);

         if(not (wdgpSELECTABLE in uiTWidget(wnd.Widgets.w[i]).Properties)) then begin
            if(i = s) then
               break;

            goto redo;
         end;
      until (i = s) or (i <> s);

      if(i <> s) then begin
         SelectByPos(wnd, i);
         Result := true;
      end;
   end;

end;

{ FINDING }

function uiTWidgetGlobal.Find(wdg: uiTWidget; x, y: longint): uiTWidget;
var
   i: longint;
   pwdg: uiTWidget;
   rect: oxTRect;

begin
   Result := wdg;

   if(wdg.Widgets.z.Entries.n > 0) then
   for i := (wdg.Widgets.z.Entries.n - 1) downto 0 do begin
      pwdg   := uiTWidget(wdg.Widgets.z.Entries[i]);
      rect.x := pwdg.Position.x;
      rect.y := pwdg.Position.y;
      rect.w := pwdg.Dimensions.w;
      rect.h := pwdg.Dimensions.h;

      if(rect.Inside(x, y)) then begin
         Result := Find(pwdg, x - pwdg.Position.x, y - pwdg.Position.y);
         break;
      end;
   end;
end;

function uiTWidgetGlobal.Find(wnd: uiTWindow; x, y: longint): uiTWidget;
var
   i: longint;
   pwdg: uiTWidget;
   rect: oxTRect;

begin
   Result := nil;

   if(wnd.Widgets.w.n > 0) then begin
      for i := (wnd.Widgets.z.Entries.n - 1) downto 0 do begin
         pwdg   := uiTWidget(wnd.Widgets.z.Entries[i]);
         rect.x := pwdg.Position.x;
         rect.y := pwdg.Position.y;
         rect.w := pwdg.Dimensions.w;
         rect.h := pwdg.Dimensions.h;

         if(rect.Inside(x, y)) then
            exit(Find(pwdg, x - pwdg.Position.x, y + pwdg.Position.y));
      end;
   end;
end;

function uiTWidgetGlobal.Find(wnd: uiTWindow; wdgID: loopint): uiTWidget;
var
   i: longint;
   wdg: uiTWidget;

begin
   Result := nil;

   if(wnd.Widgets.w.n > 0) then begin
      for i := 0 to (wnd.Widgets.w.n - 1) do begin
         wdg := uiTWidget(wnd.Widgets.w[i]);

         if(wdg <> nil) and (wdg.ID.ID = wdgID) then
            exit(wdg);
      end;
   end;
end;

function uiTWidgetGlobal.Pos(const s: uiTWidgets; wdg: uiTWidget): longint;
var
   i: longint;

begin
   Result := -1;

   if(s.w.n > 0) then begin
      for i := 0 to (s.w.n - 1) do begin
         if(s.w.List[i] = wdg) then
            exit(i);
      end;
   end;
end;

{ POSITION AND SIZE }
procedure WidgetMoveAction(var wdg: uiTWidget);
begin
   wdg.Action(uiwdgACTION_MOVE);
end;

procedure WidgetResizeAction(var wdg: uiTWidget);
begin
   wdg.Action(uiwdgACTION_RESIZE);
end;


function uiTWidgetHelper.SetPosition(Properties: TBitSet; Separation: boolean): uiTWidget;
var
   p,
   parentP: oxTPoint;
   pRect,
   sRect: oxTRect;
   gridSize: oxTDimensions;

   horizontalChange,
   verticalChange,
   {previous value for DimensionsSet (restored after we're done)}
   pDimensionsSet: boolean;

begin
   p := Position;
   pDimensionsSet := DimensionsSet;

   if(Separation) then
      gridSize := uiWidget.GridSize
   else
      gridSize := oxNullDimensions;

   {position widget horizontally}
   horizontalChange := true;

   if(Properties.IsSet(wdgPOSITION_HORIZONTAL_LEFT)) then
      p.x := gridSize.w
   else if(Properties.IsSet(wdgPOSITION_HORIZONTAL_RIGHT)) then
      p.x := Parent.Dimensions.w - 1 - (gridSize.w + Dimensions.w)
   else if(Properties.IsSet(wdgPOSITION_HORIZONTAL_CENTER)) then
      p.x := (Parent.Dimensions.w div 2) - (Dimensions.w div 2) - 1
   else
      horizontalChange := false;

   {position widget vertically}
   verticalChange := true;

   if(Properties.IsSet(wdgPOSITION_VERTICAL_TOP)) then
      p.y := Parent.Dimensions.h - 1 - gridSize.h
   else if(Properties.IsSet(wdgPOSITION_VERTICAL_BOTTOM)) then
      p.y := gridSize.h + Dimensions.h - 1
   else if(Properties.IsSet(wdgPOSITION_VERTICAL_CENTER)) then
      p.y := (Parent.Dimensions.h div 2) + (Dimensions.h div 2) - 1
   else
      verticalChange := false;

   parentP.x := 0;
   parentP.y := Parent.Dimensions.h - 1;

   pRect.Assign(parentP, Parent.Dimensions);
   sRect.Assign(p, Dimensions);

   if(not Properties.IsSet(wdgPOSITION_RESIZE)) then
      pRect.PositionInside(sRect)
   else
      pRect.FitInside(sRect);

   if(sRect.y < 0) then
      sRect.y := 0;

   if(not horizontalChange) then begin
      sRect.x := Position.x;
      sRect.w := Dimensions.w;
   end;

   if(not verticalChange) then begin
      sRect.y := Position.y;
      sRect.h := Dimensions.h;
   end;

   if(sRect.x <> Position.x) or (sRect.y <> Position.y) then
      Move(sRect.x, sRect.y);

   if(sRect.w <> Dimensions.w) or (sRect.h <> Dimensions.h) then
      Resize(sRect.w, sRect.h);

   DimensionsSet := pDimensionsSet;

   Result := Self;
end;

function uiTWidgetHelper.CenterVertically(): uiTWidget;
begin
   SetPosition(wdgPOSITION_VERTICAL_CENTER);

   Result := Self;
end;

function uiTWidgetHelper.CenterHorizontally(): uiTWidget;
begin
   SetPosition(wdgPOSITION_HORIZONTAL_CENTER);

   Result := Self;
end;

function uiTWidgetHelper.SetSize(Properties: TBitSet): uiTWidget;
var
   p,
   d: longint;

begin
   {set maximum horizontal width for widget}
   if(Properties.IsSet(wdgWIDTH_MAX_HORIZONTAL)) then begin
      p := Position.x;
      d := Parent.Dimensions.w - (p + Dimensions.w) - uiWidget.GridSize.w;

      if(d > 0) then
         Resize(Dimensions.w + d, Dimensions.h);
   end;

   {set maximum vertical width for widget}
   if(Properties.IsSet(wdgHEIGHT_MAX_VERTICAL)) then begin
      p := Position.y;
      d := Parent.Dimensions.h - (p + Dimensions.h) - uiWidget.GridSize.h;

      if(d > 0) then
         Resize(Dimensions.w, Dimensions.h + d);
   end;

   Result := Self;
end;

function uiTWidgetHelper.SetSizePosition(sizeProperties, positionProperties: TBitSet): uiTWidget;
begin
   SetSize(sizeProperties);
   SetPosition(positionProperties);

   Result := Self;
end;

procedure uiTWidgetHelper.AutoSize();
begin
   if(not DimensionsSet) then begin
      AutoSetWidgetDimensions();

      uiWidget.LastRect.Assign(Position, Dimensions);
   end;
end;

{ DISPOSING }
procedure uiTWidgetHelper.Dispose();
begin
   if(wdgpDESTROY_IN_PROGRESS in Properties) then
      exit;

   Include(Properties, wdgpDESTROY_IN_PROGRESS);

   {dispose sub-widgets, if any}
   uiWidget.Dispose(Widgets);

   {remove any other pending events for this widget}
   appEvents.DisableWithData(Self);

   Deselected();
   oxui.mSelect.Deselect(Self);

   {de-initialize the widget}
   DeInitialize();

   {remove it from the parents Z order}
   GetWidgetsContainer()^.Remove(self);
end;

procedure uiTWidgetHelper.DisposeSubWidgets();
begin
   uiWidget.Dispose(Widgets);
end;

procedure uiTWidgetGlobal.Dispose(var wdg: uiTWidget);
begin
   if(wdg <> nil) then begin
      {done}
      wdg.Dispose();

      FreeObject(wdg);
   end;
end;

{dispose of widgets}
procedure uiTWidgetGlobal.Dispose(var wdgs: uiTWidgets);
var
   current: uiTWidget;

begin
   assert(wdgs.w.n <= Length(wdgs.w.List), 'Sub-window count not equal to sub-window array size.');

   if(wdgs.w.n > 0) then begin
      current := uiTWidget(wdgs.w[0]);
      uiWidget.Dispose(current);

      Dispose(wdgs);
   end else
      wdgs.w.Dispose();
end;

procedure uiTWidgetGlobal.DisposeQueue(wdg: uiTWidget);
var
   ev: appTEvent;

begin
   if(wdg <> nil) then begin
      appEvents.Init(ev, wdgevDISPOSE, evh);
      ev.wnd := wdg.wnd;
      ev.ExternalData := wdg;
      appEvents.Queue(ev);
   end;
end;

{ MODIFICATION }

{visible property}
procedure uiTWidgetHelper.Show();
begin
   Include(Properties, wdgpVISIBLE);
end;

procedure uiTWidgetHelper.Hide();
begin
   Exclude(Properties, wdgpVISIBLE);
   Deselected();
end;

procedure InitDummyWidgetClass();
begin
   ZeroOut(uiWidget.DummyWidgetClass, SizeOf(uiTWidgetClass));

   uiWidget.DummyWidgetClass.sName        := 'wdgDUMMY';
   uiWidget.DummyWidgetClass.SelectOnAdd  := true;
   uiWidget.DummyWidgetClass.Instance := uiTWidget;
   uiWidget.DummyWidgetClass.SkinDescriptor := nil;
end;

{event handler}
procedure eventAction(var event: appTEvent);
begin
   if(event.evID = wdgevDISPOSE) then begin
      uiWidget.Dispose(uiTWidget(event.ExternalData));
   end else if(event.evID = wdgevSELECT) then begin
      uiTWidget(event.ExternalData).Select();
   end;
end;

{automatically select a newly created window as a target}
procedure onwndCreateSetTarget(wnd: uiTWindow);
begin
   uiWidget.SetTarget(wnd);
end;


{initializes widgets}
procedure InitWidgets();
begin
   { standard widget IDs }
   with uiWidget.IDs do begin
      TITLE_BUTTONS        := uiControl.GetID('ui.titlebuttons');
      OK                   := uiControl.GetID('Ok');
      CANCEL               := uiControl.GetID('Cancel');
      RETRY                := uiControl.GetID('Retry');
      ABORT                := uiControl.GetID('Abort');
      YES                  := uiControl.GetID('Yes');
      NO                   := uiControl.GetID('No');

      NEW                  := uiControl.GetID('New');
      OPEN                 := uiControl.GetID('Open');
      SAVE                 := uiControl.GetID('Save');
      SAVEAS               := uiControl.GetID('SaveAs');

      HELP                 := uiControl.GetID('Help');
   end;

   uiWidget.GridSize.w := 5;
   uiWidget.GridSize.h := 5;
   uiWidget.DefaultProperties := [wdgpENABLED, wdgpVISIBLE, wdgpSELECTABLE];

   uiWindow.OnCreate.Add(@onwndCreateSetTarget);
   uiWidget.GetCreateData(uiWidget.Create);

   if(oxui.nWidgetTypes > 0) then begin
      {allocate memory for widget classes}
      try
         SetLength(oxui.WidgetClasses, oxui.nWidgetTypes);
      except
         {eNO_MEMORY}
         exit;
      end;

      ZeroOut(oxui.WidgetClasses[0], int64(oxui.nWidgetTypes) * int64(SizeOf(uiPWidgetClass)));
   end;
end;

{de-initializes widgets}
procedure DeInitWidgets();
begin
   {dispose of widget class and renderer pointer memory}
   SetLength(oxui.WidgetClasses, 0);
   oxui.WidgetClasses := nil;

   nWidgetTypes := 0;
end;

{ TARGET }
procedure uiTWidgetGlobal.ClearTarget();
begin
   target.Window := nil;
   target.Widget := nil;
   target.Font := nil;

   ClearTargetCP();
end;

procedure uiTWidgetGlobal.SetTarget();
begin
   ClearTarget();
   target.Window := oxWindow.Current;
end;

procedure uiTWidgetGlobal.SetTarget(wnd: uiTWindow);
begin
   ClearTarget();
   target.Window := wnd;

   LastRect.SetDefault(wnd.Dimensions.h);
end;

procedure uiTWidgetGlobal.SetTargetCP(cp: uiTWidgetControlProc);
begin
   target.ControlProcedure := cp;
end;

procedure uiTWidgetGlobal.ClearTargetCP();
begin
   target.ControlProcedure := nil;
end;

procedure uiTWidgetGlobal.SetTargetFont(font: oxTFont);
begin
   target.font := font;
end;

procedure uiTWidgetGlobal.GetCreateData(out cd: uiTWidgetCreateData);
begin
   cd.Instance := nil;
   cd.ZIndex := 0;
end;

procedure uiTWidgetGlobal.PushTarget();
begin
   assert(TargetStack.Count < uiWIDGET_TARGET_STACK_COUNT, 'Widget target stack reached maximum capacity');

   TargetStack.List[TargetStack.Count] := Target;
   inc(TargetStack.Count);
end;

procedure uiTWidgetGlobal.PopTarget();
begin
   assert(TargetStack.Count > 0, 'Attempted to pop widget target stack when nothing pushed');

   dec(TargetStack.Count);
   Target := TargetStack.List[TargetStack.Count];
end;

procedure uiTWidgetGlobal.SetTarget(wnd: uiTWindow; cp: uiTWidgetControlProc);
begin
   SetTarget(wnd);
   SetTargetCP(cp);
end;

{ uiTWidgetHelper }

procedure uiTWidgetHelper.SetTarget(cp: uiTWidgetControlProc);
begin
   uiWidget.ClearTarget();

   uiWidget.Target.Window := uiTWindow(Self.wnd);
   uiWidget.Target.Widget := Self;
   uiWidget.Target.ControlProcedure := cp;

   uiWidget.LastRect.Assign(Self);
end;


{ SKIN }

function uiTWidgetHelper.GetSkin(): uiPWidgetSkin;
var
   pSkin: uiTSkin;

begin
   Result := nil;

   if(skin <> nil) then
      Result := Skin
   else begin
      pSkin :=  GetSkinObject();

      if(pSkin <> nil) then
         Result := pSkin.Get(wdgClass^.cID);
   end;
end;

function uiTWidgetHelper.GetSkinObject(): uiTSkin;
begin
   Result := nil;

   if(uiTWindow(wnd).Skin <> nil) then
      Result := uiTSkin(uiTWindow(wnd).Skin);

   if(Result = nil) then
      Result := oxui.DefaultSkin;
end;

function uiTWidgetHelper.GetColor(clrIdx: longint): TColor4ub;
begin
   if(Skin <> nil) then begin
      if(Skin^.Colors <> nil) then
         exit(Skin^.Colors[clrIdx]);
   end;

   exit(cWhite4ub);
end;

procedure uiTWidgetHelper.SetColor(clrIdx: longint);
begin
   SetColor(GetColor(clrIdx));
end;

procedure uiTWidgetHelper.SetColorBlended(clrIdx: longint);
begin
   SetColorBlended(GetColor(clrIdx));
end;

procedure uiTWidgetHelper.SetColor(color: TColor4ub);
begin
   if(not (wdgpENABLED in Properties)) then
      color := color.Darken(0.25);

   uiTWindow(wnd).SetColor(color);
end;

procedure uiTWidgetHelper.SetColorBlended(color: TColor4ub);
begin
   if(not (wdgpENABLED in Properties)) then
      color := color.Darken(0.25);

   uiTWindow(wnd).SetColorBlended(color);
end;

procedure uiTWidgetHelper.SetColorEnabled(color, disabledColor: TColor4ub);
begin
   if(wdgpENABLED in Properties) then
      uiTWindow(wnd).SetColor(color)
   else
      uiTWindow(wnd).SetColor(disabledColor);
end;

procedure uiTWidgetHelper.SetColorBlendedEnabled(color, disabledColor: TColor4ub);
begin
   if(wdgpENABLED in Properties) then
      uiTWindow(wnd).SetColorBlended(color)
   else
      uiTWindow(wnd).SetColorBlended(disabledColor);
end;

procedure uiTWidgetHelper.LockPointer();
begin
   LockPointer(0, 0);
end;

procedure uiTWidgetHelper.LockPointer(x, y: single);
begin
   if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_NONE) then begin
      oxui.PointerCapture.Typ := uiPOINTER_CAPTURE_WIDGET;
      oxui.PointerCapture.Wdg := Self;
      oxui.PointerCapture.Point.Assign(x, y);
   end;
end;

procedure uiTWidgetHelper.UnlockPointer();
begin
   if(oxui.PointerCapture.Typ = uiPOINTER_CAPTURE_WIDGET) then begin
      oxui.PointerCapture.Clear();
   end;
end;

function uiTWidgetHelper.Exists(const wdg: uiTWidget): longint;
begin
   Result := Widgets.Exists(wdg);
end;

function uiTWidgetHelper.Move(x, y: longint): uiTWidget;
begin
   if(Position.x <> x) or (Position.y <> y) then begin
      Position.x := x;
      Position.y := y;

      PositionUpdate();
      PositionChanged();
   end;

   uiWidget.LastRect.Assign(Position, Dimensions);
   Result := Self;
end;

function uiTWidgetHelper.Move(const p: oxTPoint): uiTWidget;
begin
   Result := Move(p.x, p.y);
end;

function uiTWidgetHelper.MoveOffset(x, y: loopint): uiTWidget;
begin
   Result := Move(Position.x + x, Position.y + y);
end;

function uiTWidgetHelper.MoveBelow(wdg: uiTWidget; spacing: longint): uiTWidget;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Move(Position.x, wdg.Position.y - wdg.Dimensions.h - spacing);
end;

function uiTWidgetHelper.MoveAbove(wdg: uiTWidget; spacing: longint): uiTWidget;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Move(Position.x, wdg.Position.y + wdg.Dimensions.h + spacing);
end;

function uiTWidgetHelper.MoveLeftOf(wdg: uiTWidget; spacing: longint): uiTWidget;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Move(wdg.Position.x - Dimensions.w - spacing, Position.y);
end;

function uiTWidgetHelper.MoveRightOf(wdg: uiTWidget; spacing: longint): uiTWidget;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Result := Move(wdg.Position.x + wdg.Dimensions.w + spacing, Position.y);
end;

function uiTWidgetHelper.MoveRightmost(spacing: longint): uiTWidget;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Move(Parent.Dimensions.w - 1 - Dimensions.w - spacing, Position.y);
   Result := Self;
end;

function uiTWidgetHelper.MoveLeftmost(spacing: longint): uiTWidget;
begin
   if(spacing = -1) then
      spacing := wdgDEFAULT_SPACING;

   Move(0 + spacing, Position.y);
   Result := Self;
end;

function uiTWidgetHelper.Resize(w, h: longint): uiTWidget;
begin
   if(w <> Dimensions.w) or (h <> Dimensions.h) then begin
      PreviousDimensions := Dimensions;

      Dimensions.w := w;
      Dimensions.h := h;

      DimensionsSet := true;

      SizeChanged();
      UpdateParentSize(false);
   end;

   uiWidget.LastRect.Assign(Position, Dimensions);
   Result := Self;
end;

function uiTWidgetHelper.ResizeWidth(w: longint): uiTWidget;
begin
   Result := Resize(w, Dimensions.h);
end;

function uiTWidgetHelper.ResizeHeight(h: longint): uiTWidget;
begin
   Result := Resize(Dimensions.w, h);
end;

function uiTWidgetHelper.Resize(const d: oxTDimensions): uiTWidget;
begin
   Result := Resize(d.w, d.h);
end;

function uiTWidgetHelper.ResizeComputed(): uiTWidget;
var
   computed: oxTDimensions;

begin
   GetComputedDimensions(computed);
   Resize(computed.w, computed.h);
   DimensionsSet := false;
   Result := self;
end;

procedure uiTWidgetHelper.AutoSetWidgetDimensions(force: boolean);
var
   d: oxTDimensions;

begin
   if(force) then
      DimensionsSet := false;

   if(not DimensionsSet) then begin
      GetComputedDimensions(d);

      Resize(d.w, d.h);
   end;
end;

procedure uiTWidgetHelper.FillWindow();
begin
   Move(0, wnd.Dimensions.h - 1);
   Resize(wnd.Dimensions.w, wnd.Dimensions.h);
end;

procedure uiTWidgetGlobal.Created(wdg: uiTWidget);
begin
   wdg.Level := wdg.Parent.Level + 1;

   if(wdg.Skin = nil) then
      wdg.Skin := wdg.GetSkin();

   if(wdg.Dimensions.w <> 0) or (wdg.Dimensions.h <> 0) then
      wdg.DimensionsSet := true;

   {update the position}
   wdg.PositionUpdate();

   {initialize the widget}
   wdg.Initialize();
end;

{ uiTWidgetInternal }

procedure uiTWidgetInternal.Register(const name: string; initProc: TProcedure);
begin
   uiWidget.Init(self, CopyAfter(name, '.'));

   if(initProc <> nil) then begin
      oxui.BaseInitializationProcs.iAdd(InitRoutines, name, initProc);
   end;

   inc(oxui.nWidgetTypes);
end;

procedure uiTWidgetInternal.Done(widgetClass: uiTWidgetClassType);
begin
   Self.Instance := widgetClass;
   Done();
end;

procedure uiTWidgetInternal.Done();
begin
   uiWidget.RegisterClass(self);
end;

{ WIDGET ID OPERATORS }

operator = (wdg: uiTWidget; var id: uiTControlID): boolean;
begin
   Result := (wdg <> nil) and (wdg.ID.ID = id.ID);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   uiWidget.evh := appEvents.AddHandler(uiWidget.EventHandler, 'ox.widget', @eventAction);

   oxui.BaseInitializationProcs.Add(initRoutines, 'widgets', @InitWidgets, @DeInitWidgets);
   InitDummyWidgetClass();

END.
