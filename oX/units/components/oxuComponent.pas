{
   oxuComponent, component management
   Copyright (c) 2017. Dejan Boras

   Started On:    17.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuTransform, oxuSerialization, oxuComponentDescriptors;

TYPE
   { oxTComponent }

   oxTComponent = class(oxTSerializable)
      public
      Parent: oxTTransform;

      constructor Create(); override;

      procedure OnAdd(); virtual;
      procedure OnRemove(); virtual;

      procedure OnScaleChanged(); virtual;
      procedure OnPositionChanged(); virtual;
      procedure OnRotationChanged(); virtual;

      {call when you want to update everything}
      procedure OnChange(); virtual;

      procedure GetBoundingBox(out bbox: TBoundingBox); virtual;

      {called when scene is loaded}
      procedure Load(); virtual;
      {called when scene starts}
      procedure Start(); virtual;
      {called to update component per frame}
      procedure Update(); virtual;
      {load resources for this component}
      procedure LoadResources(); virtual;

      {get the descriptor for this component}
      function GetDescriptor(): oxPComponentDescriptor; virtual;
   end;

   oxTComponentType = class of oxTComponent;

   oxTComponentsList = specialize TSimpleList<oxTComponent>;

   { oxTComponentsListHelper }

   oxTComponentsListHelper = record helper for oxTComponentsList
      procedure Destroy();
   end;

IMPLEMENTATION

{ oxTComponentsListHelper }

procedure oxTComponentsListHelper.Destroy;
var
  i: loopint;

begin
   for i := 0 to (n - 1) do
     FreeObject(List[i]);

   Dispose();
end;

{ oxTComponent }

constructor oxTComponent.Create();
begin

end;

procedure oxTComponent.OnAdd();
begin

end;

procedure oxTComponent.OnRemove();
begin

end;

procedure oxTComponent.OnScaleChanged();
begin

end;

procedure oxTComponent.OnPositionChanged();
begin

end;

procedure oxTComponent.OnRotationChanged();
begin

end;

procedure oxTComponent.OnChange();
begin
   OnPositionChanged();
   OnRotationChanged();
   OnScaleChanged();
end;

procedure oxTComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   bbox := vmBBoxZero;
end;

procedure oxTComponent.Load();
begin

end;

procedure oxTComponent.Start();
begin

end;

procedure oxTComponent.Update();
begin

end;

procedure oxTComponent.LoadResources();
begin

end;

function oxTComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @oxComponentDescriptors.Unknown;
end;

END.
