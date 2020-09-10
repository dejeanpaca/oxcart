{
   oxuModelComponent, model component
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuModelComponent;

INTERFACE

   USES
      uStd, vmVector, uLog,
      {ox}
      oxuSerialization, oxuComponentDescriptors, oxuRenderComponent, oxuEntity,
      oxuModel, oxuModelRender, oxuModelFile;

TYPE

   { oxTModelComponent }

   oxTModelComponent = class(oxTRenderComponent)
      public
      Model: oxTModel;
      Path: StdString;

      constructor Create(); override;

      procedure Render(); override;

      procedure GetBoundingBox(out bbox: TBoundingBox); override;

      procedure Deserialized(); override;
      procedure LoadResources(); override;

      function GetDescriptor(): oxPComponentDescriptor; override;

      class function GetEntity(out component: oxTModelComponent): oxTEntity; static;
   end;

IMPLEMENTATION

VAR
   descriptor: oxTComponentDescriptor;
   serializer: oxTSerialization;

{ oxTModelComponent }

constructor oxTModelComponent.Create();
begin
   inherited Create;
end;

procedure oxTModelComponent.Render();
begin
   oxModelRender.Render(Model);
end;

procedure oxTModelComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   if(Model <> nil) then
      Model.GetBoundingBox(bbox)
   else
      ZeroPtr(@bbox, SizeOf(bbox));
end;

procedure oxTModelComponent.Deserialized();
begin
   inherited Deserialized;
end;

procedure oxTModelComponent.LoadResources();
begin
   if(Model = nil) then
      Model := oxfModel.Read(Path);
end;

function oxTModelComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

class function oxTModelComponent.GetEntity(out component: oxTModelComponent): oxTEntity;
begin
   component := oxTModelComponent.Create();
   Result := oxEntity.New('Model', component);
end;

function instance(): TObject;
begin
   Result := oxTModelComponent.Create();
end;

INITIALIZATION
   descriptor.Create('render', oxTModelComponent);
   descriptor.Name := 'Model Render';

   serializer := oxTSerialization.Create(oxTModelComponent, @instance);
   serializer.AddProperty('Path', @oxTModelComponent(nil).Path, oxSerialization.Types.tString);

FINALIZATION
   FreeObject(serializer);

END.
