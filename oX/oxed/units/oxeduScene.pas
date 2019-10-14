{
   oxeduScene, oxed scene
   Copyright (C) 2016. Dejan Boras

   Started On:    18.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduScene;

INTERFACE

   USES
      uLog, uColors,
      {ox}
      uOX, oxuRunRoutines, oxuEntity, oxuSceneRender, oxuScene, oxuWorld,
      {oxed}
      uOXED, oxeduEditRenderers, oxeduMessages, oxeduEntities;

TYPE
   { oxedTSceneGlobal }

   oxedTSceneGlobal = record
      {currently selected entity}
      SelectedEntity: oxTEntity;
      {selected entity component renderer pairs}
      SelectedComponentPairs: oxedTEditRendererComponentPairs;

      {set an entity as currently selected}
      procedure SelectEntity(newEntity: oxTEntity);
      {set no entity as currently selected}
      procedure Unselect();
   end;

VAR
   {global scene properties}
   oxedScene: oxedTSceneGlobal;

   {original scene}
   oxedOriginalScene: oxTScene;
   {original world}
   oxedOriginalWorld: oxTWorld;


IMPLEMENTATION

{ oxedTSceneGlobal }

procedure oxedTSceneGlobal.SelectEntity(newEntity: oxTEntity);
begin
   SelectedEntity := newEntity;

   SelectedComponentPairs.Dispose();

   if(newEntity <> nil) then
      SelectedComponentPairs := oxedEditRenderers.FindForEntity(newEntity);
end;

procedure oxedTSceneGlobal.Unselect;
begin
   SelectEntity(nil);
end;

procedure entityRemove(entity: oxTEntity);
begin
   if(entity = oxedScene.SelectedEntity) then
      oxedScene.SelectEntity(nil);
end;

procedure sceneChange();
begin
   oxedScene.SelectEntity(nil);
end;

procedure init();
begin
   oxWorld.ClearColor.Assign(0.1, 0.1, 0.3, 1);

   oxedEntities.OnRemove.Add(@entityRemove);
end;

INITIALIZATION
   ox.Init.Add('oxed.scene', @init);

   oxed.OnSceneChange.Add(@sceneChange);

END.
