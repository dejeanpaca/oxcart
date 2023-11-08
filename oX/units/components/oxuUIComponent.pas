{
   oxuUIComponent, ui component
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuUIComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTransform,
      oxuEntity, oxuSerialization,
      oxuComponent, oxuComponentDescriptors;

TYPE

   { oxTUIComponent }

   oxTUIComponent = class(oxTComponent)
      public

      constructor Create(); override;
      destructor Destroy(); override;

      {get the descriptor for this component}
      function GetDescriptor(): oxPComponentDescriptor; override;
   end;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;
   descriptor: oxTComponentDescriptor;

function instance(): TObject;
begin
   Result := oxTUIComponent.Create();
end;

{ oxTUIComponent }

constructor oxTUIComponent.Create();
begin
   inherited Create;
end;

destructor oxTUIComponent.Destroy();
begin
   inherited Destroy();
end;

function oxTUIComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

INITIALIZATION
   serialization := oxTSerialization.Create(oxTUIComponent, @instance);

   descriptor.Create('ui', oxTUIComponent);
   descriptor.Name := 'UI';

FINALIZATION
   FreeObject(serialization);

END.
