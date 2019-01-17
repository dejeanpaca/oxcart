{
   oxuDefaultTexture, default textue

   This file is part of oX engine. See copyright information in COPYRIGHT.md
   Copyright (C) 2017. Dejan Boras

   Started On:    10.09.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDefaultTexture;

INTERFACE

   USES
      uStd, uLog, uFile, uFiles,
      {oX}
      uOX, oxuTexture, oxuTextureGenerate, oxuResourcePool;

TYPE
   oxTDefaultTextureGlobal = record
      Load: boolean;
      Texture: oxTTexture;
   end;

VAR
   oxDefaultTexture: oxTDefaultTextureGlobal;

IMPLEMENTATION

CONST
   {$INCLUDE resources/default_texture.inc}

procedure load();
var
   errorCode: loopint = 0;
   f: TFile;

begin
   if(oxDefaultTexture.Load) then begin
      fFile.Init(f);
      f.Open(@default_texture, length(default_texture));

      if(f.Error = 0) then begin
         errorCode := oxTextureGenerate.Generate('*.tga', f, oxDefaultTexture.Texture);

         {do not dispose this ever}
         oxDefaultTexture.Texture.MarkPermanent();
         oxDefaultTexture.Texture.Path := ':default_texture';
      end;

      if(f.Error <> 0) or (errorCode <> 0) then
         log.e('oX > Failed to load default texture');

      f.Close();
      f.Dispose();
   end;
end;

{destroy the default texture}
procedure dispose();
begin
   oxResource.Free(oxDefaultTexture.Texture);
end;

INITIALIZATION
   oxDefaultTexture.Load := true;
   ox.BaseInit.Add('default_texture', @load, @dispose);

END.

