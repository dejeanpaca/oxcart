{
   oxeduSceneHierarchy, scene hierarchy window
   Copyright (C) 2017. Dejan Boras

   Started On:    04.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneHierarchy;

INTERFACE

   USES
      uStd,
      {app}
      appuKeys, appuMouse,
      {ox}
      oxuTypes, oxuScene, oxuEntity, oxuFont,
      {ui}
      uiuTypes, uiuWindow, uiWidgets, uiuWidgetWindow,
      wdguList, wdguHierarchyList, wdguInputBox, uiuWidget, uiuInputBoxOverlay,
      {oxed}
      uOXED, oxeduWindow, oxeduMenubar, oxeduEntityMenu, oxeduProjectManagement, oxeduProject, oxeduProjectRunner,
      oxeduEntities, oxeduSceneManagement, oxeduScene,
      {ui}
      oxeduInspectorWindow, oxeduInspectEntity;

TYPE

   { wdgTSceneHierarchy }

   wdgTSceneHierarchy = class(wdgTHierarchyList)
      Scene: oxTEntity;

      constructor Create; override;

      procedure Assign(newScene: oxTEntity);

      function GetValue(index: loopint): string; override;
      function GetSubItems({%H-}index: loopint; ref: pointer): TPreallocatedPointerArrayList; override;
      function Expandable(index: loopint): boolean; override;

      function Key(var k: appTKeyEvent): boolean; override;

      procedure ItemNavigated(index: loopint); override;

      procedure ItemCleared(); override;
      procedure ItemClicked(index: loopint; button: TBitSet = appmcLEFT); override;
   end;

   { oxedTSceneHierarchyWindow }

   oxedTSceneHierarchyWindow = class(oxedTWindow)
      Scene: oxTScene;

      wdg: record
         Hierarchy: wdgTSceneHierarchy;
      end;

      constructor Create; override;

      procedure Initialize(); override;
      procedure SetScene(newScene: oxTScene);

      procedure SizeChanged; override;
   end;

   { oxedTSceneHierarchyClass }

   oxedTSceneHierarchyClass = class(oxedTWindowClass)
      constructor Create(const sName: string; InstanceType: oxedTUIWindowClass); override;

      procedure SetScene();
   end;

VAR
   oxedSceneHierarchy: oxedTSceneHierarchyClass;

IMPLEMENTATION

TYPE

   { oxedwdgTEntityRename }

   oxedwdgTEntityRename = class(wdgTInputBoxOverlay)
      procedure Confirmed(); override;
      procedure OnInvisible(); override;
   end;

procedure renameEntity();
var
   wnd: oxedTSceneHierarchyWindow;
   p: oxTPoint;

begin
   if(oxedEntityMenu.CurrentEntity <> nil) then begin
      wnd := oxedTSceneHierarchyWindow(oxedSceneHierarchy.Instance);

      p := wnd.wdg.Hierarchy.LastPointerPosition;
      p.x := wdgDEFAULT_SPACING;

      uiInputBoxOverlay.Instance := oxedwdgTEntityRename;
      uiInputBoxOverlay.Show(wnd.wdg.Hierarchy, p);
      uiInputBoxOverlay.Wdg.Resize(wnd.wdg.Hierarchy.Dimensions.w - wdgDEFAULT_SPACING * 2, 25);
      uiInputBoxOverlay.Wdg.SetText(oxedEntityMenu.CurrentEntity.Name);
   end;
end;

procedure OpenContext(var list: wdgTSceneHierarchy; index: loopint; var origin: uiTWidgetWindowOrigin);
begin
   if(index > -1) then begin
      oxedEntityMenu.Open(oxTEntity(list.GetItem(index)), origin);
      oxedEntityMenu.RenameCallback := @renameEntity;
   end else
      oxedEntityMenu.Open(list.Scene, origin);
end;

procedure setScene();
begin
   if(oxedSceneHierarchy <> nil) then
      oxedSceneHierarchy.SetScene();
end;

procedure openSceneHierarchy();
begin
   oxedSceneHierarchy.CreateWindow();
end;

procedure entityAdded(entity: oxTEntity);
var
   wnd: oxedTSceneHierarchyWindow;
   index: loopint;

begin
   wnd := oxedTSceneHierarchyWindow(oxedSceneHierarchy.Instance);

   if(wnd <> nil) and (wnd.wdg.Hierarchy <> nil) then begin
      index := wnd.wdg.Hierarchy.Find(entity.Parent);

      wnd.wdg.Hierarchy.AddItem(index, entity);
   end;
end;

procedure entityRemoved(entity: oxTEntity);
var
   wnd: oxedTSceneHierarchyWindow;
   index: loopint;

begin
   wnd := oxedTSceneHierarchyWindow(oxedSceneHierarchy.Instance);

   if(wnd <> nil) and (wnd.wdg.Hierarchy <> nil) then begin
      index := wnd.wdg.Hierarchy.Find(entity);

      if(index > -1) then
         wnd.wdg.Hierarchy.RemoveItem(index);

      if(oxedScene.SelectedEntity = entity) then
         oxedScene.Unselect();
   end;
end;

procedure sceneChanged();
begin
   setScene();
end;

procedure init();
begin
   oxedEntities.OnAdd.Add(@entityAdded);
   oxedEntities.OnRemove.Add(@entityRemoved);
   oxed.OnSceneChange.Add(@sceneChanged);

   oxedSceneHierarchy := oxedTSceneHierarchyClass.Create('Scene Hierarchy', oxedTSceneHierarchyWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem(oxedSceneHierarchy.Name, @openSceneHierarchy);
end;

procedure deinit();
begin
   FreeObject(oxedSceneHierarchy);
end;

{ oxedwdgTEntityRename }

procedure oxedwdgTEntityRename.Confirmed();
var
   text: string;

begin
   text := GetText();

   if(oxedEntityMenu.CurrentEntity <> nil) and (text <> '') then
      oxedEntityMenu.CurrentEntity.Name := text;
end;

procedure oxedwdgTEntityRename.OnInvisible();
var
   bwnd: oxedTSceneHierarchyWindow;

begin
   inherited;

   bwnd := oxedTSceneHierarchyWindow(wnd);
   if(bwnd.wdg.Hierarchy <> nil) then
      bwnd.wdg.Hierarchy.SelectQueue();
end;

{ oxedTSceneHierarchyClass }

constructor oxedTSceneHierarchyClass.Create(const sName: string; InstanceType: oxedTUIWindowClass);
begin
   inherited Create(sName, InstanceType);

   SingleInstance := true;
end;

procedure oxedTSceneHierarchyClass.SetScene();
begin
   if(Instance <> nil) then
      oxedTSceneHierarchyWindow(Instance).SetScene(oxScene);
end;

{ wdgTSceneHierarchy }

constructor wdgTSceneHierarchy.Create;
begin
   inherited Create;

   Selectable := true;
   HasGlyphs := true;
end;

procedure wdgTSceneHierarchy.Assign(newScene: oxTEntity);
begin
   Scene := newScene;

   Load();
end;

function wdgTSceneHierarchy.GetValue(index: loopint): string;
begin
   Result := oxTEntity(Visible.List[index].Item).Name
end;

procedure SetInspector(entity: oxTEntity);
var
   wnd: oxedTInspectorWindow;

begin
   wnd := oxedTInspectorWindow(oxedInspector.Instance);

   if(wnd = nil) then
      exit;

   if(entity <> nil) then begin
      wnd.Open(oxedInspectEntity);
      oxedInspectEntity.SetEntity(entity)
   end else
      wnd.Open(nil);
end;

function wdgTSceneHierarchy.GetSubItems(index: loopint; ref: pointer): TPreallocatedPointerArrayList;
var
   ent: oxTEntity;
   i: loopint;

begin
   Result.Initialize(Result);

   if(ref <> nil) then
      ent := oxTEntity(ref)
   else
      ent := Scene;

   if(ent = nil) then
      exit;

   Result.a := ent.Children.n;
   Result.n := Result.a;
   SetLength(Result.List, Result.n);

   for i := 0 to (Result.n - 1) do
      Result.List[i] := ent.Children.List[i];
end;

function wdgTSceneHierarchy.Expandable(index: loopint): boolean;
begin
   Result := oxTEntity(Visible.List[index].Item).Children.n > 0;
end;

function wdgTSceneHierarchy.Key(var k: appTKeyEvent): boolean;
begin
   Result := false;

   if(k.Key.Equal(kcF2)) then begin
      if(k.Key.Released() and (SelectedItem <> -1)) then begin
         oxedEntityMenu.CurrentEntity := oxTEntity(GetItem(SelectedItem));
         renameEntity();
      end;

      Result := true;
   end else if(k.Key.Equal(kcDEL)) then begin
      if(k.Key.Released() and (SelectedItem <> -1)) then begin
         oxedEntityMenu.CurrentEntity := oxTEntity(GetItem(SelectedItem));
         if(oxedEntityMenu.CurrentEntity.Parent <> nil) then
            oxedEntityMenu.CurrentEntity.Parent.Remove(oxedEntityMenu.CurrentEntity);

         oxedEntityMenu.CurrentEntity := nil;
         oxedInspectEntity.SetEntity(nil);
      end;

      Result := true;
   end else
      Result := inherited Key(k);
end;

procedure wdgTSceneHierarchy.ItemNavigated(index: loopint);
var
   entity: oxTEntity;

begin
   if(index > -1) then begin
      entity := oxTEntity(Visible.List[index].Item);

      oxedScene.SelectEntity(entity);
      SetInspector(entity);
   end else begin
      oxedScene.SelectEntity(nil);
      SetInspector(nil);
   end;
end;

procedure wdgTSceneHierarchy.ItemCleared;
begin
   oxedScene.SelectEntity(nil);
   SetInspector(nil);
end;

procedure wdgTSceneHierarchy.ItemClicked(index: loopint; button: TBitSet);
var
   origin: uiTWidgetWindowOrigin;

begin
   inherited ItemClicked(index, button);

   if(button = appmcRIGHT) then begin
      origin.Initialize(origin);

      origin.SetPoint(GetAbsolutePointer(LastPointerPosition), Self);
      OpenContext(Self, index, origin);
   end;
end;

{ oxedTSceneHierarchyWindow }

constructor oxedTSceneHierarchyWindow.Create;
begin
   inherited Create;
end;

procedure oxedTSceneHierarchyWindow.Initialize;
begin
   inherited Initialize;

   SetBackgroundType(uiwBACKGROUND_NONE);
   SetScene(oxScene);
end;

procedure oxedTSceneHierarchyWindow.SetScene(newScene: oxTScene);
begin
   if(oxedProject <> nil) then
      Scene := newScene
   else
      Scene := nil;

   if(wdg.Hierarchy = nil) then begin
      uiWidget.PushTarget();

      uiWidget.Create.Instance := wdgTSceneHierarchy;

      uiWidget.SetTarget(Self);
      wdg.Hierarchy := wdgTSceneHierarchy(wdgList.Add(oxPoint(0, Dimensions.h - 1), oxDimensions(Dimensions.w, Dimensions.h)));

      uiWidget.PopTarget();
   end;

   wdg.Hierarchy.Assign(Scene);
end;

procedure oxedTSceneHierarchyWindow.SizeChanged;
begin
   inherited SizeChanged;

   if(wdg.Hierarchy <> nil) then begin
      wdg.Hierarchy.Move(0, Dimensions.h - 1);
      wdg.Hierarchy.Resize(Dimensions.w, Dimensions.h);
   end;
end;

procedure OnProjectChange();
begin
   setScene();
end;

procedure OnStart();
begin
   setScene();
end;

procedure OnStop();
begin
   setScene();
   oxedScene.Unselect();
end;

INITIALIZATION
   oxed.Init.Add('scene.scenehierarchy', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedSceneManagement.OnNewScene.Add(@OnProjectChange);

   oxedProjectManagement.OnProjectOpen.Add(@OnProjectChange);
   oxedProjectManagement.OnNewProject.Add(@OnProjectChange);
   oxedProjectManagement.OnProjectClosed.Add(@OnProjectChange);

   oxedProjectRunner.OnStart.Add(@OnStart);
   oxedProjectRunner.OnStop.Add(@OnStop);

END.
