{
   oxeduEntityMenu, oxed entity menu, create and manipulate entities
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEntityMenu;

INTERFACE

   USES
      uStd, uLog, uColors,
      {ox}
      oxuEntity, oxuScene,
      {entities}
      oxuCameraEntity, oxuLightEntity, oxuUIEntity, oxuPrimitiveModelEntities,
      {ui}
      uiuContextMenu, uiuWidgetWindow, uiuWidget, uiuSkin,
      {oxed}
      uOXED, oxeduIcons,
      oxeduLightComponent;

TYPE
   oxedTEntityList = specialize TSimpleList<oxedTEntityFunction>;

   { oxedTEntityMenuGlobal }

   oxedTEntityMenuGlobal = record
      EntityList: oxedTEntityList;

      Menus: record
         Create,
         Primitives: uiTContextMenu;
      end;

      CurrentMenu: uiTContextMenu;
      CurrentEntity: oxTEntity;
      CurrentScene: oxTScene;

      RenameCallback: TProcedure;

      function AddToList(func: oxedTEntityFunction): loopint;

      function AddToMenu(const name: string; func: oxedTEntityFunction; menu: uiTContextMenu = nil): uiPContextMenuItem;

      procedure Open(entity: oxTEntity; const from: uiTWidgetWindowOrigin);
      procedure Open(scene: oxTScene; const from: uiTWidgetWindowOrigin);

      procedure OpenMenu(const from: uiTWidgetWindowOrigin);

      class procedure MenuCallback({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem); static;

      function GetCurrentEntity(): oxTEntity;

      class procedure RenameEntity(); static;
      class procedure AddTo(menu: uiTContextMenu); static;
   end;

VAR
   oxedEntityMenu: oxedTEntityMenuGlobal;

IMPLEMENTATION

procedure createBaseItems(menu: uiTContextMenu); forward;

{ oxedTEntityMenuGlobal }

function oxedTEntityMenuGlobal.AddToList(func: oxedTEntityFunction): loopint;
begin
   EntityList.Add(func);
   result := EntityList.n - 1;
end;

function oxedTEntityMenuGlobal.AddToMenu(const name: string; func: oxedTEntityFunction; menu: uiTContextMenu): uiPContextMenuItem;
var
   item: uiPContextMenuItem;

begin
   if(menu = nil) then
      menu := Menus.Create;

   item := menu.AddItem(name, 0, @MenuCallback);
   item^.Index := oxedEntityMenu.AddToList(func);

   result := item;
end;

procedure oxedTEntityMenuGlobal.Open(entity: oxTEntity; const from: uiTWidgetWindowOrigin);
begin
   CurrentEntity := entity;
   CurrentScene := nil;

   OpenMenu(from);
end;

procedure oxedTEntityMenuGlobal.Open(scene: oxTScene; const from: uiTWidgetWindowOrigin);
begin
   CurrentScene := scene;
   CurrentEntity := nil;

   OpenMenu(from);
end;

procedure deleteEntity();
var
   parent, current: oxTEntity;

begin
   current := oxedEntityMenu.GetCurrentEntity();

   if(current <> nil) and (current.Parent <> nil) then begin
      parent := current.Parent;

      parent.Remove(current);
   end;
end;

procedure oxedTEntityMenuGlobal.OpenMenu(const from: uiTWidgetWindowOrigin);
var
   item: uiPContextMenuItem;

begin
   CurrentMenu.RemoveAll();

   if(CurrentEntity <> nil) and (CurrentEntity.Parent <> nil) then begin
      item := CurrentMenu.AddItem('Cut');
      oxedIcons.Create(item, $f0c4);
      item := CurrentMenu.AddItem('Copy');
      oxedIcons.Create(item, $f0c5);
      item := CurrentMenu.AddItem('Paste');
      oxedIcons.Create(item, $f0ea);

      CurrentMenu.AddSeparator();

      item := CurrentMenu.AddItem('Rename', @RenameEntity);
      oxedIcons.Create(item, $f031);
      item := CurrentMenu.AddItem('Delete', @deleteEntity);
      item^.GlyphColor := uiSkin.StandardSkin.Colors.Delete;
      oxedIcons.Create(item, $f00d);

      CurrentMenu.AddSeparator();
   end;

   CurrentMenu.AddFrom(Menus.Create);

   CurrentMenu.Show(from);
end;

class procedure oxedTEntityMenuGlobal.MenuCallback(wdg: uiTWidget; menu: TObject; item: uiPContextMenuItem);
var
   entity: oxTEntity;
   current: oxTEntity;

begin
   if(item^.Index < oxedEntityMenu.EntityList.n) then begin
      entity := oxedEntityMenu.EntityList.List[item^.Index]();
      entity.Name := item^.Caption;

      current := oxedEntityMenu.GetCurrentEntity();

      if(current = nil) then
         log.e('No scene or entity set to which to add');

      if(current <> nil) then begin
         current.Add(entity);
      end;
   end;
end;

function oxedTEntityMenuGlobal.GetCurrentEntity(): oxTEntity;
begin
   if(CurrentEntity <> nil) then
      Result := CurrentEntity
   else if(CurrentScene <> nil) then
      Result := CurrentScene
   else
      Result := nil;
end;

class procedure oxedTEntityMenuGlobal.RenameEntity();
begin
   if(oxedEntityMenu.RenameCallback <> nil) then
      oxedEntityMenu.RenameCallback();
end;

class procedure oxedTEntityMenuGlobal.AddTo(menu: uiTContextMenu);
begin
   createBaseItems(menu);
   menu.AddSub(oxedEntityMenu.Menus.Primitives);
end;

{ FUNCTIONALITY }

function newEntity(): oxTEntity;
begin
   Result := oxEntity.New();
end;

function addItem(const name: string; func: oxedTEntityFunction; icon: longword = 0; menu: uiTContextMenu = nil): uiPContextMenuItem;
begin
   Result := oxedEntityMenu.AddToMenu(name, func, menu);

   if(icon <> 0) then
      oxedIcons.Create(Result, icon);
end;

function addPrimitiveItem(const name: string; func: oxedTEntityFunction; icon: longword = 0): uiPContextMenuItem;
begin
   Result := addItem(name, func, icon, oxedEntityMenu.Menus.Primitives);
end;

procedure createBaseItems(menu: uiTContextMenu);
var
   item: uiPContextMenuItem;

begin
   item := addItem('Empty', @newEntity, 0, menu);
   oxedIcons.Create(item, 0, 'regular:61640');
   addItem('Camera', @oxCameraEntity.Default, $f03d, menu);

   item := addItem('Light', @oxLightEntity.Default, $f0eb, menu);
   item^.GlyphColor := oxedLightThingie.Glyph^.Color;

   item := addItem('UI', @oxUIEntity.Default, $f0eb, menu);
end;

procedure createPrimitivesMenu();
var
   item: uiPContextMenuItem;

begin
   oxedEntityMenu.Menus.Primitives := oxedEntityMenu.Menus.Create.AddSub('Primitives');

   addPrimitiveItem('Plane', @oxPrimitiveModelEntities.Plane, $f0c8);
   addPrimitiveItem('Cube', @oxPrimitiveModelEntities.Cube, $f1b2);
   addPrimitiveItem('Sphere', @oxPrimitiveModelEntities.Sphere, $f111);

   item := addPrimitiveItem('Circle', @oxPrimitiveModelEntities.Circle, 0);
   oxedIcons.Create(item, 0, 'regular:61713');
   addPrimitiveItem('Disk', @oxPrimitiveModelEntities.Disk, $f111);
   addPrimitiveItem('Torus', @oxPrimitiveModelEntities.Torus);
   addPrimitiveItem('Cylinder', @oxPrimitiveModelEntities.Cylinder);
   addPrimitiveItem('Cone', @oxPrimitiveModelEntities.Cone, $f810);
end;

procedure init();
begin
   oxedEntityMenu.CurrentMenu := uiTContextMenu.Create('Entity menu');
   oxedEntityMenu.Menus.Create := uiTContextMenu.Create('Entity create menu');

   createBaseItems(oxedEntityMenu.Menus.Create);
   createPrimitivesMenu();
end;

procedure deinit();
begin
   uiContextMenu.Destroy();

   FreeObject(oxedEntityMenu.Menus.Create);
   FreeObject(oxedEntityMenu.CurrentMenu);
end;

INITIALIZATION
   oxed.Init.Add('entity_menu', @init, @deinit);

   oxedEntityMenu.EntityList.InitializeValues(oxedEntityMenu.EntityList);

END.

