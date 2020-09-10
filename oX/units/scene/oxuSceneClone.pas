{
   oxeduSceneClone, clone a scene
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSceneClone;

INTERFACE

   USES
      sysutils, uStd, uLog, uTiming,
      {ox}
      oxuEntity, oxuComponent, oxuScene, oxuWorld, oxuSerialization;

procedure oxCloneScene(source: oxTScene; out scene: oxTScene; var serialization: oxTSerializationManager);

IMPLEMENTATION

function CloneEntity(serialization: oxTSerializationManager; entity: oxTEntity; includeChildren: boolean = true): oxTEntity; forward;

procedure CloneChildren(serialization: oxTSerializationManager; source: oxTEntity; target: oxTEntity);
var
   i: loopint;

begin
   {clone components}
   if(source.Components.n > 0) then begin
      target.Components.Allocate(source.Components.n);

      for i := 0 to (source.Components.n - 1) do begin
         target.Components.List[i] := oxTComponent(serialization.Clone(source.Components.List[i]));
         target.Components.List[i].Parent := target;
         target.Components.List[i].OnChange();
      end;

      target.Components.n := source.Components.n;
   end;

   {clone child entities}
   if(source.Children.n > 0) then begin
      target.Children.Allocate(source.Children.n);

      for i := 0 to (source.Children.n - 1) do begin
         target.Children.List[i] := CloneEntity(serialization, oxTEntity(source.Children.List[i]));
         oxTEntity(target.Children.List[i]).Parent := target;
      end;

      target.Children.n := source.Children.n;
   end;
end;

function CloneEntity(serialization: oxTSerializationManager; entity: oxTEntity; includeChildren: boolean = true): oxTEntity;
begin
   Result := oxTEntity(serialization.Clone(entity));

   Result.SetupMatrix();
   Result.Name := entity.Name;

   if(includeChildren) then
      CloneChildren(serialization, entity, Result);

   oxEntity.OnClone.Call(entity);
end;

procedure oxCloneScene(source: oxTScene; out scene: oxTScene; var serialization: oxTSerializationManager);
var
   startTime: TDateTime;

begin
   startTime := Time();

   scene := nil;

   scene := oxTScene(CloneEntity(serialization, source, false));
   scene.World := oxTWorld(serialization.Clone(source.World));

   CloneChildren(serialization, source, scene);

   log.v('Scene cloned (Elapsed: ' + startTime.ElapsedfToString() + 's)');
end;

END.
