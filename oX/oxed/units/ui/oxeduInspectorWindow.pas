{
   oxeduInspectorWindow, oxed inspector window
   Copyright (C) 2017. Dejan Boras

   Started On:    04.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduInspectorWindow;

INTERFACE

   USES
      uStd, uColors, uLog,
      {app}
      appuMouse,
      {ox}
      oxuTypes, oxuRunRoutines,
      oxuRender, oxuRenderer, oxuTimer,
      {ui}
      uiuTypes, uiuWindow, uiWidgets, uiuWidget, uiuWindowTypes,
      wdguLabel, wdguWorkbar, wdguCheckbox, wdguInputBox, wdguGroup, wdguDivisor,
      {oxed}
      uOXED, oxeduSettings, oxeduWindow, oxeduMenubar, oxeduProjectManagement, oxeduProjectRunner;

TYPE
   oxedTInspectorWindowTransformWidgets = record
      Lbl: wdgTLabel;
      X, Y, Z: wdgTInputBox;
   end;

   oxedTInspectorWindowGroup = record
      Separator: wdgTDivisor;
      Wdg: wdgTGroup;
   end;

   oxedTInspectorWindowGroupWidgets = specialize TSimpleList<oxedTInspectorWindowGroup>;

   { oxedTInspector }

   oxedTInspector = class
      procedure Open({%H-}wnd: oxedTWindow); virtual;
      procedure Close({%H-}wnd: oxedTWindow); virtual;
      procedure SizeChanged({%H-}wnd: oxedTWindow); virtual;
      {called each cycle on update}
      procedure Update({%H-}wnd: oxedTWindow); virtual;
   end;

   oxedTInspectorClass = class of oxedTInspector;

   { oxedTInspectorWindow }

   oxedTInspectorWindow = class(oxedTWindow)
      wdg: record
         Header: wdgTWorkbar;
         Groups: oxedTInspectorWindowGroupWidgets;
      end;

      CurrentInspector: oxedTInspector;

      procedure Initialize; override;

      function AddGroup(const caption: StdString): oxedTInspectorWindowGroup;
      procedure SizeGroups();
      procedure SetGroupWidths();

      procedure SizeChanged(initial: boolean);
      procedure SizeChanged(); override;

      procedure Open(inspector: oxedTInspector);
      procedure Close();

      procedure Update(); override;
   end;

   { oxedTInspectorEdit }

   oxedTInspectorEdit = class(oxedTWindowClass)
      constructor Create(const sName: StdString; InstanceType: oxedTUIWindowClass); override;
      {return the current inspector if there is a window and the class matches the given one}
      function GetInspector(inspectorType: oxedTInspectorClass): oxedTInspector;
      {close any active inspector}
      procedure Close();
   end;

VAR
   oxedInspector: oxedTInspectorEdit;

IMPLEMENTATION

procedure init();
begin
   oxedInspector := oxedTInspectorEdit.Create('Inspector', oxedTInspectorWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem(oxedInspector.Name, TObjectProcedure(@oxedInspector.CreateWindow));
end;

procedure deinit();
begin
   FreeObject(oxedInspector);
end;

{ oxedTInspector }

procedure oxedTInspector.Open(wnd: oxedTWindow);
begin

end;

procedure oxedTInspector.Close(wnd: oxedTWindow);
begin

end;

procedure oxedTInspector.SizeChanged(wnd: oxedTWindow);
begin

end;

procedure oxedTInspector.Update(wnd: oxedTWindow);
begin

end;

{ oxedTInspectorWindow }

procedure oxedTInspectorWindow.Initialize;
begin
   inherited Initialize;

   wdg.Groups.Initialize(wdg.Groups);
end;

function oxedTInspectorWindow.AddGroup(const caption: StdString): oxedTInspectorWindowGroup;
var
   y: longint;
   lastGroup: wdgTGroup;

begin
   if(wdg.Header <> nil) then
      y := wdg.Header.BelowOf(0)
   else
      y := Dimensions.h - 1;

   if(wdg.Groups.n > 0) then begin
      lastGroup := wdg.Groups.List[wdg.Groups.n - 1].Wdg;
      y := lastGroup.BelowOf(0);
   end;

   Result.Separator := wdgDivisor.Add('', oxPoint(0, y));

   Result.Wdg := wdgGroup.Add(caption, oxPoint(0, Result.Separator.BelowOf(0)), oxDimensions(Dimensions.w, 20));
   Result.Wdg.Transparent := true;
   Result.Wdg.RenderBorder := false;

   wdg.Groups.Add(Result);
end;

procedure oxedTInspectorWindow.SizeGroups();
var
   i, size: loopint;

begin
   if(wdg.Groups.n > 0) then begin
      wdg.Groups.List[0].Separator.Move(0, wdg.Header.BelowOf(0));
      wdg.Groups.List[0].Wdg.Move(0, wdg.Groups.List[0].Separator.BelowOf(0));

      for i := 0 to (wdg.Groups.n - 1) do begin
         {set size for current group}
         size := wdg.Groups.List[i].Wdg.Widgets.GetTotalHeight() + wdgDEFAULT_SPACING * 2  + wdg.
            Groups.List[i].Wdg.CachedFont.GetHeight();

         if(size < 20) then
            size := 20;

         wdg.Groups.List[i].Wdg.Resize(Dimensions.w, size);

         {position group to be below the first one}
         if(i > 0) then begin
            wdg.Groups.List[i].Separator.Move(0, wdg.Groups.List[i - 1].Wdg.BelowOf(0));
            wdg.Groups.List[i].Wdg.Move(0, wdg.Groups.List[i].Separator.BelowOf(0));
         end;
      end;
   end;
end;

procedure oxedTInspectorWindow.SetGroupWidths();
var
   i: loopint;

begin
   for i := 0 to (wdg.Groups.n - 1) do begin
      wdg.Groups.List[i].Wdg.Resize(Dimensions.w, wdg.Groups.List[i].Wdg.Dimensions.h);
   end;
end;

procedure oxedTInspectorWindow.SizeChanged(initial: boolean);
begin
   inherited SizeChanged;

   SetGroupWidths();

   if(CurrentInspector <> nil) then
      CurrentInspector.SizeChanged(Self);

   SizeGroups();

   {TODO: We could move the widgets by the offset (current group height - minus previous group height)}
   if(initial) and (CurrentInspector <> nil) then
      CurrentInspector.SizeChanged(Self);
end;

procedure oxedTInspectorWindow.SizeChanged();
begin
   inherited SizeChanged;

   SizeChanged(false);
end;

procedure oxedTInspectorWindow.Open(inspector: oxedTInspector);
begin
   if(CurrentInspector <> nil) then begin
      CurrentInspector.Close(Self);
      uiWidget.Dispose(uiTWidgets(Widgets));
   end;

   wdg.Header := nil;
   wdg.Groups.Dispose();

   CurrentInspector := inspector;

   if(CurrentInspector <> nil) then begin
      CurrentInspector.Open(Self);

      SizeChanged(true);
   end;
end;

procedure oxedTInspectorWindow.Close();
begin
   Open(nil);
end;

procedure oxedTInspectorWindow.Update();
begin
   if(CurrentInspector <> nil) then
      CurrentInspector.Update(Self);
end;

{ oxedTInspectorEdit }

constructor oxedTInspectorEdit.Create(const sName: StdString; InstanceType: oxedTUIWindowClass);
begin
   inherited Create(sName, InstanceType);

   SingleInstance := true;
end;

function oxedTInspectorEdit.GetInspector(inspectorType: oxedTInspectorClass): oxedTInspector;
var
   wnd: oxedTInspectorWindow;

begin
   wnd := oxedTInspectorWindow(Instance);
   if(wnd <> nil) then begin
      if(wnd.CurrentInspector <> nil) and (wnd.CurrentInspector.ClassType = inspectorType) then begin
         exit(wnd.CurrentInspector);
      end;
   end;

   Result := nil;
end;

procedure oxedTInspectorEdit.Close;
begin
   if(Instance <> nil) then
      oxedTInspectorWindow(Instance).Open(nil);
end;

procedure OnProjectChange();
begin
   if(oxedInspector <> nil) and (oxedInspector.Instance <> nil) then begin
      oxedTInspectorWindow(oxedInspector.Instance).Close();
   end;
end;

procedure beforeProjectStop();
begin
   OnProjectChange();
end;


INITIALIZATION
   oxed.Init.Add('scene.inspector', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectManagement.OnOpen.Add(@OnProjectChange);
   oxedProjectManagement.OnClosed.Add(@OnProjectChange);

   oxedProjectRunner.OnBeforeStop.Add(@beforeProjectStop);

END.
