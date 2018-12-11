{
   oxu9Patch, textures 9patch support
   Copyright (c) 2017. Dejan Boras

   Started On:    02.04.2017.

   Works similar to how android 9-patch works.
}

{$INCLUDE oxdefines.inc}
UNIT oxu9Patch;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuTypes, oxuTexture, oxuPrimitives, oxuRender;

CONST
   ox9PATCH_QUADS = 9;
   ox9PATCH_VERTICES = ox9PATCH_QUADS * QUAD_VERTICES;
   ox9PATCH_INDICES = ox9PATCH_QUADS * QUAD_INDICES;
   ox9PATCH_TEXCOORDS = ox9PATCH_QUADS * QUAD_TEXCOORDS;

TYPE
   oxTBuffered9Patch = record
      vertex: array[0..ox9PATCH_VERTICES - 1] of TVector2f;
      indices: array[0..ox9PATCH_INDICES - 1] of Word;
      texcoords: array[0..ox9PATCH_TEXCOORDS - 1] of TVector2f;
   end;

   { oxT9Patch }
   oxT9Patch = class
      Sizes: record
         width,
         height: single;

         topLeft,
         topRight,
         bottomLeft,
         bottomRight,
         up,
         down,
         left,
         right,
         center: TVector2f;
      end;

      Coords: record
         topLeft,
         topRight,
         bottomLeft,
         bottomRight,
         up,
         down,
         left,
         right,
         center: TQuadTextureCoords;
      end;

      {compute a 9-patch from the given sizes}
      procedure Compute(cornerSize, xSize, ySize: loopint);

      {build the patch coordinates}
      procedure Build();
      {build the patch coordinates}
      procedure BuildBuffer(width, height: single; out buffer: oxTBuffered9Patch);

      {render patch with the given texture}
      procedure Render(width, height: single; tex: oxTTexture);

      {render patch with the given texture}
      class procedure Render(tex: oxTTexture; var buffer: oxTBuffered9Patch); static;
   end;

IMPLEMENTATION

{ oxT9Patch }

procedure oxT9Patch.Compute(cornerSize, xSize, ySize: loopint);
begin
   Sizes.topLeft[0] := cornerSize;
   Sizes.topLeft[1] := cornerSize;
   Sizes.topRight := Sizes.topLeft;
   Sizes.bottomLeft := Sizes.topLeft;
   Sizes.bottomRight := Sizes.topLeft;

   Sizes.up[0] := xSize - (cornerSize * 2);
   Sizes.up[1] := cornerSize;

   Sizes.down := Sizes.up;

   Sizes.left[0] := cornerSize;
   Sizes.left[1] := ySize - (cornerSize * 2);

   Sizes.right := Sizes.left;

   Sizes.center[0] := xSize - (cornerSize * 2);
   Sizes.center[1] := ySize - (cornerSize * 2);

   Build();
end;

procedure oxT9Patch.Build();
var
   width, height: single;

begin
   width := Sizes.topLeft[0] + Sizes.center[0] + Sizes.topRight[0];
   height := Sizes.topLeft[1] + Sizes.center[1] + Sizes.bottomLeft[1];

   Sizes.width := width;
   Sizes.height := height;

   {top left}
   oxPrimitives.GetQuadTextureCoords(width, height, 0, 0,
      Sizes.topLeft[0], Sizes.topLeft[1], Coords.topLeft);
   {top right}
   oxPrimitives.GetQuadTextureCoords(width, height, Sizes.topLeft[0] + Sizes.center[0], 0,
      Sizes.topRight[0], Sizes.topRight[1], Coords.topRight);
   {bottom left}
   oxPrimitives.GetQuadTextureCoords(width, height, 0, height - Sizes.bottomLeft[1],
      Sizes.bottomLeft[0], Sizes.bottomLeft[1], Coords.bottomLeft);
   {bottom right}
   oxPrimitives.GetQuadTextureCoords(width, height, width - Sizes.bottomRight[1], height - Sizes.bottomRight[1],
      Sizes.bottomRight[0], Sizes.bottomRight[1], Coords.bottomRight);

   {center}
   oxPrimitives.GetQuadTextureCoords(width, height, Sizes.topLeft[0], Sizes.topLeft[1],
      Sizes.center[0], Sizes.center[1], Coords.center);

   {up}
   oxPrimitives.GetQuadTextureCoords(width, height, sizes.topLeft[0], 0,
      Sizes.up[0], Sizes.up[1], Coords.up);
   {down}
   oxPrimitives.GetQuadTextureCoords(width, height, Sizes.bottomLeft[0], height - Sizes.down[1],
      Sizes.down[0], Sizes.down[1], Coords.down);

   {left}
   oxPrimitives.GetQuadTextureCoords(width, height, 0, Sizes.topLeft[1],
      Sizes.left[0], Sizes.left[1], Coords.left);
   {right}
   oxPrimitives.GetQuadTextureCoords(width, height, width - Sizes.right[0], Sizes.topLeft[1],
      Sizes.right[0], Sizes.right[1], Coords.right);
end;

procedure oxT9Patch.BuildBuffer(width, height: single; out buffer: oxTBuffered9Patch);
var
   top,
   right,
   centerWidth,
   centerHeight,
   ratioX,
   ratioY: single;

   current: longint;

procedure renderPart(x, y, w, h: single; coords: PVector2f);
begin
   oxPrimitives.SetQuadVertices(x, y, x + w, y + h, PVector2f(@buffer.vertex[current * QUAD_VERTICES]));
   oxPrimitives.SetQuadIndices(current * QUAD_VERTICES, pword(@buffer.indices[current * QUAD_INDICES]));
   oxPrimitives.SetQuadTextureCoords(@buffer.texcoords[current * QUAD_TEXCOORDS], coords);

   inc(current);
end;

begin
   ratioX := (width - Sizes.topLeft[0] + Sizes.topRight[0]) / Sizes.center[0];
   ratioY := (height - Sizes.topLeft[1] + Sizes.topRight[1]) / Sizes.center[1];

   right := Sizes.topLeft[0] + Sizes.center[0] * ratioX;
   top := Sizes.bottomLeft[1] + Sizes.center[1] * ratioY;

   centerWidth := Sizes.center[0] * ratioX;
   centerHeight := Sizes.center[1] * ratioY;

   current := 0;

   {top left}
   renderPart(0, top, Sizes.topLeft[0], Sizes.topLeft[1], Coords.topLeft);
   {top right}
   renderPart(right, top, Sizes.topRight[0], Sizes.topRight[1], Coords.topRight);

   {up}
   renderPart(Sizes.topLeft[0], top, centerWidth, Sizes.up[1], Coords.up);
   {down}
   renderPart(Sizes.bottomLeft[0], 0, centerWidth, Sizes.down[1], Coords.down);

   {center}
   renderPart(Sizes.topLeft[0], Sizes.bottomLeft[1], centerWidth, centerHeight, Coords.center);

   {bottomLeft}
   renderPart(0, 0, Sizes.bottomLeft[0], Sizes.bottomLeft[1], Coords.bottomLeft);
   {bottomRight}
   renderPart(right, 0, Sizes.bottomRight[0], Sizes.bottomRight[1], Coords.bottomRight);

   {left}
   renderPart(0, Sizes.topLeft[1], Sizes.left[0], centerHeight, Coords.left);
   {bottomRight}
   renderPart(right, Sizes.topRight[1], Sizes.right[0], centerHeight, Coords.right);
end;

procedure oxT9Patch.Render(width, height: single; tex: oxTTexture);
var
   buffer: oxTBuffered9Patch;

begin
   BuildBuffer(width, height, buffer);

   Render(tex, buffer);
end;

class procedure oxT9Patch.Render(tex: oxTTexture; var buffer: oxTBuffered9Patch);
begin
   oxRender.EnableTexture();
   tex.rId.Bind();

   oxRender.Color4f(1, 1, 1, 1);

   oxRender.TextureCoords(buffer.texcoords[0]);
   oxRender.Vertex(buffer.vertex[0]);
   oxRender.Primitives(oxPRIMITIVE_TRIANGLES, ox9PATCH_QUADS * QUAD_INDICES, pword(@buffer.indices[0]));
end;

END.
