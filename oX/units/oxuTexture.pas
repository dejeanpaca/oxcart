{
   oxuTexture, textures
   Copyright (c) 2013. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuTexture;

INTERFACE

   USES
      uComponentProvider, uStd, uImage, uColors,
      vmVector, vmMath,
      {oX}
      oxuTypes, oxuRenderer, oxuRenderers;

CONST
   { TEXTURE PROPERTIES }
   oxTEXTURE_HAS_ALPHA                 = $1;

TYPE
   oxTTextureFilter = (
      oxTEXTURE_FILTER_NONE,
      oxTEXTURE_FILTER_BILINEAR,
      oxTEXTURE_FILTER_TRILINEAR,
      oxTEXTURE_FILTER_ANISOTROPIC
   );

   oxTTextureRepeat = (
      oxTEXTURE_REPEAT,
      oxTEXTURE_REPEAT_MIRROR,
      oxTEXTURE_CLAMP_TO_EDGE,
      oxTEXTURE_CLAMP_TO_BORDER
   );

   { oxTTextureIDHelper }

   oxTTextureIDHelper = type helper for oxTTextureID
      procedure Bind();
      procedure Delete();
      procedure SetRepeat(repeatType: oxTTextureRepeat);
      procedure SetBorderColor(const color: TColor4f);
      procedure SetFilter(filterType: oxTTextureFilter);
   end;

   {Texture ID component}

   { oxTTextureIDComponent }

   oxTTextureIDComponent = class
      procedure Bind(var {%H-}rID: oxTTextureID); virtual;
      procedure Delete(var {%H-}rID: oxTTextureID); virtual;
      procedure SetRepeat(var {%H-}rID: oxTTextureID; {%H-}repeatType: oxTTextureRepeat); virtual;
      procedure SetBorderColor(var {%H-}rID: oxTTextureID; const {%H-}color: TColor4f); virtual;
      procedure SetFilter(var {%H-}rID: oxTTextureID; {%H-}filterType: oxTTextureFilter); virtual;
   end;

   { oxTTexture }

   {texture information}
   oxTTexture = class(oxTResource)
      Name: string;
      {texture type}
      TextureType: oxTTextureType;

      {texture width and height}
      Width,
      Height: longint;

      rId: oxTTextureID;
      Properties: TBitSet; {texture properties}
      PixelFormat: imgTPixelFormat;

      function HasAlpha(): boolean; inline;

      procedure Delete();
      destructor Destroy(); override;

      procedure SetRepeat(repeatType: oxTTextureRepeat);
      procedure SetBorderColor(const color: TColor4f);
   end;

   oxTTextures = array of oxTTexture;

   { oxTTextureGlobal }

   oxTTextureGlobal = record
      defaultFilter: oxTTextureFilter;

      Id: oxTTextureIDComponent;
      TextureInstance: TSingleComponent;

      {checks whether a texture with a given height and size is a power of 2 texture}
      class function IsPot(w, h: longint): boolean; static;
      {instances a texture}
      function Instance(): oxTTexture;

      { TEXTURE COORDS }

      class procedure CoordsQuadWH(w, h, dw, dh: longint; t: PVector2f); static;
      class procedure QuadCoords(tw, th, tilew, tileh, tilex, tiley: longint; t: PVector2f); static;

      class function Valid(t: oxTTexture): boolean; static;
      class function ValidId(t: oxTTexture): boolean; static;
   end;

   oxTSimpleTextureList = specialize TSimpleList<oxTTexture>;

VAR
   oxTex: oxTTextureGlobal;

IMPLEMENTATION


{ oxTTextureGlobal }

class function oxTTextureGlobal.IsPot(w, h: longint): boolean;
begin
   if(w > 0) and (h > 0) then
      Result := (PopCnt(dword(w)) = 1) and (PopCnt(dword(h)) = 1)
   else
      Result := false;
end;

function oxTTextureGlobal.Instance(): oxTTexture;
begin
   if(TextureInstance.Return <> nil) then
      Result := oxTTexture(TextureInstance.Return())
   else
      Result := oxTTexture.Create();
end;

{ TEXTURE COORDS }

class procedure oxTTextureGlobal.CoordsQuadWH(w, h, dw, dh: longint; t: PVector2f);
var
   px, py, dpx, dpy0: single;

begin
   if(w > 0) and (h > 0) then begin
      px    := 1.0 / w;
      py    := 1.0 / h;

      dpx   := dw * px;
      dpy0  := (h - dh) * py;

      t[0][0] := 0.0;
      t[0][1] := dpy0;

      t[1][0] := dpx;
      t[1][1] := dpy0;

      t[2][0] := dpx;
      t[2][1] := 1.0;

      t[3][0] := 0.0;
      t[3][1] := 1.0;
   end;
end;

class procedure oxTTextureGlobal.QuadCoords(tw, th, tilew, tileh, tilex, tiley: longint; t: PVector2f);
var
   x, y, px, py, lenx, leny: single;

begin
   px    := 1.0 / tw;
   py    := 1.0 / th;

   x     := (tilew * tilex) * px;
   y     := (tilew * tiley) * py;
   lenx  := tilew * px;
   leny  := tileh * py;

   t[0][0] := x;
   t[0][1] := y;

   t[1][0] := x + lenx;
   t[1][1] := y;

   t[2][0] := x + lenx;
   t[2][1] := y + leny;

   t[3][0] := x;
   t[3][1] := y + leny;
end;

class function oxTTextureGlobal.Valid(t: oxTTexture): boolean;
begin
   Result := (t <> nil) and (t.Name <> '');
end;

class function oxTTextureGlobal.ValidId(t: oxTTexture): boolean;
begin
   Result := (t <> nil) and (t.rId <> 0);
end;

{ oxTTextureIDComponent }

procedure oxTTextureIDComponent.Bind(var rID: oxTTextureID);
begin
end;

procedure oxTTextureIDComponent.Delete(var rID: oxTTextureID);
begin
end;

procedure oxTTextureIDComponent.SetRepeat(var rID: oxTTextureID; repeatType: oxTTextureRepeat);
begin

end;

procedure oxTTextureIDComponent.SetBorderColor(var rID: oxTTextureID; const color: TColor4f);
begin

end;

procedure oxTTextureIDComponent.SetFilter(var rID: oxTTextureID; filterType: oxTTextureFilter);
begin

end;

{ oxTTexture }

function oxTTexture.HasAlpha: boolean;
begin
   Result := Properties.IsSet(oxTEXTURE_HAS_ALPHA);
end;

procedure oxTTexture.Delete;
begin
   rId.Delete();
end;

destructor oxTTexture.Destroy();
begin
   rId.Delete();
end;

procedure oxTTexture.SetRepeat(repeatType: oxTTextureRepeat);
begin
   rId.SetRepeat(repeatType);
end;

procedure oxTTexture.SetBorderColor(const color: TColor4f);
begin
   rId.SetBorderColor(color);
end;

{ oxTTextureIDHelper }

procedure oxTTextureIDHelper.Bind();
begin
   oxTex.Id.Bind(Self);
end;

procedure oxTTextureIDHelper.Delete();
begin
   if(Self <> 0) then begin
      oxTex.Id.Delete(Self);
      Self := 0;
   end;
end;

procedure oxTTextureIDHelper.SetRepeat(repeatType: oxTTextureRepeat);
begin
   if(Self <> 0) then begin
      oxTex.Id.SetRepeat(Self, repeatType);
   end;
end;

procedure oxTTextureIDHelper.SetBorderColor(const color: TColor4f);
begin
   if(Self <> 0) then
      oxTex.Id.SetBorderColor(Self, color);
end;

procedure oxTTextureIDHelper.SetFilter(filterType: oxTTextureFilter);
begin
   if(Self <> 0) then
      oxTex.Id.SetFilter(Self, filterType);
end;

{ oxTTextureGlobal }

procedure onUse();
var
   pTextureInstance: PSingleComponent;

begin
   pTextureInstance := oxRenderer.FindComponent('texture');

   if(pTextureInstance <> nil) then
      oxTex.TextureInstance := pTextureInstance^;

   oxTex.Id := oxTTextureIDComponent(oxRenderer.GetComponent('texture.id'));
end;


INITIALIZATION
   oxTex.defaultFilter := oxTEXTURE_FILTER_TRILINEAR;

   oxRenderers.UseRoutines.Add(@onUse);
END.

