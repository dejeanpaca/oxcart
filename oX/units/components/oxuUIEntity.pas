{
   oxuUIEntity, UI entity
   Copyright (c) 2019. Dejan Boras

   Started On:    14.11.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuUIEntity;

INTERFACE

   USES
      uStd,
      {ox}
      oxuEntity, oxuUIComponent;

TYPE
   { oxTUIEntity }

   oxTUIEntity = record
      class function Default(): oxTEntity; static;
   end;

VAR
   oxUIEntity: oxTUIEntity;

IMPLEMENTATION

function getEntity(out component: oxTUIComponent): oxTEntity;
begin
   component := oxTUIComponent.Create();

   Result := oxEntity.New('UI', component);
end;

{ oxTUIEntity }

class function oxTUIEntity.Default(): oxTEntity;
var
   component: oxTUIComponent;

begin
   Result := getEntity(component);
end;

END.
