{
   oxuSkyboxComponent, sky box
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSkyboxComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuComponent, oxuComponentDescriptors, oxuRenderComponent, oxuEntity,
      oxuSerialization, oxuSkybox;

TYPE

   { oxTSkyboxComponent }

   oxTSkyboxComponent = class(oxTRenderComponent)
      public
      constructor Create(); override;

      procedure Render(); override;

      function GetDescriptor(): oxPComponentDescriptor; override;

      class function GetEntity(out component: oxTSkyboxComponent): oxTEntity; static;
   end;

IMPLEMENTATION

VAR
   serializer: oxTSerialization;
   descriptor: oxTComponentDescriptor;

{ oxTSkyboxComponent }

constructor oxTSkyboxComponent.Create();
begin
   inherited;
end;

procedure oxTSkyboxComponent.Render();
begin
   {TODO: Render Skybox}
end;

function oxTSkyboxComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

class function oxTSkyboxComponent.GetEntity(out component: oxTSkyboxComponent): oxTEntity;
begin
   component := oxTSkyboxComponent.Create();
   Result := oxEntity.New('Skybox', component);
end;

function instance(): TObject;
begin
   Result := oxTSkyboxComponent.Create();
end;

INITIALIZATION
   serializer := oxTSerialization.Create(oxTSkyboxComponent, @instance);

   descriptor.Create('skybox', oxTSkyboxComponent);
   descriptor.Name := 'Skybox';

FINALIZATION
   FreeObject(serializer);

END.
