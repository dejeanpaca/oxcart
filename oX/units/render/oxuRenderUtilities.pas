{
   oxuRenderUtilities, utilities and helpers for rendering
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRenderUtilities;

INTERFACE

   USES
     uColors, vmVector,
     {ox}
     oxuRender, oxuTypes, oxuPrimitives, oxuMaterial, oxuTexture;
   
TYPE

   { oxTRenderingUtilitiesGlobal }
   oxTRenderingUtilitiesGlobal = record
      {render a cube primitive}
      procedure Cube();

		{renders lines for a bounding box}
		class procedure BBox(var bb: TBoundingBox); static;
      class procedure BBox(const p: TVector3f; var bb: TBoundingBox); static;
      class procedure Rect(x, y, x2, y2: single); static;

      class procedure Line(const p1, p2: TVector3f); static;
      class procedure Line(const p1, p2: TVector3f; const color: TColor4f); static;

      class procedure Triangle(const p1, p2, p3: TVector3f); static;
      class procedure Triangle(const p1, p2, p3: TVector3f; const color: TColor4f); static;

      class procedure TexturedQuad(x, y, w, h: single; tex: oxTTexture); static;
      class procedure QuadVertex(var v: TQuadVertices); static;

      class procedure StartQuad(id: oxTTexture); static;
      class procedure QuadTexture(id: oxTTexture); static;
      class procedure QuadVertex(); static;
      class procedure Quad(); static;
	end;

VAR
	oxRenderingUtilities: oxTRenderingUtilitiesGlobal;

IMPLEMENTATION

procedure oxTRenderingUtilitiesGlobal.Cube();
begin
   oxRender.Vertex(CubeVertices[0]);

   oxRender.Primitives(oxPRIMITIVE_TRIANGLES, Length(CubeIndicesus), pword(@CubeIndicesus[0]));
end;

{renders lines for a bounding box}
class procedure oxTRenderingUtilitiesGlobal.BBox(var bb: TBoundingBox);
var
   vx: array[0..23] of TVector3f;

begin
   {front-left line}
   vx[0] := bb[0];
   vx[1].Assign(bb[0][0], bb[1][1], bb[0][2]);

   {back-left line}
   vx[2].Assign(bb[1][0], bb[0][1], bb[0][2]);
   vx[3].Assign(bb[1][0], bb[1][1], bb[0][2]);
   {front-right line}
   vx[4].Assign(bb[0][0], bb[0][1], bb[1][2]);
   vx[5].Assign(bb[0][0], bb[1][1], bb[1][2]);
   {back-right line}
   vx[6].Assign(bb[1][0], bb[0][1], bb[1][2]);
   vx[7].Assign(bb[1][0], bb[1][1], bb[1][2]);

   {bottom 4 lines}
   {front}
   vx[8].Assign(bb[0][0], bb[0][1], bb[0][2]);
   vx[9].Assign(bb[1][0], bb[0][1], bb[0][2]);
   {back}
   vx[10].Assign(bb[0][0], bb[0][1], bb[1][2]);
   vx[11].Assign(bb[1][0], bb[0][1], bb[1][2]);
   {left}
   vx[12].Assign(bb[0][0], bb[0][1], bb[0][2]);
   vx[13].Assign(bb[0][0], bb[0][1], bb[1][2]);
   {right}
   vx[14].Assign(bb[1][0], bb[0][1], bb[0][2]);
   vx[15].Assign(bb[1][0], bb[0][1], bb[1][2]);

   {top 4 lines}
   {front}
   vx[16].Assign(bb[0][0], bb[1][1], bb[0][2]);
   vx[17].Assign(bb[1][0], bb[1][1], bb[0][2]);
   {back}
   vx[18].Assign(bb[0][0], bb[1][1], bb[1][2]);
   vx[19].Assign(bb[1][0], bb[1][1], bb[1][2]);
   {left}
   vx[20].Assign(bb[0][0], bb[1][1], bb[0][2]);
   vx[21].Assign(bb[0][0], bb[1][1], bb[1][2]);
   {right}
   vx[22].Assign(bb[1][0], bb[1][1], bb[0][2]);
   vx[23].Assign(bb[1][0], bb[1][1], bb[1][2]);

   oxRender.Vertex(vx[0]);
   oxRender.DrawArrays(oxPRIMITIVE_LINES, length(vx));
end;

class procedure oxTRenderingUtilitiesGlobal.BBox(const p: TVector3f; var bb: TBoundingBox);
var
   b: TBoundingBox;

begin
   b := bb;
   b[0] := b[0] + p;
   b[1] := b[1] + p;

   BBox(b);
end;

class procedure oxTRenderingUtilitiesGlobal.Rect(x, y, x2, y2: single);
var
   vx: array[0..3] of TVector2f;

begin
   {top}
   vx[0][0] := x;
   vx[0][1] := y;

   vx[1][0] := x2;
   vx[1][1] := y;


   vx[2][0] := x2;
   vx[2][1] := y2;

   vx[3][0] := x;
   vx[3][1] := y2;

   oxRender.Vertex(vx[0]);
   oxRender.DrawArrays(oxPRIMITIVE_LINE_LOOP, length(vx));
end;

class procedure oxTRenderingUtilitiesGlobal.Line(const p1, p2: TVector3f);
var
   v: array[0..1] of TVector3f;

begin
   v[0] := p1;
   v[1] := p2;

   oxRender.Lines(v);
end;

class procedure oxTRenderingUtilitiesGlobal.Line(const p1, p2: TVector3f; const color: TColor4f);
var
   v: array[0..1] of TVector3f;

begin
   oxCurrentMaterial.ApplyColor('color', color);

   v[0] := p1;
   v[1] := p2;

   oxRender.Lines(v);
end;

class procedure oxTRenderingUtilitiesGlobal.Triangle(const p1, p2, p3: TVector3f);
var
   v: array[0..2] of TVector3f;

begin
   v[0] := p1;
   v[1] := p2;
   v[2] := p3;

   oxRender.Vertex(v[0]);
   oxRender.DrawArrays(oxPRIMITIVE_TRIANGLES, Length(v));
end;

class procedure oxTRenderingUtilitiesGlobal.Triangle(const p1, p2, p3: TVector3f; const color: TColor4f);
var
   v: array[0..2] of TVector3f;

begin
   oxCurrentMaterial.ApplyColor('color', color);

   v[0] := p1;
   v[1] := p2;
   v[2] := p3;

   oxRender.Vertex(v[0]);
   oxRender.DrawArrays(oxPRIMITIVE_TRIANGLES, Length(v));
end;

class procedure oxTRenderingUtilitiesGlobal.TexturedQuad(x, y, w, h: single; tex: oxTTexture);
var
   vertex: TQuadVertices;

begin
   vertex := QuadVertices;
   vertex[0][0] := vertex[0][0] * w + x;
   vertex[0][1] := vertex[0][1] * h + y;

   vertex[1][0] := vertex[1][0] * w + x;
   vertex[1][1] := vertex[1][1] * h + y;

   vertex[2][0] := vertex[2][0] * w + x;
   vertex[2][1] := vertex[2][1] * h + y;

   vertex[3][0] := vertex[3][0] * w + x;
   vertex[3][1] := vertex[3][1] * h + y;

   oxRender.BlendDefault();
   QuadTexture(tex);

   oxRender.Vertex(vertex[0]);
   oxRender.Primitives(oxPRIMITIVE_TRIANGLES, 6, pword(@QuadIndicesus[0]));
end;

class procedure oxTRenderingUtilitiesGlobal.QuadVertex(var v: TQuadVertices);
begin
   oxRender.Vertex(v[0]);
   oxRender.Primitives(oxPRIMITIVE_TRIANGLES, 6, pword(@QuadIndicesus[0]));
end;

class procedure oxTRenderingUtilitiesGlobal.StartQuad(id: oxTTexture);
begin
   QuadTexture(id);
   QuadVertex();
end;

class procedure oxTRenderingUtilitiesGlobal.QuadTexture(id: oxTTexture);
begin
   oxCurrentMaterial.ApplyTexture('texture', id);
   oxRender.TextureCoords(QuadTexCoords[0]);
end;

class procedure oxTRenderingUtilitiesGlobal.QuadVertex();
begin
   oxRender.Vertex(QuadVertices[0]);
end;

class procedure oxTRenderingUtilitiesGlobal.Quad();
begin
   oxRender.Primitives(oxPRIMITIVE_TRIANGLES, 6, pword(@QuadIndicesus[0]));
end;


END.

