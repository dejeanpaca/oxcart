{
   oxuTexturePool, texture management
   Copyright (C) 2011. Dejan Boras

   Started On:    14.11.2009.
}

{$INCLUDE oxdefines.inc}
UNIT oxuTexturePool;


INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuResourcePool;

TYPE
   oxTTexturePool = class(oxTResourcePool)
   end;

VAR
   oxTexturePool: oxTTexturePool;

IMPLEMENTATION

procedure init();
begin
   oxTexturePool := oxTTexturePool.Create();
end;

procedure deinit();
begin
   FreeObject(oxTexturePool);
end;

INITIALIZATION
   ox.Init.Add('texture-pool', @init, @deinit);

END.
