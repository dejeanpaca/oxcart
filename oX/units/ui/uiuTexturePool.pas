{
   uiuTexturePool, ui texture pool
   Copyright (C) 2018. Dejan Boras

   Started On:    20.09.2018.
}

{$INCLUDE oxdefines.inc}
UNIT uiuTexturePool;


INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuResourcePool;

TYPE
   uiTTexturePool = class(oxTResourcePool)
   end;

   uiTAtlasPool = class(oxTResourcePool)
   end;

   uiTPatchPool = class(oxTResourcePool)
   end;

VAR
   uiTexturePool: uiTTexturePool;
   uiAtlasPool: uiTAtlasPool;
   uiPatchPool: uiTPatchPool;

IMPLEMENTATION

procedure init();
begin
   uiTexturePool := uiTTexturePool.Create();
   uiAtlasPool := uiTAtlasPool.Create();
   uiPatchPool := uiTPatchPool.Create();
end;

procedure deinit();
begin
   FreeObject(uiTexturePool);
   FreeObject(uiAtlasPool);
   FreeObject(uiPatchPool);
end;

INITIALIZATION
   ox.Init.Add('ui-texture-pool', @init, @deinit);

END.
