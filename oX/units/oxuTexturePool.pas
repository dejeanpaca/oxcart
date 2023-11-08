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

VAR
   initRoutines: oxTRunRoutine;

{ oxTTexturePool }

constructor oxTTexturePool.Create();
begin
   inherited;

   Name := 'texture';
end;

INITIALIZATION
   ox.Init.Add(initRoutines, 'texture-pool', @init, @deinit);

END.
