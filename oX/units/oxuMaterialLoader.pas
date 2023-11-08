{
   oxuMaterialLoader, material resource loader
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuMaterialLoader;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      uOX, oxuTypes,
      oxuMaterial, oxuMaterialFile, oxuResourceLoader;

TYPE

   { oxTMaterialResourceLoader }

   oxTMaterialResourceLoader = object(oxTResourceLoader)
      constructor Create();

      function Load(resource: oxTResource): boolean; reintroduce;
   end;

VAR
   oxMaterialResourceLoader: oxTMaterialResourceLoader;

IMPLEMENTATION
{ oxTMaterialResourceLoader }

constructor oxTMaterialResourceLoader.Create();
begin
   Name := 'Material';
end;

function oxTMaterialResourceLoader.Load(resource: oxTResource): boolean;
var
   material: oxTMaterial;

begin
   Result := false;
   material := oxTMaterial(resource);

   if(material.Path <> '') then begin
      log.v('Loading material: ' + material.Path);

      // TODO: Load material
   end;

   // TODO: Load textures
end;

INITIALIZATION
   oxMaterialResourceLoader.Create();
   oxMaterial.ResourceLoader := @oxMaterialResourceLoader;

END.
