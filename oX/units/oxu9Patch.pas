{
   oxu9Patch, textures 9patch support
   Copyright (c) 2017. Dejan Boras

   Works similar to how android 9-patch works.
}

{$INCLUDE oxdefines.inc}
UNIT oxu9Patch;

INTERFACE

   USES
      uStd, vmVector, oxuMaterial,
      {ox}
      oxuTypes, oxuTexture, oxuPrimitives, oxuRender;

CONST
   ox9PATCH_QUADS = 9;
   ox9PATCH_VERTICES = ox9PATCH_QUADS * QUAD_VERTICES;
   ox9PATCH_INDICES = ox9PATCH_QUADS * QUAD_INDICES;
   ox9PATCH_TEXCOORDS = ox9PATCH_QUADS * QUAD_TEXCOORDS;

TYPE
   oxTBuffered9Patch = record
      Vertex: array[0..ox9PATCH_VERTICES - 1] of TVector2f;
      Indices: array[0..ox9PATCH_INDICES - 1] of Word;
      TexCoords: array[0..ox9PATCH_TEXCOORDS - 1] of TVector2f;
   end;

   { oxT9Patch }
   oxT9Patch = class
      Sizes: record
         Width,
         Height: single;

         TopLeft,
         TopRight,
         BottomLeft,
         BottomRight,
         Up,
         Down,
         Left,
         Right,
         Center: TVector2f;
      end;

      Coords: record
         TopLeft,
         TopRight,
         BottomLeft,
         BottomRight,
         Up,
         Down,
         Left,
         Right,
         Center: TQuadTextureCoords;
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
   Sizes.TopLeft[0] := cornerSize;
   Sizes.TopLeft[1] := cornerSize;

   Sizes.TopRight := Sizes.TopLeft;
   Sizes.BottomLeft := Sizes.TopLeft;
   Sizes.BottomRight := Sizes.TopLeft;

   Sizes.Up[0] := xSize - (cornerSize * 2);
   Sizes.Up[1] := cornerSize;

   Sizes.Down := Sizes.Up;

   Sizes.Left[0] := cornerSize;
   Sizes.Left[1] := ySize - (cornerSize * 2);

   Sizes.Right := Sizes.Left;

   Sizes.Center[0] := xSize - (cornerSize * 2);
   Sizes.Center[1] := ySize - (cornerSize * 2);

   Build();
end;

procedure oxT9Patch.Build();
var
   width, height: single;

begin
   width := Sizes.TopLeft[0] + Sizes.Center[0] + Sizes.TopRight[0];
   height := Sizes.TopLeft[1] + Sizes.Center[1] + Sizes.BottomLeft[1];

   Sizes.Width := width;
   Sizes.Height := height;

   {top left}
   oxPrimitives.GetQuadTextureCoords(width, height, 0, 0,
      Sizes.TopLeft[0], Sizes.TopLeft[1], Coords.TopLeft);
   {top right}
   oxPrimitives.GetQuadTextureCoords(width, height, Sizes.TopLeft[0] + Sizes.Center[0], 0,
      Sizes.TopRight[0], Sizes.TopRight[1], Coords.TopRight);
   {bottom left}
   oxPrimitives.GetQuadTextureCoords(width, height, 0, height - Sizes.BottomLeft[1],
      Sizes.BottomLeft[0], Sizes.BottomLeft[1], Coords.BottomLeft);
   {bottom right}
   oxPrimitives.GetQuadTextureCoords(width, height, width - Sizes.BottomRight[1], height - Sizes.BottomRight[1],
      Sizes.BottomRight[0], Sizes.BottomRight[1], Coords.BottomRight);

   {center}
   oxPrimitives.GetQuadTextureCoords(width, height, Sizes.TopLeft[0], Sizes.TopLeft[1],
      Sizes.Center[0], Sizes.Center[1], Coords.Center);

   {up}
   oxPrimitives.GetQuadTextureCoords(width, height, sizes.TopLeft[0], 0,
      Sizes.Up[0], Sizes.Up[1], Coords.Up);
   {down}
   oxPrimitives.GetQuadTextureCoords(width, height, Sizes.BottomLeft[0], height - Sizes.Down[1],
      Sizes.Down[0], Sizes.Down[1], Coords.Down);

   {left}
   oxPrimitives.GetQuadTextureCoords(width, height, 0, Sizes.TopLeft[1],
      Sizes.Left[0], Sizes.Left[1], Coords.Left);
   {right}
   oxPrimitives.GetQuadTextureCoords(width, height, width - Sizes.Right[0], Sizes.TopLeft[1],
      Sizes.Right[0], Sizes.Right[1], Coords.Right);
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
   oxPrimitives.SetQuadVertices(x, y, x + w, y + h, PVector2f(@buffer.Vertex[current * QUAD_VERTICES]));
   oxPrimitives.SetQuadIndices(current * QUAD_VERTICES, pword(@buffer.Indices[current * QUAD_INDICES]));
   oxPrimitives.SetQuadTextureCoords(@buffer.TexCoords[current * QUAD_TEXCOORDS], coords);

   inc(current);
end;

begin
   ratioX := (width - Sizes.TopLeft[0] + Sizes.TopRight[0]) / Sizes.Center[0];
   ratioY := (height - Sizes.TopLeft[1] + Sizes.TopRight[1]) / Sizes.Center[1];

   right := Sizes.TopLeft[0] + Sizes.Center[0] * ratioX;
   top := Sizes.BottomLeft[1] + Sizes.Center[1] * ratioY;

   centerWidth := Sizes.Center[0] * ratioX;
   centerHeight := Sizes.Center[1] * ratioY;

   current := 0;

   {top left}
   renderPart(0, top, Sizes.TopLeft[0], Sizes.TopLeft[1], Coords.TopLeft);
   {top right}
   renderPart(right, top, Sizes.TopRight[0], Sizes.TopRight[1], Coords.TopRight);

   {up}
   renderPart(Sizes.TopLeft[0], top, centerWidth, Sizes.Up[1], Coords.Up);
   {down}
   renderPart(Sizes.BottomLeft[0], 0, centerWidth, Sizes.Down[1], Coords.Down);

   {center}
   renderPart(Sizes.TopLeft[0], Sizes.BottomLeft[1], centerWidth, centerHeight, Coords.Center);

   {bottomLeft}
   renderPart(0, 0, Sizes.BottomLeft[0], Sizes.BottomLeft[1], Coords.BottomLeft);
   {bottomRight}
   renderPart(right, 0, Sizes.BottomRight[0], Sizes.BottomRight[1], Coords.BottomRight);

   {left}
   renderPart(0, Sizes.TopLeft[1], Sizes.Left[0], centerHeight, Coords.Left);
   {bottomRight}
   renderPart(right, Sizes.TopRight[1], Sizes.Right[0], centerHeight, Coords.Right);
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
   oxCurrentMaterial.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxCurrentMaterial.ApplyTexture('texture', tex);

   oxRender.TextureCoords(buffer.TexCoords[0]);
   oxRender.Vertex(buffer.Vertex[0]);

   oxRender.Primitives(oxPRIMITIVE_TRIANGLES, ox9PATCH_QUADS * QUAD_INDICES, pword(@buffer.Indices[0]));
end;

END.
