{
   oxeduEntityMenu, oxed entity menu, create and manipulate entities
   Copyright (C) 2017. Dejan Boras

   Started On:    22.03.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEntityMenu;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      oxuEntity, oxuScene,
      {entities}
      oxuCameraEntity, oxuLightEntity, oxuUIEntity, oxuPrimitiveModelEntities,
      {ui}
      uiuContextMenu, uiuWidgetWindow, uiuWidget,
      {oxed}
      uOXED, oxeduIcons;

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

      function AddToMenu(const name: string; func: oxedTEntityFunction): uiPContextMenuItem;
      function AddToMenu(const name: string; func: oxedTEntityFunction; menu: uiTContextMenu): uiPContextMenuItem;

      procedure Open(entity: oxTEntity; const from: uiTWidgetWindowOrigin);
      procedure Open(scene: oxTScene; const from: uiTWidgetWindowOrigin);

      procedure OpenMenu(const from: uiTWidgetWindowOrigin);

      class procedure MenuCallback({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem); static;

      function GetCurrentEntity(): oxTEntity;

      class procedure RenameEntity(); static;
   end;

VAR
   oxedEntityMenu: oxedTEntityMenuGlobal;

IMPLEMENTATION

{ oxedTEntityMenuGlobal }

function oxedTEntityMenuGlobal.AddToList(func: oxedTEntityFunction): loopint;
begin
   EntityList.Add(func);
   result := EntityList.n - 1;
end;

function oxedTEntityMenuGlobal.AddToMenu(const name: string; func: oxedTEntityFunction): uiPContextMenuItem;
begin
   result := AddToMenu(name, func, Menus.Create);
end;

function oxedTEntityMenuGlobal.AddToMenu(const name: string; func: oxedTEntityFunction; menu: uiTContextMenu): uiPContextMenuItem;
var
   item: uiPContextMenuItem;

begin
   item := menu.AddItem(name, 0, @oxedEntityMenu.MenuCallback);
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

function newEntity(): oxTEntity;
begin
   Result := oxEntity.New();
end;

procedure init();
var
   item: uiPContextMenuItem;

begin
   oxedEntityMenu.CurrentMenu := uiTContextMenu.Create('Entity menu');

   oxedEntityMenu.Menus.Create := uiTContextMenu.Create('Entity create menu');

   item := oxedEntityMenu.AddToMenu('Empty', @newEntity);

   item := oxedEntityMenu.AddToMenu('Camera', @oxCameraEntity.Default);
   oxedIcons.Create(item, $f03d);
   item := oxedEntityMenu.AddToMenu('Light', @oxLightEntity.Default);
   oxedIcons.Create(item, $f0eb);
   item := oxedEntityMenu.AddToMenu('UI', @oxUIEntity.Default);
   oxedIcons.Create(item, $f0eb);

   oxedEntityMenu.Menus.Primitives := oxedEntityMenu.Menus.Create.AddSub('Primitives');

   item := oxedEntityMenu.AddToMenu('Plane', @oxPrimitiveModelEntities.Plane, oxedEntityMenu.Menus.Primitives);
   oxedIcons.Create(item, $f0c8);

   item := oxedEntityMenu.AddToMenu('Cube', @oxPrimitiveModelEntities.Cube, oxedEntityMenu.Menus.Primitives);
   oxedIcons.Create(item, $f1b2);
   item := oxedEntityMenu.AddToMenu('Sphere', @oxPrimitiveModelEntities.Sphere, oxedEntityMenu.Menus.Primitives);
   oxedIcons.Create(item, $f111);

   item := oxedEntityMenu.AddToMenu('Circle', @oxPrimitiveModelEntities.Circle, oxedEntityMenu.Menus.Primitives);
   item := oxedEntityMenu.AddToMenu('Disk', @oxPrimitiveModelEntities.Disk, oxedEntityMenu.Menus.Primitives);
   item := oxedEntityMenu.AddToMenu('Torus', @oxPrimitiveModelEntities.Torus, oxedEntityMenu.Menus.Primitives);
   item := oxedEntityMenu.AddToMenu('Cylinder', @oxPrimitiveModelEntities.Cylinder, oxedEntityMenu.Menus.Primitives);
   item := oxedEntityMenu.AddToMenu('Cone', @oxPrimitiveModelEntities.Cone, oxedEntityMenu.Menus.Primitives);

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

