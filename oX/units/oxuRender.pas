{
   oxuRender, rendering
   Copyright (C) 2011. Dejan Boras

   Started On:    21.02.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuRender;

INTERFACE

   USES
      uStd, uColors, vmVector,
      {oX}
      {$IFNDEF OX_LIBRARY}
      oxuRunRoutines,
      {$ENDIF}
      oxuTypes,
      oxuRenderer, oxuRenderers, oxuTexture, oxuGlobalInstances;

TYPE
   { oxTRender }

   oxTRender = class
      {$IFDEF DEBUG}
      LastUsedVertex: pointer;
      LastUsedTextureCoords: pointer;
      LastUsedNormals: pointer;
      LastUsedIndices: pointer;
      LastUsedColor: pointer;
      {$ENDIF}

      procedure EnableBlend();
      procedure DisableBlend();
      procedure BlendFunction({%H-}blendFunc: oxTBlendFunction); virtual;
      procedure BlendDefault();

      procedure DepthTest({%H-}test: oxTTestFunction); virtual;
      procedure DepthWrite({%H-}on: boolean); virtual;
      procedure DepthDefault();

      procedure AlphaTest({%H-}test: oxTTestFunction; {%H-}alpha: single); virtual;

      procedure CullFace({%H-}cull: oxTCullFace); virtual;

      { SETUP }

      {set line width}
      procedure LineWidth({%H-}pixels: single); virtual;
      procedure PointSize({%H-}size: single); virtual;

      { RENDERING }
      procedure TextureCoords(var {%H-}v: TVector2f); virtual;

      procedure Vertex(var {%H-}v: TVector2f); virtual;
      procedure Vertex(var {%H-}v: TVector3f); virtual;

      procedure Color(var {%H-}v: TColor3f); virtual;
      procedure Color(var {%H-}v: TColor4f); virtual;
      procedure Color(var {%H-}v: TColor3ub); virtual;
      procedure Color(var {%H-}v: TColor4ub); virtual;
      procedure DisableColor(); virtual;

      procedure Normals(var {%H-}v: array of TVector3f); virtual;
      procedure DisableNormals(); virtual;

      procedure Triangles(n: longint; var v: array of TVector2f; var indices: array of word);
      procedure Triangles(n: longint; var v: array of TVector3f; var indices: array of word);
      procedure Triangles(n: longint; var v: array of TVector2f; var indices: array of longword);
      procedure Triangles(n: longint; var v: array of TVector3f; var indices: array of longword);

      procedure Triangles(n: longint; var v: TVector2f; indices: PLongWord);
      procedure Triangles(n: longint; var v: TVector3f; indices: PLongWord);
      procedure Triangles(n: longint; var v: TVector2f; indices: PWord);
      procedure Triangles(n: longint; var v: TVector3f; indices: PWord);

      procedure Lines(var {%H-}v: array of TVector2f); virtual;
      procedure Lines(var {%H-}v: array of TVector3f); virtual;

      procedure LineLoop(var {%H-}v: array of TVector2f); virtual;
      procedure LineLoop(var {%H-}v: array of TVector3f); virtual;

      procedure LineStrip(var {%H-}v: array of TVector2f); virtual;
      procedure LineStrip(var {%H-}v: array of TVector3f); virtual;

      procedure Points(var {%H-}v: array of TVector2f); virtual;
      procedure Points(var {%H-}v: array of TVector3f); virtual;

      procedure Primitives({%H-}primitive: oxTPrimitives; {%H-}count: longint; {%H-}indices: PWord); virtual;
      procedure Primitives({%H-}primitive: oxTPrimitives; {%H-}count: longint; {%H-}indices: PLongWord); virtual;
      procedure DrawArrays({%H-}primitive: oxTPrimitives; {%H-}count: longint); virtual;

      procedure CheckError(); virtual;

      {SCISSOR}
      {set the scissor test boundaries}
      procedure Scissor({%H-}x, {%H-}y, {%H-}w, {%H-}h: longint); virtual;
      procedure DisableScissor(); virtual;
   end;

VAR
   oxRender: oxTRender;

IMPLEMENTATION

{ oxTRender }

procedure oxTRender.EnableBlend();
begin
   BlendFunction(oxBLEND_DEFAULT);
end;

procedure oxTRender.DisableBlend();
begin
   BlendFunction(oxBLEND_NONE)
end;

procedure oxTRender.BlendFunction(blendFunc: oxTBlendFunction);
begin
end;

procedure oxTRender.BlendDefault;
begin
   EnableBlend();
   BlendFunction(oxBLEND_DEFAULT);
end;

procedure oxTRender.DepthTest(test: oxTTestFunction);
begin

end;

procedure oxTRender.DepthWrite(on: boolean);
begin
end;

procedure oxTRender.DepthDefault;
begin
   DepthWrite(true);
   DepthTest(oxTEST_FUNCTION_DEFAULT);
end;

procedure oxTRender.AlphaTest(test: oxTTestFunction; alpha: single);
begin
end;

procedure oxTRender.CullFace(cull: oxTCullFace);
begin
end;

procedure oxTRender.LineWidth(pixels: single);
begin
end;

procedure oxTRender.PointSize(size: single);
begin

end;

procedure oxTRender.TextureCoords(var v: TVector2f);
begin

end;

procedure oxTRender.Vertex(var v: TVector2f);
begin

end;

procedure oxTRender.Vertex(var v: TVector3f);
begin

end;

procedure oxTRender.Color(var v: TColor3f);
begin

end;

procedure oxTRender.Color(var v: TColor4f);
begin

end;

procedure oxTRender.Color(var v: TColor3ub);
begin

end;

procedure oxTRender.Color(var v: TColor4ub);
begin

end;

procedure oxTRender.DisableColor;
begin

end;

procedure oxTRender.Normals(var v: array of TVector3f);
begin
end;

procedure oxTRender.DisableNormals();
begin
end;

procedure oxTRender.Triangles(n: longint; var v: array of TVector2f; var indices: array of word);
begin
   Vertex(v[0]);
   Primitives(oxPRIMITIVE_TRIANGLES, n, pword(@indices[0]));
end;

procedure oxTRender.Triangles(n: longint; var v: array of TVector3f; var indices: array of word);
begin
   Vertex(v[0]);
   Primitives(oxPRIMITIVE_TRIANGLES, n, pword(@indices[0]));
end;

procedure oxTRender.Triangles(n: longint; var v: array of TVector2f; var indices: array of longword);
begin
   Vertex(v[0]);
   Primitives(oxPRIMITIVE_TRIANGLES, n, PLongWord(@indices[0]));
end;

procedure oxTRender.Triangles(n: longint; var v: array of TVector3f; var indices: array of longword);
begin
   Vertex(v[0]);
   Primitives(oxPRIMITIVE_TRIANGLES, n, PLongWord(@indices[0]));
end;

procedure oxTRender.Triangles(n: longint; var v: TVector2f; indices: PLongWord);
begin
   Vertex(v);
   Primitives(oxPRIMITIVE_TRIANGLES, n, indices);
end;

procedure oxTRender.Triangles(n: longint; var v: TVector3f; indices: PLongWord);
begin
   Vertex(v);
   Primitives(oxPRIMITIVE_TRIANGLES, n, indices);
end;

procedure oxTRender.Triangles(n: longint; var v: TVector2f; indices: PWord);
begin
   Vertex(v);
   Primitives(oxPRIMITIVE_TRIANGLES, n, indices);
end;

procedure oxTRender.Triangles(n: longint; var v: TVector3f; indices: PWord);
begin
   Vertex(v);
   Primitives(oxPRIMITIVE_TRIANGLES, n, indices);
end;

procedure oxTRender.Lines(var v: array of TVector2f);
begin
end;

procedure oxTRender.Lines(var v: array of TVector3f);
begin
end;

procedure oxTRender.LineLoop(var v: array of TVector2f);
begin
end;

procedure oxTRender.LineLoop(var v: array of TVector3f);
begin
end;

procedure oxTRender.LineStrip(var v: array of TVector2f);
begin

end;

procedure oxTRender.LineStrip(var v: array of TVector3f);
begin

end;

procedure oxTRender.Points(var v: array of TVector2f);
begin
end;

procedure oxTRender.Points(var v: array of TVector3f);
begin
end;

procedure oxTRender.Primitives(primitive: oxTPrimitives; count: longint; indices: PWord);
begin

end;

procedure oxTRender.Primitives(primitive: oxTPrimitives; count: longint; indices: PLongWord);
begin

end;

procedure oxTRender.DrawArrays(primitive: oxTPrimitives; count: longint);
begin
end;

procedure oxTRender.CheckError;
begin

end;

procedure oxTRender.Scissor(x, y, w, h: longint);
begin
end;

procedure oxTRender.DisableScissor();
begin
end;

procedure onUse();
begin
   oxRender := oxTRender(oxRenderer.GetComponent('render'));

   if(oxRender = nil) then
      oxRender := oxTRender.Create();
end;

procedure OnDeInit();
begin
   if(oxRender <> nil) and (oxRender.ClassName = 'oxTRender') then
      FreeObject(oxRender);

   oxRender := nil;
end;

VAR
   grRender: oxPGlobalInstance;

function instanceGlobal(): TObject;
begin
   Result := oxTRender.Create();
end;

INITIALIZATION
   oxRenderers.UseRoutines.Add(@onUse);

   grRender := oxGlobalInstances.Add(oxTRender, @oxRender, @instanceGlobal);
   grRender^.Allocate := false;
   grRender^.CopyOverReference := true;

   {$IFNDEF OX_LIBRARY}
   oxRenderers.init.dAdd('oxRender', @OnDeInit);
   {$ENDIF}

END.
