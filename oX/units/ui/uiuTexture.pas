{
   uiuTexture, ui textures
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuTexture;

INTERFACE

   USES
      uStd, uColors,
      {oX}
      oxuTypes, uiuTypes, oxuTexture, oxuTextureAtlas, oxu9Patch, uiuTexturePool;

TYPE

   { uiTTexture }

   uiTTexture = record
      Texture: oxTTexture;
      Atlas: oxTTextureAtlas;
      Patch: oxT9Patch;
      AtlasIndex: loopint;

      function Load(const fn: string): boolean;
      function LoadFromAtlas(const fn: string; index: loopint): boolean;
      function LoadPatch(const fn: string): boolean;

      procedure Destroy();
   end;

IMPLEMENTATION

{ uiTTexture }

function uiTTexture.Load(const fn: string): boolean;
begin

end;

function uiTTexture.LoadFromAtlas(const fn: string; index: loopint): boolean;
begin

end;

function uiTTexture.LoadPatch(const fn: string): boolean;
begin

end;

procedure uiTTexture.Destroy();
begin

end;

END.
