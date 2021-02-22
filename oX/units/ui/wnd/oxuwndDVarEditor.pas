{
   oxuwndDvarEditor, dvar editor window
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndDVarEditor;

INTERFACE

USES
   uStd, udvars,
   {app}
   appuMouse,
   {oX}
   uOX, oxuTypes, oxuRunRoutines, oxuwndBase,
   {ui}
   uiuControl, uiuWindow, uiWidgets, uiuWidget, uiuInputBoxOverlay,
   {widgets}
   wdguButton, wdguDivisor, wdguInputBox, wdguGrid;

TYPE
   oxPDVarEditorPointer = ^oxTDVarEditorPointer;
   oxTDVarEditorPointer = record
      Path: string;
      Group: PDVarGroup;
      Variable: PDVar;
   end;

   oxTDVarEditorPointers = specialize TSimpleList<oxTDVarEditorPointer>;

   { oxwdgTDVarEditorGrid }

   oxwdgTDVarEditorGrid = class(wdgTStringGrid)
      Vars: oxTDVarEditorPointers;

      constructor Create(); override;

      function GetValue(index, column: loopint): StdString; override;
      function GetItemCount(): loopint; override;

      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;

      procedure Reload();
   end;

   { oxuiTDVarEditorWindow }

   oxuiTDVarEditorWindow = class(oxuiTWindowBase)
      procedure SizeChanged(); override;
   end;

   oxPDVarEditorWindow = ^oxTDVarEditorWindow;

   { oxTDVarEditorWindow }

   oxTDVarEditorWindow = object(oxTWindowBase)
      wdg: record
         Divisor: wdgTDivisor;
         Close: wdgTButton;
         Filter: wdgTInputBox;
         Vars: oxwdgTDVarEditorGrid;
      end;

      constructor Create();

      protected
      procedure CreateWindow(); virtual;
      procedure AddWidgets(); virtual;

      protected
      procedure Resized();
      procedure WindowDestroyed({%H-}wnd: oxuiTWindowBase); virtual;
   end;

VAR
   oxwndDVarEditor: oxTDVarEditorWindow;

IMPLEMENTATION

TYPE
   { oxwdgTChangeValue }

   oxwdgTChangeValue = class(wdgTInputBoxOverlay)
      pointedDvar: PDVar;

      procedure Confirmed(); override;
      procedure OnInvisible(); override;
   end;

procedure oxwdgTChangeValue.Confirmed();
begin
   pointedDvar^.AssignFromString(GetText());
end;

procedure oxwdgTChangeValue.OnInvisible();
var
   bwnd: oxPDVarEditorWindow;

begin
   inherited;

   bwnd := oxuiTDVarEditorWindow(wnd).BaseHandler;

   if(bwnd <> nil) and (bwnd^.wdg.Vars <> nil) then
      oxTDVarEditorWindow(oxuiTDVarEditorWindow(wnd).BaseHandler^).wdg.Vars.SelectQueue();
end;


{ oxwdgTDVarEditorGrid }

constructor oxwdgTDVarEditorGrid.Create();
begin
   inherited Create;

   Vars.InitializeValues(Vars, 512);
end;

function oxwdgTDVarEditorGrid.GetValue(index, column: loopint): StdString;
var
   p: oxPDVarEditorPointer;

begin
   Result := '';

   if(index >= Vars.n) then
      exit('Unknown');

   p :=  @Vars.List[index];

   if(column = 0) then
      Result := p^.Path
   else if(column = 1) then
      Result := p^.Variable^.GetAsString();
end;

function oxwdgTDVarEditorGrid.GetItemCount(): loopint;
begin
   Result := Vars.n;
end;

procedure oxwdgTDVarEditorGrid.ItemClicked(index: loopint;  button: TBitSet);
var
   p: oxTPoint;
   wdg: oxwdgTChangeValue;
   pv: PDVar;

begin
   inherited ItemClicked(index, button);

   if(button = appmcLEFT) then begin
      if(index < 0) then
         exit;

      pv := Vars.List[SelectedItem].Variable;

      if(dvarREADONLY in pv^.Properties) then
         exit();

      p := oxNullPoint;
      p.y := Dimensions.h - GetItemVerticalOffset(SelectedItem);

      uiInputBoxOverlay.Instance := oxwdgTChangeValue;
      uiInputBoxOverlay.Show(Self, p);
      wdg := oxwdgTChangeValue(uiInputBoxOverlay.Wdg);
      wdg.pointedDvar := pv;
      wdg.SetText(wdg.pointedDvar^.GetAsString());

      uiInputBoxOverlay.Wdg.Resize(Dimensions.w, uiInputBoxOverlay.Wdg.Dimensions.h);
   end;
end;

procedure LoadVars(var vars: oxTDVarEditorPointers; var group: TDVarGroup; const parentPath: StdString);
var
   current: PDVar;
   currentGroup: PDVarGroup;

   v: oxTDVarEditorPointer;

begin
   v.Group := @group;

   { load variables }

   current := group.vs;

   if(current <> nil) then repeat
      v.Variable := current;

      if(parentPath <> '') then
         v.Path := parentPath + '.' + v.Variable^.Name
      else
         v.Path := v.Variable^.Name;

      vars.Add(v);

      current := current^.Next;
   until (current = nil);

   { load groups }

   currentGroup := group.sub.s;

   if(currentGroup <> nil) then repeat
      if(parentPath <> '') then
         LoadVars(vars, currentGroup^, parentPath + '.' + currentGroup^.Name)
      else
         LoadVars(vars, currentGroup^, currentGroup^.Name);

      currentGroup := currentGroup^.Next;
   until (currentGroup = nil);
end;

procedure LoadVarsRoot(var vars: oxTDVarEditorPointers; var root: TDVarGroup);
var
   currentGroup: PDVarGroup;

begin
   currentGroup := root.sub.s;
   if(currentGroup <> nil) then repeat
      LoadVars(vars, currentGroup^, currentGroup^.Name);

      currentGroup := currentGroup^.Next;
   until (currentGroup = nil);
end;

procedure oxwdgTDVarEditorGrid.Reload();
begin
   Vars.Dispose();

   Vars.Allocate(dvar.GetVariableCountRecursive());
   LoadVars(Vars, dvar.dvars, '');

   Assigned();
end;

{ oxuiTDVarEditorWindow }

procedure oxuiTDVarEditorWindow.SizeChanged();
begin
   inherited SizeChanged();

   if(BaseHandler <> nil) then
      oxTDVarEditorWindow(BaseHandler^).Resized();
end;

procedure oxTDVarEditorWindow.AddWidgets();
begin
   wdg.Close := wdgButton.Add('Close', oxNullPoint, oxNullDimensions, @Close);

   wdg.Divisor := wdgDivisor.Add('');

   wdg.Filter := wdgInputBox.Add('');
   wdg.Filter.SetPlaceholder('Filter');

   uiWidget.Create.Instance := oxwdgTDVarEditorGrid;
   wdg.Vars := oxwdgTDVarEditorGrid(wdgGrid.Add());
   wdg.Vars.AddColumn('Name')^.Ratio := 0.3;
   wdg.Vars.AddColumn('Value');
   wdg.Vars.Selectable := true;

   Resized();

   wdg.Vars.Reload();
end;

procedure oxTDVarEditorWindow.Resized();
begin
   wdg.Close.SetPosition(wdgPOSITION_HORIZONTAL_RIGHT or wdgPOSITION_VERTICAL_BOTTOM);

   wdg.Divisor.Move(5, wdg.Close.AboveOf());

   wdg.Filter.SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_TOP);
   wdg.Filter.Resize(wdg.Filter.MaximumWidth(), wdg.Filter.Dimensions.h);

   wdg.Vars.Move(wdgDEFAULT_SPACING, wdg.Filter.BelowOf());
   wdg.Vars.Resize(wdg.Vars.MaximumWidth(), wdg.Vars.Position.y - wdg.Divisor.Position.y);
end;

procedure oxTDVarEditorWindow.WindowDestroyed(wnd: oxuiTWindowBase);
begin
   ZeroPtr(@wdg, SizeOf(wdg));
end;

constructor oxTDVarEditorWindow.Create();
begin
   ID := uiControl.GetID('ox.dvar_editor');
   Width := 480;
   Height := 360;
   Title := 'DVar Editor';
   Instance := oxuiTDVarEditorWindow;

   {$IFDEF OX_FEATURE_CONSOLE}
   ConsoleOpenCommand := 'wnd:dvar_editor';
   {$ENDIF}

   inherited Create;
end;

procedure oxTDVarEditorWindow.CreateWindow();
begin
   inherited;
end;

procedure Initialize();
begin
   oxwndDVarEditor.Create();
end;

procedure deinitialize();
begin
   oxwndDVarEditor.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.wnd.dvar_edit', @initialize, @deinitialize);

END.
