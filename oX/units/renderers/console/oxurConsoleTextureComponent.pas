{
   oxurConsoleTextureComponent, texture component
   Copyright (C) 2016. Dejan Boras

   Started On:    28.11.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxurConsoleTextureComponent;

INTERFACE

   USES
      uStd,
      {ox}
      uOX, oxuConsoleRenderer, oxuTexture;

TYPE
   { oxrconTTextureComponent }

   oxrconTTextureComponent = class(oxTTexture)
   end;

   { oxrconTTextureIDComponent }

   oxrconTTextureIDComponent = class(oxTTextureIDComponent)
   end;


IMPLEMENTATION

VAR
   conTextureID: oxrconTTextureIDComponent;

function idComponentReturn(): TObject;
begin
   result := conTextureID;
end;

function componentReturn(): TObject;
begin
   result := oxrconTTextureComponent.Create();
end;

procedure init();
begin
   conTextureID := oxrconTTextureIDComponent.Create();
   oxConsoleRenderer.components.RegisterComponent('texture.id', @idComponentReturn);
   oxConsoleRenderer.components.RegisterComponent('texture', @componentReturn);
end;

procedure deinit();
begin
   FreeObject(conTextureID);
end;

INITIALIZATION
   ox.PreInit.Add('ox.con.texture', @init, @deinit);

END.
