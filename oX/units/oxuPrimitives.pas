{
   oxuPrimitives, primitives
   Copyright (C) 2010. Dejan Boras

   Started On:    17.11.2010.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPrimitives;

INTERFACE

   USES
      uStd, vmVector;

CONST
   { quad }
   QUAD_FACES              = 2;
   QUAD_VERTICES           = 4;
   QUAD_INDICES            = 6;
   QUAD_TEXCOORDS          = 4;

   { cube }
   CUBE_FACES              = 12;

   CUBE_VERTICES           = 8;
   CUBE_VERTICES_ARRAY     = 36;

   CUBE_INDICES            = 36;
   CUBE_INDICES_TRI_STRIP  = 14;

{ QUAD }

TYPE
   TQuadVertices        = array[0..QUAD_VERTICES - 1] of TVector3f;
   TQuadTextureCoords   = array[0..QUAD_VERTICES - 1] of TVector2f;

CONST
   QuadIndicesui: array[0..QUAD_INDICES - 1] of longword   = (0, 1, 3, 3, 1, 2);
   QuadIndicesus: array[0..QUAD_INDICES - 1] of word       = (0, 1, 3, 3, 1, 2);
   QuadIndicesub: array[0..QUAD_INDICES - 1] of byte       = (0, 1, 3, 3, 1, 2);

   QuadVertices: TQuadVertices = (
      (-1.0,-1.0, 0.0),
      ( 1.0,-1.0, 0.0),
      ( 1.0, 1.0, 0.0),
      (-1.0, 1.0, 0.0)
   );

   QuadTexCoords: TQuadTextureCoords = (
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0)
   );

   { CUBE }

   CubeIndicesui: array[0..CUBE_INDICES-1] of longword = (
      0,2,1, 0,3,2,
      1,2,6, 6,5,1,
      4,5,6, 6,7,4,
      2,3,6, 6,3,7,
      0,7,3, 0,4,7,
      0,1,5, 0,5,4
   );

   CubeIndicesus: array[0..CUBE_INDICES-1] of word = (
      0,2,1, 0,3,2,
      1,2,6, 6,5,1,
      4,5,6, 6,7,4,
      2,3,6, 6,3,7,
      0,7,3, 0,4,7,
      0,1,5, 0,5,4);

   CubeIndicesub: array[0..CUBE_INDICES-1] of byte =  (
      0,2,1, 0,3,2,
      1,2,6, 6,5,1,
      4,5,6, 6,7,4,
      2,3,6, 6,3,7,
      0,7,3, 0,4,7,
      0,1,5, 0,5,4
   );

   CubeVertices: array[0..CUBE_VERTICES-1] of TVector3f = (
      (-1.0,-1.0,-1.0),
      ( 1.0,-1.0,-1.0),
      ( 1.0, 1.0,-1.0),
      (-1.0, 1.0,-1.0),
      (-1.0,-1.0, 1.0),
      ( 1.0,-1.0, 1.0),
      ( 1.0, 1.0, 1.0),
      (-1.0, 1.0, 1.0)
   );

   CubeVerticesTriStrip: array[0..CUBE_VERTICES-1] of TVector3f = (
      (-1.0,-1.0, 1.0),
      ( 1.0,-1.0, 1.0),
      (-1.0, 1.0, 1.0),
      ( 1.0, 1.0, 1.0),
      (-1.0,-1.0,-1.0),
      ( 1.0,-1.0,-1.0),
      (-1.0, 1.0,-1.0),
      ( 1.0, 1.0,-1.0)
   );

   CubeIndicesTriStripui: array[0..CUBE_INDICES_TRI_STRIP - 1] of longword =
      (0, 1, 2, 3, 7, 1, 5, 4, 7, 6, 2, 4, 0, 1
   );

   CubeIndicesTriStripus: array[0..CUBE_INDICES_TRI_STRIP - 1] of word =
      (0, 1, 2, 3, 7, 1, 5, 4, 7, 6, 2, 4, 0, 1
   );

   CubeIndicesTriStripub: array[0..CUBE_INDICES_TRI_STRIP - 1] of byte =
      (0, 1, 2, 3, 7, 1, 5, 4, 7, 6, 2, 4, 0, 1
   );

   CubeVerticesArray: array[0..CUBE_VERTICES_ARRAY-1] of TVector3f = (
      ( 1.0, 1.0, 1.0), (-1.0, 1.0, 1.0), (-1.0,-1.0, 1.0),
      (-1.0,-1.0, 1.0), ( 1.0,-1.0, 1.0), ( 1.0, 1.0, 1.0),

      ( 1.0, 1.0, 1.0), ( 1.0,-1.0, 1.0), ( 1.0,-1.0,-1.0),
      ( 1.0,-1.0,-1.0), ( 1.0, 1.0,-1.0), ( 1.0, 1.0, 1.0),

      ( 1.0, 1.0, 1.0), ( 1.0, 1.0,-1.0), (-1.0, 1.0,-1.0),
      (-1.0, 1.0,-1.0), (-1.0, 1.0, 1.0), ( 1.0, 1.0, 1.0),

      (-1.0, 1.0, 1.0), (-1.0, 1.0,-1.0), (-1.0,-1.0,-1.0),
      (-1.0,-1.0,-1.0), (-1.0,-1.0, 1.0), (-1.0, 1.0, 1.0),

      (-1.0,-1.0,-1.0), ( 1.0,-1.0,-1.0), ( 1.0,-1.0, 1.0),
      ( 1.0,-1.0, 1.0), (-1.0,-1.0, 1.0), (-1.0,-1.0,-1.0),

      ( 1.0,-1.0,-1.0), (-1.0,-1.0,-1.0), (-1.0, 1.0,-1.0),
      (-1.0, 1.0,-1.0), ( 1.0, 1.0,-1.0), ( 1.0,-1.0,-1.0)
   );

   oxPrimitivePoints: array[0..8] of loopint = (
      0, {oxPRIMITIVE_NONE}
      1, {oxPRIMITIVE_POINTS}
      2, {oxPRIMITIVE_LINES}
      1, {oxPRIMITIVE_LINE_LOOP}
      1, {oxPRIMITIVE_LINE_STRIP}
      3, {oxPRIMITIVE_TRIANGLES}
      2, {oxPRIMITIVE_TRIANGLE_STRIP}
      1, {oxPRIMITIVE_TRIANGLE_FAN}
      4 {oxPRIMITIVE_QUADS}
   );

TYPE

   { oxTPrimitivesGlobal }

   oxTPrimitivesGlobal = record
      procedure SetQuadVertices(x1, y1, x2, y2: single; q: PVector3f);
      procedure SetQuadVertices(x1, y1, x2, y2: single; q: PVector2f);
      procedure SetQuadTextureCoords(q: PVector2f; coords: PVector2f);
      procedure SetQuadIndices(base: word; indices: pword);
      procedure SetQuadIndices(base: dword; indices: PDWord);

      {get quad texture coordinates}
      procedure GetQuadTextureCoords(totalWidth, totalHeight, x, y, width, height: single; out coords: TQuadTextureCoords);
      procedure GetQuadTextureCoords(totalWidth, totalHeight, x, y, width, height: single; index: loopint; var coords: array of TVector2f);
      {get quad texture coords with given position and size on a texture}
      procedure GetQuadTextureCoords(cx, cy, wx, wy: single; coords: PVector2f);
      {get vertically flipped quad texture coordinates}
      procedure GetQuadTextureCoordsFlipped(totalWidth, totalHeight, x, y, width, height: single; out coords: TQuadTextureCoords);
      procedure GetQuadTextureCoordsFlipped(totalWidth, totalHeight, x, y, width, height: single; index: loopint; var coords: array of TVector2f);
      {get vertically flipped quad texture coords with given position and size on a texture}
      procedure GetQuadTextureCoordsFlipped(cx, cy, wx, wy: single; coords: PVector2f);

      {reindex an array from old indices to new indices}
      procedure Reindex(oldIndices: PWord; newIndices: PWord; count: loopint; oldVertex, newVertex: PVector3f);
      {reindex an array from old indices to new indices}
      procedure Reindex(oldIndices: PDWord; newIndices: PDWord; count: loopint; oldVertex, newVertex: PVector3f);
   end;

VAR
   oxPrimitives: oxTPrimitivesGlobal;

IMPLEMENTATION

procedure oxTPrimitivesGlobal.SetQuadVertices(x1, y1, x2, y2: single; q: PVector3f);
begin
   q[0][0] := x1;
   q[0][1] := y1;
   q[0][2] := 0;

   q[1][0] := x2;
   q[1][1] := y1;
   q[1][2] := 0;

   q[2][0] := x2;
   q[2][1] := y2;
   q[2][2] := 0;

   q[3][0] := x1;
   q[3][1] := y2;
   q[3][2] := 0;
end;

procedure oxTPrimitivesGlobal.SetQuadVertices(x1, y1, x2, y2: single; q: PVector2f);
begin
   q[0][0] := x1;
   q[0][1] := y1;

   q[1][0] := x2;
   q[1][1] := y1;

   q[2][0] := x2;
   q[2][1] := y2;

   q[3][0] := x1;
   q[3][1] := y2;
end;

procedure oxTPrimitivesGlobal.SetQuadTextureCoords(q: PVector2f; coords: PVector2f);
begin
   q[0] := coords[0];
   q[1] := coords[1];
   q[2] := coords[2];
   q[3] := coords[3];
end;

procedure oxTPrimitivesGlobal.SetQuadIndices(base: word; indices: pword);
begin
   indices[0] := base + QuadIndicesus[0];
   indices[1] := base + QuadIndicesus[1];
   indices[2] := base + QuadIndicesus[2];
   indices[3] := base + QuadIndicesus[3];
   indices[4] := base + QuadIndicesus[4];
   indices[5] := base + QuadIndicesus[5];
end;

procedure oxTPrimitivesGlobal.SetQuadIndices(base: dword; indices: PDWord);
begin
   indices[0] := int64(base) + QuadIndicesui[0];
   indices[1] := int64(base) + QuadIndicesui[1];
   indices[2] := int64(base) + QuadIndicesui[2];
   indices[3] := int64(base) + QuadIndicesui[3];
   indices[4] := int64(base) + QuadIndicesui[4];
   indices[5] := int64(base) + QuadIndicesui[5];
end;

procedure oxTPrimitivesGlobal.GetQuadTextureCoords(totalWidth, totalHeight, x, y, width, height: single; out coords: TQuadTextureCoords);
begin
   GetQuadTextureCoords(totalWidth, totalHeight, x, y, width, height, 0, {%H-}coords);
end;

procedure oxTPrimitivesGlobal.GetQuadTextureCoords(totalWidth, totalHeight, x, y, width, height: single; index: loopint;
   var coords: array of TVector2f);
var
   cx, cy, pix, piy, px, py: single;

begin
   pix := 1 / totalWidth;
   piy := 1 / totalHeight;

   px := pix * width;
   py := piy * height;

   cx := pix * x;
   cy := 1 - (piy * y);

   GetQuadTextureCoords(cx, cy, px, py, @coords[index]);
end;

procedure oxTPrimitivesGlobal.GetQuadTextureCoords(cx, cy, wx, wy: single; coords: PVector2f);
begin
   coords[0][0] := cx;
   coords[0][1] := cy - wy;

   coords[1][0] := cx + wx;
   coords[1][1] := cy - wy;

   coords[2][0] := cx + wx;
   coords[2][1] := cy;

   coords[3][0] := cx;
   coords[3][1] := cy;
end;

procedure oxTPrimitivesGlobal.GetQuadTextureCoordsFlipped(totalWidth, totalHeight, x, y, width, height: single;
   out coords: TQuadTextureCoords);
begin
   GetQuadTextureCoordsFlipped(totalWidth, totalHeight, x, y, width, height, 0, {%H-}coords);
end;

procedure oxTPrimitivesGlobal.GetQuadTextureCoordsFlipped(totalWidth, totalHeight, x, y, width, height: single; index: loopint;
   var coords: array of TVector2f);
var
   cx, cy, pix, piy, px, py: single;

begin
   pix := 1 / totalWidth;
   piy := 1 / totalHeight;

   px := pix * width;
   py := piy * height;

   cx := pix * x;
   cy := 1 - (piy * y);

   GetQuadTextureCoordsFlipped(cx, cy, px, py, @coords[index]);
end;

procedure oxTPrimitivesGlobal.GetQuadTextureCoordsFlipped(cx, cy, wx, wy: single; coords: PVector2f);
begin
   coords[0][0] := cx;
   coords[0][1] := cy;

   coords[1][0] := cx + wx;
   coords[1][1] := cy;

   coords[2][0] := cx + wx;
   coords[2][1] := cy - wy;

   coords[3][0] := cx;
   coords[3][1] := cy - wy;
end;

procedure oxTPrimitivesGlobal.Reindex(oldIndices: PWord; newIndices: PWord;
   count: loopint; oldVertex, newVertex: PVector3f);
var
   i: loopint;

begin
   for i := 0 to count - 1 do begin
     newVertex[newIndices[i]] := oldVertex[oldIndices[i]];
   end;
end;

procedure oxTPrimitivesGlobal.Reindex(oldIndices: PDWord; newIndices: PDWord;
   count: loopint; oldVertex, newVertex: PVector3f);
var
   i: loopint;

begin
   for i := 0 to count - 1 do begin
     newVertex[newIndices[i]] := oldVertex[oldIndices[i]];
   end;
end;

END.
