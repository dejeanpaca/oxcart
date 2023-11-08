{
   oxuTexturePool, texture management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuTexturePool;


INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuRunRoutines, oxuResourcePool;

TYPE

   { oxTTexturePool }

   oxTTexturePool = class(oxTResourcePool)
      constructor Create(); override;
   end;

VAR
   oxTexturePool: oxTTexturePool;

IMPLEMENTATION

procedure init();
begin
   oxTexturePool := oxTTexturePool.Create();
   oxTexturePool.Name := 'texture.default';
end;

procedure deinit();
begin
   FreeObject(oxTexturePool);
end;

{ oxTTexturePool }

constructor oxTTexturePool.Create();
begin
   inherited;

   Name := 'texture';
end;

INITIALIZATION
   ox.Init.Add('texture-pool', @init, @deinit);

END.
