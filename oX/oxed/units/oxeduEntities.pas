{
   oxeduEntities, entity management
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEntities;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuEntity, oxuComponent, oxuRunRoutines,
      {oxed}
      oxeduThingies, oxeduEntityTypes;

TYPE
   { oxedTEntities }

   oxedTEntities = record
      OnCreate,
      OnDestroy,
      OnAdd,
      OnRemove,
      OnClone: oxTEntityCallbacks;
      OnComponentAdd,
      OnComponentRemove: oxTComponentCallbacks;

      procedure SetupHooks(var entities: oxTEntityGlobal);
   end;

VAR
   oxedEntities: oxedTEntities;

IMPLEMENTATION

procedure componentRemove(entity: oxTEntity; component: oxTComponent);
begin
   oxedEntities.OnComponentRemove.Call(entity, component);
end;

procedure componentAdd(entity: oxTEntity; {%H-}component: oxTComponent);
begin
   oxedEntities.OnComponentAdd.Call(entity, component);
end;

procedure entityCreate(entity: oxTEntity);
begin
   oxedEntities.OnCreate.Call(entity);
end;

procedure entityDestroy(entity: oxTEntity);
begin
   oxedEntities.OnDestroy.Call(entity);
end;

procedure entityAdd(entity: oxTEntity);
begin
   oxedEntities.OnAdd.Call(entity);
end;

procedure entityRemove(entity: oxTEntity);
begin
   oxedEntities.OnRemove.Call(entity);
end;

procedure entityClone(entity: oxTEntity);
begin
   oxedEntities.OnClone.Call(entity);
end;

procedure componentRemoveRenderers(entity: oxTEntity; component: oxTComponent);
begin
   oxedTEntityData(entity.Editor).ComponentRenderers := oxedThingies.FindForEntity(entity, component);
end;

procedure componentAddRenderers(entity: oxTEntity; {%H-}component: oxTComponent);
begin
   oxedTEntityData(entity.Editor).ComponentRenderers := oxedThingies.FindForEntity(entity);
end;

procedure entityCreateData(entity: oxTEntity);
begin
   if(entity.Editor = nil) then
      entity.Editor := oxedTEntityData.Create();
end;

procedure entityCloneData(entity: oxTEntity);
begin
   entityCreateData(entity);
   oxedTEntityData(entity.Editor).ComponentRenderers := oxedThingies.FindForEntity(entity);
end;

procedure init();
begin
   oxedEntities.SetupHooks(oxEntity);

   oxedEntities.OnCreate.Add(@entityCreateData);
   oxedEntities.OnClone.Add(@entityCloneData);

   oxedEntities.OnComponentRemove.Add(@componentRemoveRenderers);
   oxedEntities.OnComponentAdd.Add(@componentAddRenderers);
end;

procedure deinit();
begin
   oxedEntities.OnCreate.Dispose();
   oxedEntities.OnDestroy.Dispose();
   oxedEntities.OnAdd.Dispose();
   oxedEntities.OnRemove.Dispose();
   oxedEntities.OnClone.Dispose();

   oxedEntities.OnComponentAdd.Dispose();
   oxedEntities.OnComponentRemove.Dispose();
end;

{ oxedTEntities }

procedure oxedTEntities.SetupHooks(var entities: oxTEntityGlobal);
begin
   entities.OnCreate.Add(@entityCreate);
   entities.OnDestroy.Add(@entityDestroy);
   entities.OnAdd.Add(@entityAdd);
   entities.OnRemove.Add(@entityRemove);
   entities.OnClone.Add(@entityClone);

   entities.OnComponentRemove.Add(@componentRemove);
   entities.OnComponentAdd.Add(@componentAdd);
end;

INITIALIZATION
   ox.Init.Add('oxed.entities', @init, @deinit);

   oxTEntityCallbacks.InitializeValues(oxedEntities.OnCreate);
   oxTEntityCallbacks.InitializeValues(oxedEntities.OnDestroy);
   oxTEntityCallbacks.InitializeValues(oxedEntities.OnAdd);
   oxTEntityCallbacks.InitializeValues(oxedEntities.OnRemove);
   oxTEntityCallbacks.InitializeValues(oxedEntities.OnClone);

   oxTComponentCallbacks.InitializeValues(oxedEntities.OnComponentAdd);
   oxTComponentCallbacks.InitializeValues(oxedEntities.OnComponentRemove);

END.
