{
   oxuglTextureComponent, texture component
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglTextureComponent;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uColors,
      {ox}
      uOX, oxuTypes, oxuglRenderer, oxuTexture, oxuOGL, oxuRunRoutines;

TYPE
   { oglTTextureComponent }

   oglTTextureComponent = class(oxTTexture)
   end;

   { oglTextureIDComponent }

   oglTextureIDComponent = class(oxTTextureIDComponent)
      procedure Bind(var rID: oxTTextureID); override;
      procedure Delete(var rID: oxTTextureID); override;
      procedure SetRepeat(var {%H-}rID: oxTTextureID; repeatType: oxTTextureRepeat); override;
      procedure SetBorderColor(var {%H-}rID: oxTTextureID; const {%H-}color: TColor4f); override;
      procedure SetFilter(var {%H-}rID: oxTTextureID; filterType: oxTTextureFilter); override;
   end;


IMPLEMENTATION

VAR
   oglTextureID: oglTextureIDComponent;

function idComponentReturn(): TObject;
begin
   Result := oglTextureID;
end;

{ oglTextureIDComponent }

procedure oglTextureIDComponent.Bind(var rID: oxTTextureID);
begin
   assert(rID <> 0, 'Attempted to bind a 0 Id texture');

   glBindTexture(GL_TEXTURE_2D, rID)
end;

procedure oglTextureIDComponent.Delete(var rID: oxTTextureID);
var
   texID: GLuint;

begin
   texID := rID;
   glDeleteTextures(1, @texID);
end;

procedure oglTextureIDComponent.SetRepeat(var rID: oxTTextureID; repeatType: oxTTextureRepeat);
begin
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, oxglTexRepeat[longint(repeatType)]);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, oxglTexRepeat[longint(repeatType)]);
end;

procedure oglTextureIDComponent.SetBorderColor(var rID: oxTTextureID; const color: TColor4f);
begin
   {$IFNDEF GLES}
   glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, @color);
   {$ENDIF}
end;

procedure oglTextureIDComponent.SetFilter(var {%H-}rID: oxTTextureID; filterType: oxTTextureFilter);
begin
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, oxglTexFilters[longint(filterType)].min);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, oxglTexFilters[longint(filterType)].mag);
end;

function componentReturn(): TObject;
begin
   Result := oglTTextureComponent.Create();
end;

procedure init();
begin
   oglTextureID := oglTextureIDComponent.Create();
   oxglRenderer.components.RegisterComponent('texture.id', @idComponentReturn);
   oxglRenderer.components.RegisterComponent('texture', @componentReturn);
end;

procedure deinit();
begin
   oglTextureID.Free();
end;

INITIALIZATION
   ox.PreInit.Add('gl.texture_component', @init, @deinit);

END.
