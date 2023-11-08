{
   uiuTexturePool, ui texture pool
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuTexturePool;


INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuResourcePool;

TYPE

   { uiTTexturePool }

   uiTTexturePool = class(oxTResourcePool)
      constructor Create(); override;
   end;

   { uiTAtlasPool }

   uiTAtlasPool = class(oxTResourcePool)
      constructor Create(); override;
   end;

   { uiTPatchPool }

   uiTPatchPool = class(oxTResourcePool)
      constructor Create(); override;
   end;

VAR
   uiTexturePool: uiTTexturePool;
   uiAtlasPool: uiTAtlasPool;
   uiPatchPool: uiTPatchPool;

IMPLEMENTATION

procedure init();
begin
   uiTexturePool := uiTTexturePool.Create();
   uiTexturePool.Name := 'ui.texture.default';

   uiAtlasPool := uiTAtlasPool.Create();
   uiAtlasPool.Name := 'ui.atlas.default';

   uiPatchPool := uiTPatchPool.Create();
   uiPatchPool.Name := 'ui.patch.default';
end;

procedure deinit();
begin
   FreeObject(uiTexturePool);
   FreeObject(uiAtlasPool);
   FreeObject(uiPatchPool);
end;

{ uiTTexturePool }

constructor uiTTexturePool.Create();
begin
   inherited;

   Name := 'ui.texture';
end;

{ uiTAtlasPool }

constructor uiTAtlasPool.Create();
begin
   inherited Create();

   Name := 'ui.atlas';
end;

{ uiTPatchPool }

constructor uiTPatchPool.Create();
begin
   inherited;

   Name := 'ui.patch';
end;

INITIALIZATION
   ox.Init.Add('ui-texture-pool', @init, @deinit);

END.
