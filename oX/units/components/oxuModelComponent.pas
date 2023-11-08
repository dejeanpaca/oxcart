{
   oxuModelComponent, model component
   Copyright (c) 2018. Dejan Boras

   Started On:    30.01.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuModelComponent;

INTERFACE

   USES
      uStd, vmVector, uLog,
      {ox}
      oxuSerialization, oxuComponentDescriptors, oxuRenderComponent, oxuModel, oxuModelRender, oxuModelFile;

TYPE

   { oxTModelComponent }

   oxTModelComponent = class(oxTRenderComponent)
      public
      Model: oxTModel;
      Path: StdString;

      constructor Create(); override;

      procedure Render; override;

      procedure GetBoundingBox(out bbox: TBoundingBox); override;

      procedure Deserialized; override;
      procedure LoadResources(); override;

      function GetDescriptor(): oxPComponentDescriptor; override;
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

procedure oxTModelComponent.Render;
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

procedure oxTModelComponent.Deserialized;
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
